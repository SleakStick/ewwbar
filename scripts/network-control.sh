#! /bin/bash
CURRENT_NETWORK="$(nmcli -t -f NAME,STATE connection show --active | grep -v '^lo' | grep :activated | cut -d: -f1)"

connect_unknown () {
  INTERFACE="$(nmcli -t -f DEVICE,TYPE device | grep :wifi | cut -d: -f1 | head -n 1)"
  SSID="$1"
  PASSWORD="$2"
  SECURITY="$3"
  nmcli connection add type wifi con-name "$SSID" ifname "$INTERFACE" ssid "$SSID" -- wifi-sec.key-mgmt wpa-psk
  nmcli connection modify $SSID wifi-sec.psk "$PASSWORD"
  nmcli connection up $SSID
}

connect_known () {
  NAME="$1"
  nmcli connection up "$NAME" 
}

select_known_network() {
  FIELD_VISIBLE="$1"
  NETWORK_NAME="$2"
  TOGGLE="true"
  if [[ $FIELD_VISIBLE == "true" ]]; then
    TOGGLE="false" 
  fi
  echo $(eww get network-control_knownControlWidgetReavealer)
  echo $TOGGLE

  COMMAND="connect_known"
  CONNECT_BUTTON="Connect"
  if [[ $CURRENT_NETWORK == $NETWORK_NAME ]]; then
    COMMAND="disconnect"
    CONNECT_BUTTON="Disconnect"
  fi
    CONTROL_WIDGET_INFO=$(jq -n \
    --arg n "$NETWORK_NAME" \
    --arg b "$CONNECT_BUTTON" \
    --arg c "$COMMAND" \
    '{name: $n, buttonlabel: $b, command: $c}')
  eww update network-control_controlWidgetInfo="$CONTROL_WIDGET_INFO"
  eww update network-control_controlWidgetReavealer="true"
  eww update network-control_knownControlWidgetReavealer="true"
  eww update network-control_unknownControlWidgetReavealer="false"

}

select_unknown_network() {
  FIELD_VISIBLE="$1"
  NETWORK_NAME="$2"
  TOGGLE="true"
  if [[ $FIELD_VISIBLE == "true" ]]; then
    TOGGLE="false" 
  fi
  
  NEARBY_NETWORKS="$(eww get network-control_unknownNetworks)"
  NETWORK_INFO=$(echo "$NEARBY_NETWORKS" | jq -r --arg target "$NETWORK_NAME" '.[] | select(.ssid == $target)')
  SECURITY=$(echo "$NETWORK_INFO" | jq -r '.security')
  SIGNAL=$(echo "$NETWORK_INFO" | jq -r '.signal')

  COMMAND="connect_unknown"
  CONNECT_BUTTON="Connect"
  CONTROL_WIDGET_INFO=$(jq -n \
    --arg n "$NETWORK_NAME" \
    --arg b "$CONNECT_BUTTON" \
    --arg c "$COMMAND" \
    --arg d "$SECURITY" \
    --arg e "$SIGNAL" \
    '{name: $n, buttonlabel: $b, command: $c, security: $d, signal: $e}')
  eww update network-control_controlWidgetInfo="$CONTROL_WIDGET_INFO"
  eww update network-control_controlWidgetReavealer="true"
  eww update network-control_unknownControlWidgetReavealer="true"
  eww update network-control_knownControlWidgetReavealer="false"
  #echo $CONTROL_WIDGET_INFO
  #echo $(eww get network-control_controlWidgetInfo)
}

update_vars () {
  KNOWN_NETWORKS=$(nmcli -t -f NAME c show | jq -R -s '
    split("\n") | 
    map(select(length > 0) | 
    split(":") | 
    select(.[0] != "lo") | 
    {ssid: .[0]})')
  eww update network-control_knownNetworks="$KNOWN_NETWORKS"
  CURRENT_NETWORK_JSON=$(nmcli -t -f NAME,DEVICE con show --active | jq -R -s '
    split("\n") | 
    map(select(length > 0) | 
    split(":") | 
    select(.[0] != "") | 
    select(.[1] != "lo") |
    {ssid: .[0], device: .[1]})')
  eww update network-control_currentNetwork="$CURRENT_NETWORK_JSON"
  if [[ "$1" == "rescan" ]]; then
    NEARBY_NETWORKS=$(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | jq -R -s '
      split("\n") | 
      map(select(length > 0) | 
      split(":") | 
      select(.[0] != "") | 
      {ssid: .[0], signal: .[1], security: .[2]})')
    NEARBY_NETWORKS_CLEAN="$(echo "$NEARBY_NETWORKS" | jq 'unique_by(.ssid)')"
    eww update network-control_unknownNetworks="$NEARBY_NETWORKS"
  fi
}

disconnect () {
  NAME="$1"
  nmcli connection down "$NAME"
}

forget_network () {
  NAME="$1"
  nmcli connection delete id $NAME
}


if [[ "$1" == "connect_unknown" ]]; then
  connect_unknown "$2" "$3" "$4" #SSID ,PASSWORD ,SECURITY TYPE
  update_vars
fi
if [[ "$1" == "connect_known" ]]; then
  connect_known "$2"
  update_vars
fi
if [[ "$1" == "disconnect" ]]; then
  disconnect "$2"
  update_vars
fi

if [[ "$1" == "known_networks" ]]; then
  KNOWN_NETWORKS=$(nmcli -t -f NAME c show | jq -R -s '
    split("\n") | 
    map(select(length > 0) | 
    split(":") | 
    select(.[0] != "lo") | 
    {ssid: .[0]})')
  echo $KNOWN_NETWORKS
fi
if [[ "$1" == "unknown_networks" ]]; then
  NEARBY_NETWORKS=$(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | jq -R -s '
    split("\n") | 
    map(select(length > 0) | 
    split(":") | 
    select(.[0] != "") | 
    {ssid: .[0], signal: .[1], security: .[2]})')
  NEARBY_NETWORKS_CLEAN="$(echo "$NEARBY_NETWORKS" | jq 'unique_by(.ssid)')"
  echo $NEARBY_NETWORKS_CLEAN
fi
if [[ "$1" == "current_network" ]]; then
  CURRENT_NETWORK_JSON=$(nmcli -t -f NAME,DEVICE con show --active | jq -R -s '
    split("\n") | 
    map(select(length > 0) | 
    split(":") | 
    select(.[0] != "") | 
    select(.[1] != "lo") |
    {ssid: .[0], device: .[1]})')
  echo $CURRENT_NETWORK_JSON
fi 
if [[ "$1" == "select_known_network" ]]; then
  select_known_network "$2" "$3"
fi
if [[ "$1" == "select_unknown_network" ]]; then
  select_unknown_network "$2" "$3"
fi
if [[ "$1" == "forget_network" ]]; then
  forget_network "$2"
  update_vars
fi
if [[ "$1" == "toggle_scan" ]]; then
  eww update network-control_scanButton="Scanning"
  update_vars "rescan"
  eww update network-control_scanButton="Scan"
fi
if [[ "$1" == "toggle_power" ]]; then
  POWER="$(nmcli networking)"
  if [[ $POWER == "enabled" ]]; then
    eww update network-control_onOffButton="Turn on"
    nmcli networking off
  elif [[ $POWER == "disabled" ]]; then
    eww update network-control_onOffButton="Turn off"
    nmcli networking on
  fi
  update_vars
fi
