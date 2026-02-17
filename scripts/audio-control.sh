#!/bin/bash

#pactl list sinks | grep -C5 "Sink #{device}" | grep "Description: " | cut -c 15- desc from device

declare -a SINK_BANWORDS=("Output") #ignore sinks with these words, (used to avoid duplicate sinks)
declare -A SINK_RENAMES=( ["Raptor Lake-P/U/H cAVS Speaker"]="Laptop Speakers" ) #rename the sink (key) to the value
declare -a SOURCE_BANWORDS=("Output" "Monitor" "Speaker") #Same for sources 
declare -A SOURCE_RENAMES=( ["Raptor Lake-P/U/H cAVS Stereo Microphone"]="Laptop Stereo Microphone" ["Raptor Lake-P/U/H cAVS Digital Microphone"]="Laptop Digital Microphone" )

#there is certainly a better way to do this but fuck it
DEFAULT_SINK_NAME=$(pactl get-default-sink)
ACTIVE_SINK=$(echo "$SINKS_RAW_JSON" | jq -r --arg def "$DEFAULT_SINK_NAME" '.[] | select(.name == $def) | .description')
if [[ -n "$ACTIVE_SINK" && "$ACTIVE_SINK" != "null" ]]; then
    if [[ ${SINK_RENAMES["$ACTIVE_SINK"]+isset} ]]; then
        ACTIVE_SINK="${SINK_RENAMES["$ACTIVE_SINK"]}"
    fi
fi
ACTIVE_SINK="${ACTIVE_SINK//\"/}"

DEFAULT_SOURCE_NAME=$(pactl get-default-source)
ACTIVE_SOURCE=$(echo "$SOURCES_RAW_JSON" | jq -r --arg def "$DEFAULT_SOURCE_NAME" '.[] | select(.name == $def) | .description')
if [[ -n "$ACTIVE_SOURCE" && "$ACTIVE_SOURCE" != "null" ]]; then
    if [[ ${SOURCE_RENAMES["$ACTIVE_SOURCE"]+isset} ]]; then
        ACTIVE_SOURCE="${SOURCE_RENAMES["$ACTIVE_SOURCE"]}"
    fi
fi
ACTIVE_SOURCE="${ACTIVE_SOURCE//\"/}"


print_sinks () {
SINKS_RAW_JSON="$(pactl --format="json" list sinks)"
SINKS_RAW_JSON_COUNT="$(echo $SINKS_RAW_JSON | jq -r 'length')"
declare -a SINK_DESCRIPTIONS=()
declare -a SINK_IDS=()

i=0
index=0

while [ $i -lt $SINKS_RAW_JSON_COUNT ]; do 
  DESC=$(echo $SINKS_RAW_JSON | jq -r ".[$i].description")
  ID=$(echo $SINKS_RAW_JSON | jq -r ".[$i].index")

  valid_sink=true
  j=0
  while [ $j -lt ${#SINK_BANWORDS[@]} ]; do
    if [[ "$DESC" == *"${SINK_BANWORDS[$j]}"* ]]; then
      valid_sink=false
    fi
    ((j++))
  done
  if [[ -n "${SINK_RENAMES[$DESC]}" ]]; then
    DESC="${SINK_RENAMES[$DESC]}"
  fi
  
  if $valid_sink; then
    SINK_DESCRIPTIONS[$index]="$DESC"
    SINK_IDS[$index]="$ID"
    ((index++))
  fi
  ((i++))
done

#reorder sinks to have the correct one on top and avoid annoying :onchange calls upon opening window
declare -a SINK_NAMES=("$ACTIVE_SINK")
for item in "${SINK_DESCRIPTIONS[@]}"; do
  if [[ "$ACTIVE_SINK" != "$item" ]]; then
    SINK_NAMES+=("$item")
  fi
done

SINK_NAMES_JSON=$(jq -nc '$ARGS.positional | map(select(. != ""))' --args "${SINK_NAMES[@]}")
}

print_sources () {
SOURCES_RAW_JSON="$(pactl --format="json" list sources)"
SOURCES_RAW_JSON_COUNT="$(echo $SOURCES_RAW_JSON | jq -r 'length')"
declare -a SOURCE_DESCRIPTIONS=()
declare -a SOURCE_IDS=()

i=0
index=0

while [ $i -lt $SOURCES_RAW_JSON_COUNT ]; do 
  DESC=$(echo $SOURCES_RAW_JSON | jq -r ".[$i].description")
  ID=$(echo $SOURCES_RAW_JSON | jq -r ".[$i].index")

  valid_sink=true
  j=0
  while [ $j -lt ${#SOURCE_BANWORDS[@]} ]; do
    if [[ "$DESC" == *"${SOURCE_BANWORDS[$j]}"* ]]; then
      valid_sink=false
    fi
    ((j++))
  done
  if [[ -n "${SOURCE_RENAMES[$DESC]}" ]]; then
    DESC="${SOURCE_RENAMES[$DESC]}"
  fi
  
  if $valid_sink; then
    SOURCE_DESCRIPTIONS[$index]="$DESC"
    SOURCE_IDS[$index]="$ID"
    ((index++))
  fi
  ((i++))
done

#reorder sinks to have the correct one on top and avoid annoying :onchange calls upon opening window
declare -a SOURCE_NAMES=("$ACTIVE_SOURCE")
for item in "${SOURCE_DESCRIPTIONS[@]}"; do
  if [[ "$ACTIVE_SOURCE" != "$item" ]]; then
    SOURCE_NAMES+=("$item")
  fi
done

SOURCE_NAMES_JSON=$(jq -nc '$ARGS.positional | map(select(. != ""))' --args "${SOURCE_NAMES[@]}")
}


# change sink to whatever was chosen in the combo-box-text
change_sink () {

  desc=$2
  if [[ "$ACTIVE_SINK" == "$desc" ]]; then
    exit 0
  fi
  for key in "${!SINK_RENAMES[@]}"; do
    if [[ "${SINK_RENAMES[$key]}" == *"$desc"* ]]; then
        desc="$key"
        break
    fi
  done
  SINK_ID=$(pactl list sinks| grep -B3 "Description: $desc"|grep Sink|cut -c 7-)
  pactl set-default-sink $SINK_ID
}


loop=true
if [[ "$1" == "sink_to" ]]; then
  change_sink $1 $2
  loop=false
fi

while [ $loop == true ]; do
  print_sinks
  print_sources
  AUDIO_INFO=$(jq -n --argjson a "$SINK_NAMES_JSON" --argjson b "$SOURCE_NAMES_JSON" '{sinks: $a, sources: $b}')
  echo $AUDIO_INFO
  sleep 2
done


