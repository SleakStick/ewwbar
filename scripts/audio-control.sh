#!/bin/bash

declare -a SINK_BANWORDS=("Output") #ignore sinks with these words, (used to avoid duplicate sinks)
declare -A SINK_RENAMES=( ["Raptor Lake-P/U/H cAVS Speaker"]="Laptop Speakers" ) #rename the sink (key) to the value

#there is certainly a better way to do this but fuck it
DEFAULT_SINK_NAME=$(pactl get-default-sink)
ACTIVE_SINK=$(echo "$SINKS_RAW_JSON" | jq -r --arg def "$DEFAULT_SINK_NAME" '.[] | select(.name == $def) | .description')
if [[ -n "$ACTIVE_SINK" && "$ACTIVE_SINK" != "null" ]]; then
    if [[ ${SINK_RENAMES["$ACTIVE_SINK"]+isset} ]]; then
        ACTIVE_SINK="${SINK_RENAMES["$ACTIVE_SINK"]}"
    fi
fi
ACTIVE_SINK="${ACTIVE_SINK//\"/}"

print_sinks () {
SINKS_RAW_JSON="$(pactl --format="json" list sinks)"
SINKS_RAW_JSON_COUNT="$(echo $SINKS_RAW_JSON | jq -r 'length')"
declare -a SINK_DESCRIPTIONS=()

i=0
index=0

while [ $i -lt $SINKS_RAW_JSON_COUNT ]; do 
  DESC=$(echo $SINKS_RAW_JSON | jq -r ".[$i].description")

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

print_apps () {
  APPS_RAW_JSON="$(pactl --format=json list sink-inputs )"
  APPS_COUNT=$(echo $APPS_RAW_JSON | jq -r 'length')
 
  i=0
  declare -a APPS_NAMES
  declare -a APPS_VOLUMES
  while [ $i -lt $APPS_COUNT ]; do
    DESC=$(echo $APPS_RAW_JSON | jq ".[$i] | .properties[\"application.name\"]")
    VOLUME=$(echo $APPS_RAW_JSON | jq -r ".[$i].volume.\"front-left\".value_percent" | cut -d '%' -f1)
    APPS_VOLUMES[$i]=$VOLUME
    APPS_NAMES[$i]=$DESC
    ((i++))
  done
  APPS_NAMES_JSON=$(jq -nc '$ARGS.positional | map(select(. != ""))' --args "${APPS_NAMES[@]}")
  APPS_VOLUMES_JSON=$(jq -nc '$ARGS.positional | map(select(. != ""))' --args "${APPS_VOLUMES[@]}")
  APPS_INFO_JSON=$(jq -n --argjson a "$APPS_VOLUMES_JSON" --argjson b "$APPS_NAMES_JSON" 'range(0; $a | length) as $i | { "volume": $a[$i], "name": $b[$i] } | . ' | jq -s '.')
}

# change sink to whatever was chosen in the combo-box-text
change_sink () {
  desc="$2"
  if [[ "$ACTIVE_SINK" == "$desc" ]]; then
    exit 0
  fi
  for key in "${!SINK_RENAMES[@]}"; do
    if [[ "${SINK_RENAMES[$key]}" == *"$desc"* ]]; then
        desc="$key"
        break
    fi
  done
  SINK_ID=$(pactl --format="json" list sinks| jq -r --arg desc "$desc" '.[] | select(.description == $desc) | .index')
  pactl set-default-sink $SINK_ID
}

change_app_audio () {
  app_name="$2"
  volume="$3%"
  app_id=$(pactl --format=json list sink-inputs | jq -r --arg app_name "$app_name" '.[] | select(.properties["application.name"]== $app_name) | .index')
  pactl set-sink-input-volume $app_id $volume
}


loop=true
if [[ "$1" == "sink_to" ]]; then
  change_sink $1 "$2"
  loop=false
fi
if [[ "$1" == "app_audio" ]]; then
  change_app_audio "$1" "$2" $3 
  loop=false
fi
while [ $loop == true ]; do
  print_sinks
  print_apps
  AUDIO_INFO=$(jq -n --argjson a "$SINK_NAMES_JSON" --argjson b "$APPS_INFO_JSON" '{sinks: $a, apps: $b}')
  echo $AUDIO_INFO
  sleep 2
done
