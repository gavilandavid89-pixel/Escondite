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

xvfb-run -a -s "-screen 0 ${SCREEN_SIZE}x24" bash -euo pipefail -c '
  openbox >/dev/null 2>&1 &
  wm_pid=$!
  editor_pid=""
  game_pid=""
  cleanup() {
    [ -z "$game_pid" ] || kill -TERM "$game_pid" 2>/dev/null || true
    [ -z "$editor_pid" ] || kill -TERM "$editor_pid" 2>/dev/null || true
    kill "$wm_pid" 2>/dev/null || true
    [ -z "$game_pid" ] || wait "$game_pid" 2>/dev/null || true
    [ -z "$editor_pid" ] || wait "$editor_pid" 2>/dev/null || true
  }
  trap cleanup EXIT INT TERM
  sleep 1

  echo "[EDITOR] Launching Godot editor"
  "$GODOT_BIN" --editor --path "$PROJECT_DIR" >"$OUTPUT_DIR/editor.log" 2>&1 &
  editor_pid=$!
  sleep "$EDITOR_WAIT"
  kill -0 "$editor_pid"
  find "$HOME/.config/godot" -maxdepth 1 -type f -name "editor_settings*" -exec cp {} "$OUTPUT_DIR/" \; 2>/dev/null || true
  ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-only.png"

  # 2D workspace and the scene tree/Inspector docks.
  xdotool key --clearmodifiers ctrl+F1
  sleep 2
  ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-2d-workspace.png"

  # Open the main script through Godot's Quick Open Script dialog.
  xdotool key --clearmodifiers ctrl+alt+o
  sleep 1
  xdotool type --clearmodifiers --delay 2 "res://scripts/main.gd"
  xdotool key Return
  sleep 3
  ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-script-main.png"

  # Save visible Output and Debugger panels as separate evidence.
  xdotool key --clearmodifiers alt+o
  sleep 2
  ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-output-panel.png"
  xdotool key --clearmodifiers alt+d
  sleep 2
  ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/editor-debugger-panel.png"

  # Visit every authored scene in the real editor. The complete node hierarchy
  # is also exported as text/JSON so no scene is lost if a dialog search misses.
  mapfile -t scene_paths < <(python3 - "$OUTPUT_DIR/project-inspection.json" <<'PYSCENES'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
for scene in data.get("scenes", []):
    path = scene.get("path", "")
    if path.endswith(".tscn"):
        print(path)
PYSCENES
)
  mkdir -p "$OUTPUT_DIR/scenes"
  for scene_path in "${scene_paths[@]}"; do
    scene_slug=$(printf "%s" "$scene_path" | tr '/.' '__')
    echo "[EDITOR] Opening scene $scene_path"
    xdotool key --clearmodifiers ctrl+shift+o
    sleep 0.6
    xdotool type --clearmodifiers --delay 1 "res://$scene_path"
    xdotool key Return
    sleep 2
    ffmpeg -y -loglevel error -f x11grab -video_size "$SCREEN_SIZE" -i "$DISPLAY" -frames:v 1 "$OUTPUT_DIR/scenes/$scene_slug.png"
  done

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
'
echo "[EDITOR] Captures and logs saved in $OUTPUT_DIR"
