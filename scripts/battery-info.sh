#!/bin/bash

BATTERY_PERCENTAGE="$(cat /sys/class/power_supply/BAT0/capacity)"
declare -A BATTERY_PERCENTAGE_ICON_DICT=(["80"]="" ["60"]="" ["40"]="" ["20"]="" ["0"]="" )
i=80
while [ $i -ge 0 ]; do
  if [ "$BATTERY_PERCENTAGE" -ge "$i" ]; then
    BATTERY_PERCENTAGE_ICON="${BATTERY_PERCENTAGE_ICON_DICT[$i]}"
    break 
  fi
  i=$((i - 20))
done
POWER_PROFILE="$(powerprofilesctl get)"
declare -A NEXT_POWER_PROFILE_DICT=(["power-saver"]="balanced" ["balanced"]="performance" ["performance"]="power-saver")
NEXT_POWER_PROFILE=${NEXT_POWER_PROFILE_DICT[$POWER_PROFILE]}
declare -A POWER_PROFILE_ICON_DICT=(["power-saver"]= ["balanced"]=  ["performance"]=)
POWER_PROFILE_ICON=${POWER_PROFILE_ICON_DICT[$POWER_PROFILE]}
CHARGING="$(cat /sys/class/power_supply/AC/online)"
if [[ $CHARGING == 1 ]]; then
  POWER_PROFILE_ICON=
fi

BATTERY_INFO="$BATTERY_PERCENTAGE $POWER_PROFILE $CHARGING $POWER_PROFILE_ICON $BATTERY_PERCENTAGE_ICON $NEXT_POWER_PROFILE"
jq -nc '$ARGS.positional | map(split(" ") | {percentage: (.[0]|tonumber), power_profile: .[1], charging: .[2], power_profile_icon: .[3], battery_percentage_icon: .[4], next_power_profile: .[5]})' --args "${BATTERY_INFO}"
echo $JSON_BATTERY_INFO
exit
