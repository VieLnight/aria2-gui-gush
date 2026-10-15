#!/usr/bin/env bash
#
# aria2-gui.sh — minimal GUI front-end for aria2c
# Artix Linux (or any Linux with zenity + aria2)
#
# Asks for a URL and a destination folder, then runs aria2c
# tuned for maximum download speed.

set -euo pipefail

# --- Check dependencies -----------------------------------------------------
missing=()
command -v zenity >/dev/null 2>&1 || missing+=("zenity")
command -v aria2c >/dev/null 2>&1 || missing+=("aria2")

if [ ${#missing[@]} -ne 0 ]; then
    echo "Missing dependencies: ${missing[*]}"
    echo "Install them with:  sudo pacman -S ${missing[*]}"
    exit 1
fi

# --- Ask for the URL ---------------------------------------------------------
URL=$(zenity --entry \
    --title="aria2 Downloader" \
    --text="Enter the URL to download:" \
    --width=500)

# User cancelled or left it empty
[ -z "${URL:-}" ] && exit 0

# --- Ask for the destination folder ------------------------------------------
DEST=$(zenity --file-selection \
    --directory \
    --title="Choose download destination" \
    --filename="$HOME/Downloads/")

[ -z "${DEST:-}" ] && exit 0

# --- Run aria2c, tuned for max speed -----------------------------------------
# -x16          up to 16 connections per server
# -s16          split file into 16 pieces
# -j5           up to 5 parallel downloads (relevant for torrents/metalinks)
# -k1M          min split size 1MiB (lets it actually use 16 connections)
# --max-connection-per-server=16  (belt & braces, same as -x)
# --file-allocation=none          skips slow preallocation, speeds up start
# --continue=true                 resume if the file partially exists
# --console-log-level=notice      keep terminal output readable
#
# Run in a terminal so the user can see progress/speed live.

CMD="aria2c \
  --dir=\"$DEST\" \
  --max-connection-per-server=16 \
  --split=16 \
  --min-split-size=1M \
  --max-concurrent-downloads=5 \
  --file-allocation=none \
  --continue=true \
  --console-log-level=notice \
  \"$URL\""

# Try to launch in a terminal so progress is visible.
if command -v konsole >/dev/null 2>&1; then
    konsole -e bash -c "$CMD; echo; echo 'Download finished. Press Enter to close.'; read"
elif command -v xterm >/dev/null 2>&1; then
    xterm -e bash -c "$CMD; echo; echo 'Download finished. Press Enter to close.'; read"
else
    # No terminal emulator found — run in background and notify via zenity.
    eval "$CMD" && \
        zenity --info --text="Download finished:\n$DEST" || \
        zenity --error --text="Download failed. Check the URL and try again."
fi
