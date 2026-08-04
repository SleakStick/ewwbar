#!/usr/bin/env bash

audio_control () { #󰋋 󰟎      
  declare -a SPEAKER_SYMBOLS=(  )
  declare -a SPEAKER_SYMBOL_VOLUMES=(70 30 1) 
  ICON_AUDIO_CONTROL="󰋋"
  CURRENT_VOLUME=$(pactl --format='json' get-sink-volume @DEFAULT_SINK@ | jq -r '.volume["front-left"].value_percent'| cut -d '%' -f1)
  DEFAULT_SINK=$(pactl get-default-sink)
  
  if [[ $DEFAULT_SINK == *"Speaker"* ]]; then
    ICON_AUDIO_CONTROL=""
    i=0
    for symbol in ${SPEAKER_SYMBOLS[@]}; do
      if [[ $CURRENT_VOLUME -ge ${SPEAKER_SYMBOL_VOLUMES[$i]} ]]; then
        ICON_AUDIO_CONTROL="$symbol"
        break
      fi
      ((i++))
    done
  elif [[ $CURRENT_VOLUME == 0 ]]; then
    ICON_AUDIO_CONTROL="󰟎"
  fi
  echo $ICON_AUDIO_CONTROL
}

bluetooth () { # 󰂱  󰂲
  CONTROLLER_POWER="$(bluetoothctl show | grep PowerState)"
  CONNECTED_DEVICES="$(bluetoothctl devices Connected)"
  ICON_BLUETOOTH="󰂱"
  if [[ $CONNECTED_DEVICES == "" ]]; then
    ICON_BLUETOOTH=""
  fi
  if [[ $CONTROLLER_POWER == "PowerState: off" ]]; then
    ICON_BLUETOOTH="󰂲"
  fi
  echo $ICON_BLUETOOTH
}

if [[ "$1" == "bluetooth" ]]; then
  bluetooth
fi
if [[ "$1" == "audio_control" ]]; then
  audio_control
fi
