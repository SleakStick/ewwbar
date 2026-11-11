#!/usr/bin/env bash
declare -A NEXT_POWER_PROFILE_DICT=(["power-saver"]="balanced" ["balanced"]="performance" ["performance"]="power-saver")
POWER_PROFILE=$(powerprofilesctl get)
powerprofilesctl set ${NEXT_POWER_PROFILE_DICT[$POWER_PROFILE]}
echo "Set the power profile to $(powerprofilesctl get)"
eww update bar_batteryInfo="$(~/.config/eww/scripts/battery-info.sh)" 
exit
