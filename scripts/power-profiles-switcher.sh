#!/bin/bash
declare -A NEXT_POWER_PROFILE_DICT=(["power-saver"]="balanced" ["balanced"]="performance" ["performance"]="power-saver")
echo "declared dict"
POWER_PROFILE=$(sudo -n powerprofilesctl get)
echo $POWER_PROFILE
sudo -n powerprofilesctl set ${NEXT_POWER_PROFILE_DICT[$POWER_PROFILE]}
echo "set the power profile to "
echo $(sudo -n powerprofilesctl get)
eww update bar_batteryInfo="$(/home/ben/.config/eww/scripts/battery-info.sh)"
echo "updated the batteryInfo variable "
exit
