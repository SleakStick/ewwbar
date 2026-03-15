#! /bin/bash

if [[ "$1" == "sysinfo" ]]; then
  MEMUSED=$(free -m -h | awk '/^Mem:/ {print $3}')
  MEMTOT=$(free -m -h | awk '/^Mem:/ {print $2}')
  SENSORINFO=$(sensors -j 2>/dev/null)
  CPUTEMP=$(echo $SENSORINFO | jq '."thinkpad-isa-0000".CPU.temp1_input | floor')
  FAN1RPM=$(echo $SENSORINFO | jq '."thinkpad-isa-0000".fan1.fan1_input | floor')
  FAN2RPM=$(echo $SENSORINFO | jq '."thinkpad-isa-0000".fan2.fan2_input | floor')
  BATCHRG=$(echo $SENSORINFO | jq '."BAT0-acpi-0".power1.power1_input | floor')
  NVMETEMP=$(echo $SENSORINFO | jq '."nvme-pci-0400".Composite.temp1_input | floor')


  SYSINFO=$(jq -n --arg a "$MEMUSED" --arg b "$CPUTEMP" --arg c "$FAN1RPM" --arg d "$FAN2RPM" --arg e "$BATCHRG" --arg f "$NVMETEMP" --arg g "$MEMTOT" '{memory: $a, memtot: $g, cputemp: $b, fan1: $c, fan2: $d, batchrg: $e, nvmetemp: $f}')
  echo $SYSINFO
  exit
fi
CONTENTS=$(<~/.config/eww/resources/debounce)

if [[ "$CONTENTS" == "$1" ]]; then
  if [[ "$1" == "shutdown" ]]; then
    poweroff
  elif [[ "$1" == "restart" ]]; then
    restart
  elif [[ "$1" == "logout" ]]; then
    hyprctl dispatch exit
  fi
  echo "false" > ~/.config/eww/resources/debounce
  exit
else 
  echo $1 > ~/.config/eww/resources/debounce
  sleep 0.4
  echo "false" > ~/.config/eww/resources/debounce
fi
