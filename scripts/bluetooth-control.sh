#!/bin/bash
# This was forked from https://github.com/theUGG0/eww_bluetooth_widget/blob/main/eww.yuck
# Credit to theUGG0 for making a script i can ruin with my lacking skills

poll_controller () {
RAW_DATA=$(bluetoothctl show)

NAME=$(echo "$RAW_DATA" | grep 'Name:' | sed 's/^[[:space:]]*//' | cut -d' ' -f2-)
DISCOVERING=$(echo "$RAW_DATA" | grep -q 'Discovering: yes' && echo true || echo false)
POWERED=$(echo "$RAW_DATA" | grep -q 'Powered: yes' && echo true || echo false)
SCAN_BUTTON="Scan"
POWER_BUTTON="Turn on"
if [[ $POWERED == "true" ]]; then
  POWER_BUTTON="Turn off"
fi
if $DISCOVERING; then
  SCAN_BUTTON="Scanning"
fi

jq -n \
    --arg name "$NAME" \
    --arg discovering "$DISCOVERING" \
    --arg powered "$POWERED" \
    --arg scan_button "$SCAN_BUTTON" \
    --arg power_button "$POWER_BUTTON" \
    '{
        name: $name,
        discovering: $discovering,
        powered: $powered,
        scan_button: $scan_button,
        power_button: $power_button
    }'
}

poll_devices () {
    connected_devices=$(jq -n '[]')
    paired_devices=$(jq -n '[]')
    devices=$(jq -n '[]')

    clean_bt_data=$(echo "devices" | bluetoothctl | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | tr -d '\r')

    while read -r line; do
        [[ "$line" =~ "Device" ]] || continue

        mac=$(echo "$line" | awk '{print $2}')
        
        if [[ -n "$mac" ]]; then
            info=$(echo info "$mac" | bluetoothctl | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | tr -d '\r')
            # Use awk to get everything after the label "name:"
            name=$(echo "$info" | grep 'Name:' | sed 's/.*Name: //')
            paired=$(echo "$info" | grep -q 'Paired: yes' && echo true || echo false)
            connected=$(echo "$info" | grep -q 'Connected: yes' && echo true || echo false)
            if [[ -z "$name" ]]; then
                name=$(echo "$line" | cut -d' ' -f3-)
            fi

            name=$(echo "$name" | tr -dc '[:print:]')
            # Exclude if name is just a MAC address
            if [[ "$name" =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]; then
                continue
            fi
            device_obj=$(jq -n \
              --arg name "$name" \
              --arg mac "$mac" \
              --argjson paired "$paired" \
              --argjson connected "$connected" \
              '{name: $name, mac: $mac, paired: $paired, connected: $connected}')
            
            if [[ $connected == "true" ]]; then
                connected_devices=$(jq --argjson obj "$device_obj" '. + [$obj]' <<< "$connected_devices")
            elif [[ $paired == "true" ]]; then
                paired_devices=$(jq --argjson obj "$device_obj" '. + [$obj]' <<< "$paired_devices")
            else
                devices=$(jq --argjson obj "$device_obj" '. + [$obj]' <<< "$devices")
            fi           
        fi
    done <<< "$clean_bt_data"

    jq -n \
      --argjson devices "$devices" \
      --argjson connected "$connected_devices" \
      --argjson paired "$paired_devices" \
      '{devices: $devices, connected: $connected, paired: $paired}'
}

toggle_power () {
if bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power off
    CONTROLLER_POLL="$(poll_controller)"
    eww update bluetooth-control_controllerPoll="$CONTROLLER_POLL"
else
    bluetoothctl power on
    CONTROLLER_POLL="$(poll_controller)"
    eww update bluetooth-control_controllerPoll="$CONTROLLER_POLL"
fi
}

toggle_scan () {
SCAN_TIMEOUT=10

if bluetoothctl show | grep -q "Discovering: yes"; then
    bluetoothctl scan off 
    CONTROLLER_POLL="$(poll_controller)"
    eww update bluetooth-control_controllerPoll="$CONTROLLER_POLL"
    pkill -f "bluetoothctl.*scan on" 2>/dev/null
else
    bluetoothctl --timeout $SCAN_TIMEOUT scan on &
    CONTROLLER_POLL="$(poll_controller)"
    eww update bluetooth-control_controllerPoll="$CONTROLLER_POLL"
    wait

fi
CONTROLLER_POLL="$(poll_controller)"
eww update bluetooth-control_controllerPoll="$CONTROLLER_POLL"
}


if [[ "$1" == "toggle_power" ]]; then
  toggle_power
  exit
fi
if [[ "$1" == "toggle_scan" ]]; then
  toggle_scan
  exit
fi
if [[ "$1" == "poll_controller" ]]; then
  poll_controller  
  exit
fi
if [[ "$1" == "poll_devices" ]]; then
  poll_devices
  exit
fi

device=""
action=""

while getopts "m:cd" opt; do
    case $opt in
        m) device=$OPTARG ;;
        c) action="connect" ;;
        d) action="disconnect" ;;
        \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
    esac
done

mac=$(echo "$device" | jq -r '.mac')
name=$(echo "$device" | jq -r '.name')

case $action in
    connect)
        bluetoothctl connect "$mac" & eww update bluetooth-control_selectedDevice="$(echo "$device" | jq -c '.connected = true')"
        ;;
    disconnect)
        bluetoothctl disconnect "$mac" & eww update bluetooth-control_selectedDevice ="$(echo $device | jq -c '.connected = false')"
        ;;
esac

