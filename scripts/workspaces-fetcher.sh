#!/usr/bin/env bash

declare -A SUBSTRING_LIST=(["firefox"]=󰈹 ["YouTube"]="󰗃" ["tmux"]= ["kitty"]="" ["spotify"]= ["Evince"]="" ["sioyek"]="" ["mpv"]="" ["Nautilus"]="󰉋")

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
  if [[ $WORKSPACE_ID -ge 1 ]]; then
  WORKSPACE_WINDOWID=$(echo $HYPR_WORKSPACES_OUTPUT | jq -r ".[$i].lastwindow")
  WORKSPACE_LASTWINDOW=$(hyprctl clients -j | jq --arg a "$WORKSPACE_WINDOWID" '.[] | select(.address == $a) | .class')
  #echo $WORKSPACE_LASTWINDOW
  WORKSPACE_BUTTONS[$i]=" $WORKSPACE_ID"
  for key in "${!SUBSTRING_LIST[@]}"; do
    if [[ "$WORKSPACE_LASTWINDOW" == *"$key"* ]]; then
      WORKSPACE_BUTTONS[$i]="${SUBSTRING_LIST[$key]} $WORKSPACE_ID"
    fi
  done
  if [[ "$WORKSPACE_ID" == "$ACTIVE_WORKSPACE_ID" ]]; then
    WORKSPACE_BUTTONS[$i]=" $WORKSPACE_ID"
  fi
  fi
  ((i++))
done
JSON_WORKSPACE_BUTTONS="$(jq -nc '$ARGS.positional | map(split(" ") | {symb: .[0], id: (.[1]|tonumber)})' --args "${WORKSPACE_BUTTONS[@]}")"
echo ${JSON_WORKSPACE_BUTTONS[@]}
sleep 0.2
done

