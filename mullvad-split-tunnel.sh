#!/usr/bin/env bash

#reset log
: > ./out.log

#load excluded apps from config
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mullvad-split-tunnel"
EXCLUDED_APPS_FILE="$CONFIG_DIR/excluded-apps"
if [ ! -f "$EXCLUDED_APPS_FILE" ]; then
  echo "Missing excluded apps file: $EXCLUDED_APPS_FILE" >&2
  exit 1
fi
echo "Using excluded apps list from: $EXCLUDED_APPS_FILE"

#read excluded apps into array
mapfile -t EXCLUDED_APPS < "$EXCLUDED_APPS_FILE"

#check if any excluded apps were found, else open config for editing
if [ ${#EXCLUDED_APPS[@]} -eq 0 ]; then
  echo "No excluded apps found in $EXCLUDED_APPS_FILE" >&2
  code "$EXCLUDED_APPS_FILE"
  exit 1
fi

cleanup(){
  echo ""
  echo "Cleaning up split tunnel..."
  mullvad split-tunnel clear >> ./out.log
}
trap cleanup EXIT

STATE_FILE="$HOME/.cache/mullvad-split-pids"

#ensure state file directory exists
mkdir -p "$(dirname "$STATE_FILE")"

#reset state file
: > "$STATE_FILE" # : because > alone can fail if noclobber is set

echo "Cleaning up existing split tunnel pids..."

cleanup

echo "Split tunnel running, ${#EXCLUDED_APPS[*]} apps excluded."

while true; do
  for app in "${EXCLUDED_APPS[@]}"; do
    # echo "Checking for app: $app"

    pgrep -f "$app" | while read -r pid; do
      if ! grep -q "^$pid$" "$STATE_FILE"; then
        echo -e "$app [$pid]"
        if mullvad split-tunnel add "$pid"; then
          echo "$pid" >> "$STATE_FILE"
        else 
          echo "Failed to add $app [$pid] to split tunnel"
        fi
      fi
    done
  done
  
  sleep 5
done

