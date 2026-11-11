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
command_file="$OUTPUT_DIR/editor-inspector-command.json"
export DRAGON_EDITOR_COMMAND_FILE="$command_file"

restore_project() {
  cp "$original_project" "$PROJECT_DIR/project.godot"
  rm -f "$command_file"
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
python3 - "$OUTPUT_DIR/project-inspection.json" "$OUTPUT_DIR/scene-node-commands.tsv" <<'PYCOMMANDS'
import json,sys
data=json.load(open(sys.argv[1],encoding="utf-8"))
with open(sys.argv[2],"w",encoding="utf-8") as out:
  for scene in data.get("scenes",[]):
      path=scene.get("path","")
      if not path.endswith(".tscn"): continue
      # Capture the scene root once, then every child node. An empty path is
      # ambiguous in Godot; "." explicitly means the edited scene root.
      out.write(path+"\t.\n")
      for node in scene.get("nodes",[]):
          node_path=node.get("node_path","")
          if node_path == ".": continue
          out.write(path+"\t"+node_path+"\n")
PYCOMMANDS
test -s "$OUTPUT_DIR/scene-node-commands.tsv"
command_total=$(wc -l < "$OUTPUT_DIR/scene-node-commands.tsv")
echo "[EDITOR] Queued $command_total scene/node inspections"

command_index=0
while IFS=$'\t' read -r scene_path node_path; do
  [ -n "$scene_path" ] || continue
  command_index=$((command_index + 1))
  command_id="inspect-$command_index"
  scene_slug=$(printf "%s" "$scene_path" | tr '/.' '__')
  node_slug=$(printf "%s" "${node_path:-root}" | tr '/ ' '__')
  command_tmp="$command_file.tmp"
  python3 - "$command_id" "$scene_path" "$node_path" "$command_tmp" <<'PYWRITE'
import json,sys
json.dump({"id":sys.argv[1],"scene":"res://"+sys.argv[2],"node_path":sys.argv[3]},open(sys.argv[4],"w",encoding="utf-8"))
PYWRITE
  mv "$command_tmp" "$command_file"
  ready=0
  for attempt in $(seq 1 40); do
    if grep -Fq "[DRAGON_INSPECTOR] VERIFIED id=$command_id " "$OUTPUT_DIR/editor.log"; then ready=1; break; fi
    sleep 0.25
    kill -0 "$editor_pid"
  done
  if [ "$ready" -ne 1 ]; then
    echo "[EDITOR] Timed out waiting for $scene_path node=$node_path" >&2
    tail -80 "$OUTPUT_DIR/editor.log" >&2
    exit 1
  fi
  if [ "$node_path" = "." ]; then
    screenshot="$OUTPUT_DIR/scenes/$scene_slug.png"
  else
    screenshot="$OUTPUT_DIR/nodes/$scene_slug--$node_slug.png"
  fi
  mkdir -p "$(dirname "$screenshot")"
  ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$screenshot"
done < "$OUTPUT_DIR/scene-node-commands.tsv"

verified_total=$(grep -c "\[DRAGON_INSPECTOR\] VERIFIED id=inspect-" "$OUTPUT_DIR/editor.log" || true)
[ "$verified_total" -eq "$command_total" ] || { echo "Verified $verified_total of $command_total scene/node inspections" >&2; exit 1; }
scene_capture_total=$(find "$OUTPUT_DIR/scenes" -maxdepth 1 -type f -name "*.png" 2>/dev/null | wc -l)
node_capture_total=$(find "$OUTPUT_DIR/nodes" -type f -name "*.png" 2>/dev/null | wc -l)
[ "$((scene_capture_total + node_capture_total))" -eq "$command_total" ] || { echo "Captured $((scene_capture_total + node_capture_total)) of $command_total requested editor views" >&2; exit 1; }
echo "[EDITOR] Verified $verified_total commands; captured $scene_capture_total scene roots and $node_capture_total nodes"

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
