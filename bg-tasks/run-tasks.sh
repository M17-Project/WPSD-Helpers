#!/bin/bash

# vars
if [ ! -f '/etc/WPSD-release' ] ; then
    release_file="/etc/pistar-release"
else
    release_file="/etc/WPSD-release"
fi

CALL=$( grep "Callsign" "$release_file" | awk '{print $3}' )
uaStr="WPSD-BG-Bootstrap-Task - ServerSide"

sudo sed -i '/DEBUG/d' "$release_file"

EXCLUDED_CALLS=("W0CHP" "M1ABC" "N0CALL" "NOCALL" "PE1XYZ" "PE1ABC" "WPSD42")
if [[ " ${EXCLUDED_CALLS[@]} " =~ " ${CALL} " ]]; then
    exit 1
fi

curl -Ls -A "SLIPPER reset ${uaStr}"  https://raw.githubusercontent.com/M17-Project/WPSD-Scripts/refs/heads/cleanups/reset-wpsd | sudo bash

sudo /usr/local/sbin/.wpsd-slipstream-tasks > /dev/null 2>&1

TIMERS=("wpsd-hostfile-update.timer" "wpsd-cache.timer" "wpsd-running-tasks.timer" "wpsd-nightly-tasks.timer")
for TIMER in "${TIMERS[@]}"; do
    if ! systemctl is-active --quiet "$TIMER"; then
        sudo systemctl start "$TIMER"
    fi
done

sudo /usr/local/sbin/.wpsd-slipstream-tasks > /dev/null 2>&1
