#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
OUTPUT_DIR="${OUTPUT_DIR:-${PROJECT_DIR}/artifacts/editor-inspection}"
SCREEN_SIZE="${SCREEN_SIZE:-1920x1080}"
EDITOR_WAIT="${EDITOR_WAIT:-25}"
GAME_WAIT="${GAME_WAIT:-4}"

mkdir -p "$OUTPUT_DIR"
export GODOT_BIN PROJECT_DIR OUTPUT_DIR SCREEN_SIZE EDITOR_WAIT GAME_WAIT

if [ "${1:-}" != "--inside-xvfb" ]; then
  exec xvfb-run -a -s "-screen 0 ${SCREEN_SIZE}x24" bash "$0" --inside-xvfb
fi

x_display="${DISPLAY:-:99}"
export DISPLAY="$x_display"
echo "[EDITOR] Using display $x_display"
openbox >/dev/null 2>&1 &
wm_pid=$!
editor_pid=""
game_pid=""
original_project="$OUTPUT_DIR/project.godot.original"
cp "$PROJECT_DIR/project.godot" "$original_project"
command_dir="$OUTPUT_DIR/editor-commands"
mkdir -p "$command_dir"
export DRAGON_EDITOR_COMMAND_DIR="$command_dir"

restore_project() {
  cp "$original_project" "$PROJECT_DIR/project.godot"
  rm -rf "$command_dir"
}
cleanup() {
  [ -z "$game_pid" ] || kill -TERM "$game_pid" 2>/dev/null || true
  [ -z "$editor_pid" ] || kill -TERM "$editor_pid" 2>/dev/null || true
  kill "$wm_pid" 2>/dev/null || true
  [ -z "$game_pid" ] || wait "$game_pid" 2>/dev/null || true
  [ -z "$editor_pid" ] || wait "$editor_pid" 2>/dev/null || true
  restore_project
}
trap cleanup EXIT INT TERM
sleep 1

# Enable a temporary EditorPlugin bridge only for this CI run.
python3 - "$PROJECT_DIR/project.godot" <<PYENABLE
import re, sys
p=sys.argv[1]
s=open(p,encoding="utf-8").read()
plugin="res://addons/dragon_realm_ci_inspector/plugin.cfg"
m=re.search(r'^enabled=PackedStringArray\(([^)]*)\)',s,re.M)
if not m:
  raise SystemExit("Could not locate [editor_plugins] enabled setting")
items=re.findall(r'"([^"]+)"',m.group(1))
if plugin not in items:
  items.append(plugin)
s=s[:m.start()]+ "enabled=PackedStringArray(" + ", ".join('"'+x+'"' for x in items) + ")" + s[m.end():]
open(p,"w",encoding="utf-8").write(s)
PYENABLE

echo "[EDITOR] Launching Godot editor with inspection bridge"
"$GODOT_BIN" --editor --path "$PROJECT_DIR" >"$OUTPUT_DIR/editor.log" 2>&1 &
editor_pid=$!
sleep "$EDITOR_WAIT"
kill -0 "$editor_pid"
find "$HOME/.config/godot" -maxdepth 1 -type f -name "editor_settings*" -exec cp {} "$OUTPUT_DIR/" \; 2>/dev/null || true
ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-only.png"

env DISPLAY="$x_display" xdotool key --clearmodifiers ctrl+F1
sleep 2
ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-2d-workspace.png"

# Capture the script workspace and both diagnostic docks.
env DISPLAY="$x_display" xdotool key --clearmodifiers ctrl+alt+o
sleep 1
env DISPLAY="$x_display" xdotool type --clearmodifiers --delay 2 "main.gd"
env DISPLAY="$x_display" xdotool key Return
sleep 3
ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-script-main.png"
env DISPLAY="$x_display" xdotool key --clearmodifiers alt+o
sleep 2
ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-output-panel.png"
env DISPLAY="$x_display" xdotool key --clearmodifiers alt+d
sleep 2
ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-debugger-panel.png"

# The plugin opens each scene through EditorInterface and selects every node
# so screenshots show the actual Scene dock and Inspector selection.
python3 - "$OUTPUT_DIR/project-inspection.json" "$OUTPUT_DIR/scene-node-commands.tsv" "$OUTPUT_DIR/scene-node-commands.jsonl" <<'PYCOMMANDS'
import json,sys
data=json.load(open(sys.argv[1],encoding="utf-8"))
with open(sys.argv[2],"w",encoding="utf-8") as tsv, open(sys.argv[3],"w",encoding="utf-8") as commands:
  index=0
  for scene in data.get("scenes",[]):
      path=scene.get("path","")
      if not path.endswith(".tscn"): continue
      nodes=[(".",)] + [(n.get("node_path",""),) for n in scene.get("nodes",[]) if n.get("node_path") not in ("", ".")]
      for (node_path,) in nodes:
          index += 1
          command={"id":f"inspect-{index}","scene":"res://"+path,"node_path":node_path}
          tsv.write(path+"|"+node_path+"\n")
          commands.write(json.dumps(command,ensure_ascii=False)+"\n")
