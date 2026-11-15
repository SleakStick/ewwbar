#!/usr/bin/env bash
declare -A POWER_PROFILE_DICT=(["power-saver"]=1 ["balanced"]=2 ["performance"]=3)

poll () {
  echo ${POWER_PROFILE_DICT[$(powerprofilesctl get)]}
}

switch () {
  declare -A INV_POWER_PROFILE_DICT=(["1"]="power-saver" ["2"]="balanced" ["3"]="performance")
  switch_to_ppfil=$1
  powerprofilesctl set ${INV_POWER_PROFILE_DICT[$switch_to_ppfil]}
  echo "Set the power profile to $(powerprofilesctl get)"
  eww update powerprofile=$switch_to_ppfil
  eww update bar_batteryInfo="$(exec ./scripts/battery-info.sh)"
}

if [[ "$1" == "poll" ]]; then
  poll
fi
if [[ "$1" == "switch" ]]; then
  switch $2
fi
