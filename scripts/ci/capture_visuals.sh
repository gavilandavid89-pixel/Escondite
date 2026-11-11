#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
OUTPUT_DIR="${OUTPUT_DIR:-${PROJECT_DIR}/artifacts/visual}"
SCREEN_SIZE="${SCREEN_SIZE:-1440x900}"
GAME_SIZE="${GAME_SIZE:-1280x720}"
CAPTURE_DELAY="${CAPTURE_DELAY:-4}"
WINDOW_WAIT="${WINDOW_WAIT:-20}"

mkdir -p "$OUTPUT_DIR"

capture_one() {
  local name="$1"
  shift
  local output="${OUTPUT_DIR}/${name}.png"
  local log="${OUTPUT_DIR}/${name}.log"

  echo "[VISUAL] Capturing ${name}"
  xvfb-run -a -s "-screen 0 ${SCREEN_SIZE}x24" bash -c '
    set -euo pipefail
    godot_bin="$1"
    project_dir="$2"
    output="$3"
    log="$4"
    delay="$5"
    screen_size="$6"
    game_size="$7"
    window_wait="$8"
    shift 8

    openbox >/dev/null 2>&1 &
    wm_pid=$!
    sleep 1

    "$godot_bin" --audio-driver Dummy --path "$project_dir" --rendering-method gl_compatibility --windowed --resolution "$game_size" -- "$@" >"$log" 2>&1 &
    game_pid=$!

    cleanup() {
      kill -TERM "$game_pid" 2>/dev/null || true
      kill "$wm_pid" 2>/dev/null || true
      wait "$game_pid" 2>/dev/null || true
    }
    trap cleanup EXIT INT TERM

    window_id=""
    for ((i=0; i<window_wait*2; i++)); do
      window_id=$(xdotool search --onlyvisible --pid "$game_pid" 2>/dev/null | head -n 1 || true)
      if [ -n "$window_id" ]; then break; fi
      if ! kill -0 "$game_pid" 2>/dev/null; then
        echo "Godot exited before creating a visible window" >&2
        cat "$log" >&2
        exit 1
      fi
      sleep 0.5
    done
    if [ -z "$window_id" ]; then
      echo "Timed out waiting for the Godot game window" >&2
      cat "$log" >&2
      exit 1
    fi

    xdotool windowmap "$window_id"
    xdotool windowactivate --sync "$window_id" || true
    wmctrl -ir "$window_id" -b remove,hidden,minimized || true
    wmctrl -ir "$window_id" -e "0,80,80,1280,720" || true
    sleep "$delay"

    ffmpeg -y -loglevel error -f x11grab -video_size "$screen_size" -i "$DISPLAY" -frames:v 1 "$output"
    test -s "$output"
    bytes=$(wc -c < "$output")
    if [ "$bytes" -lt 10000 ]; then
      echo "Screenshot is suspiciously small ($bytes bytes): $output" >&2
      exit 1
    fi
    if grep -E "SCRIPT ERROR|Parse Error|Invalid call" "$log"; then
      echo "Godot reported a script/runtime error while capturing $output" >&2
      exit 1
    fi
  ' _ "$GODOT_BIN" "$PROJECT_DIR" "$output" "$log" "$CAPTURE_DELAY" "$SCREEN_SIZE" "$GAME_SIZE" "$WINDOW_WAIT" "$@"
  echo "[VISUAL] Saved ${output}"
}

capture_one menu
capture_one valley --preview
capture_one city --city-preview
capture_one namek --zone-preview=namek

printf 'Captured visual set:\n'
find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.png' -printf '%f %s bytes\n' | sort