PYCOMMANDS
test -s "$OUTPUT_DIR/scene-node-commands.jsonl"
command_total=$(wc -l < "$OUTPUT_DIR/scene-node-commands.jsonl")
echo "[EDITOR] Queued $command_total scene/node inspections"

# Each command gets a unique filename. This avoids stale reads when the
# editor polls the queue on virtualized CI filesystems.
command_index=0
while IFS= read -r command_json; do
  [ -n "$command_json" ] || continue
  command_index=$((command_index + 1))
  command_id="inspect-$command_index"
  command_tmp=$(printf "%s/%04d.json.tmp" "$command_dir" "$command_index")
  command_ready=$(printf "%s/%04d.json" "$command_dir" "$command_index")
  printf '%s\n' "$command_json" > "$command_tmp"
  mv "$command_tmp" "$command_ready"
  ready=0
  for attempt in $(seq 1 40); do
    if grep -Fq "[DRAGON_INSPECTOR] VERIFIED id=$command_id " "$OUTPUT_DIR/editor.log"; then ready=1; break; fi
    sleep 0.25
    kill -0 "$editor_pid"
  done
  if [ "$ready" -ne 1 ]; then
    echo "[EDITOR] Timed out waiting for command $command_id (see scene-node-commands.tsv)" >&2
    tail -80 "$OUTPUT_DIR/editor.log" >&2
    exit 1
  fi
  screenshot=$(printf "%s/views/inspect-%04d.png" "$OUTPUT_DIR" "$command_index")
  mkdir -p "$(dirname "$screenshot")"
  ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$screenshot"
done < "$OUTPUT_DIR/scene-node-commands.jsonl"

verified_total=$(grep -c "\[DRAGON_INSPECTOR\] VERIFIED id=inspect-" "$OUTPUT_DIR/editor.log" || true)
[ "$verified_total" -eq "$command_total" ] || { echo "Verified $verified_total of $command_total scene/node inspections" >&2; exit 1; }
view_capture_total=$(find "$OUTPUT_DIR/views" -type f -name "inspect-*.png" 2>/dev/null | wc -l)
[ "$view_capture_total" -eq "$command_total" ] || { echo "Captured $view_capture_total of $command_total requested editor views" >&2; exit 1; }
echo "[EDITOR] Verified $verified_total commands; captured $view_capture_total scene/node views"

# Game preview floating above the editor, then fullscreen.
echo "[EDITOR] Launching windowed game over editor"
"$GODOT_BIN" --audio-driver Dummy --path "$PROJECT_DIR" --rendering-method gl_compatibility --windowed --resolution 1280x720 -- --preview >"$OUTPUT_DIR/game-windowed.log" 2>&1 &
game_pid=$!
sleep "$GAME_WAIT"
kill -0 "$game_pid"
ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/game-windowed-over-editor.png"
kill -TERM "$game_pid" 2>/dev/null || true
wait "$game_pid" 2>/dev/null || true
game_pid=""

echo "[EDITOR] Launching fullscreen game"
"$GODOT_BIN" --audio-driver Dummy --path "$PROJECT_DIR" --rendering-method gl_compatibility --fullscreen -- --preview >"$OUTPUT_DIR/game-fullscreen.log" 2>&1 &
game_pid=$!
sleep "$GAME_WAIT"
kill -0 "$game_pid"
ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/game-fullscreen.png"
kill -TERM "$game_pid" 2>/dev/null || true
wait "$game_pid" 2>/dev/null || true
game_pid=""

sleep 2
ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-clean.png"

for file in "$OUTPUT_DIR"/editor-only.png "$OUTPUT_DIR"/editor-2d-workspace.png "$OUTPUT_DIR"/editor-script-main.png "$OUTPUT_DIR"/editor-output-panel.png "$OUTPUT_DIR"/editor-debugger-panel.png "$OUTPUT_DIR"/game-windowed-over-editor.png "$OUTPUT_DIR"/game-fullscreen.png "$OUTPUT_DIR"/editor-clean.png; do
  test -s "$file"
  bytes=$(wc -c < "$file")
  [ "$bytes" -ge 10000 ] || { echo "Suspicious screenshot: $file ($bytes bytes)" >&2; exit 1; }
done

{
  echo "=== GODOT EDITOR ==="
  cat "$OUTPUT_DIR/editor.log" 2>/dev/null || true
  echo
  echo "=== WINDOWED GAME / DEBUG OUTPUT ==="
  cat "$OUTPUT_DIR/game-windowed.log" 2>/dev/null || true
  echo
  echo "=== FULLSCREEN GAME / DEBUG OUTPUT ==="
  cat "$OUTPUT_DIR/game-fullscreen.log" 2>/dev/null || true
} > "$OUTPUT_DIR/editor-debugger-output.txt"
echo "[EDITOR] Captures and logs saved in $OUTPUT_DIR"
