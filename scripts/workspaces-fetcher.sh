#!/bin/bash

declare -A SUBSTRING_LIST=(["Firefox"]=󰈹 ["YouTube"]="󰗃" ["tmux"]= ["~"]="" ["Spotify"]= ["pdf"]="")

declare -a WORKSPACE_BUTTONS

while true; do
HYPR_WORKSPACES_OUTPUT="$(hyprctl -j workspaces | jq 'sort_by(.id)')"
ACTIVE_WORKSPACE_ID=$(hyprctl activeworkspace -j | jq -r '.id')
WORKSPACES_COUNT="$(echo $HYPR_WORKSPACES_OUTPUT | jq -r 'length')"
WORKSPACE_BUTTONS=()

i=0 
while [ $i -lt $WORKSPACES_COUNT ]
do
  WORKSPACE_ID=$(echo $HYPR_WORKSPACES_OUTPUT | jq -r ".[$i].id")
  WORKSPACE_LASTWINDOW=$(echo $HYPR_WORKSPACES_OUTPUT | jq -r ".[$i].lastwindowtitle")
  WORKSPACE_BUTTONS[$i]=" $WORKSPACE_ID"
  for key in "${!SUBSTRING_LIST[@]}"; do
    if [[ "$WORKSPACE_LASTWINDOW" == *"$key"* ]]; then
      WORKSPACE_BUTTONS[$i]="${SUBSTRING_LIST[$key]} $WORKSPACE_ID"
    fi
  done
  if [[ "$WORKSPACE_ID" == "$ACTIVE_WORKSPACE_ID" ]]; then
    WORKSPACE_BUTTONS[$i]=" $WORKSPACE_ID"
  fi
  ((i++))
done
JSON_WORKSPACE_BUTTONS="$(jq -nc '$ARGS.positional | map(split(" ") | {symb: .[0], id: (.[1]|tonumber)})' --args "${WORKSPACE_BUTTONS[@]}")"
echo ${JSON_WORKSPACE_BUTTONS[@]}
sleep 0.2
done
