 ewwbar is my (somewhat shoddy) custom bar, built with eww and bash I use on nixOS/archlinux and hyprland.
This was built primarily for my thinkpad, but should mostly work (with some errors and bugs) on all laptops. Investigating `eww logs` will pinpoint the exact error when opening a widget or selecting a button, and opening issues on here is welcome.
## Installation
To install you will need to clone this repo to your ~/.config/ directory and rename the ewwbar directory to eww. This project has a few required dependencies, most should be available in the nix store and the aur
- eww (obviously)
- sensors (sometimes called lmsensors)
- powerprofilesctl (if your running on a laptop)
- playerctl (for the media player)
- bluetoothctl
- nmcli
- jq (for json parsing)
- pactl
- A nerd font of your liking (I recommend jetbrains mono Nerd font available everywhere)
	
Thus, on arch `yay -S eww ` and `pacman -S lm_sensors powerprofilesctl playerctl bluez-utils networkmanager jq libpulse ttf-jetbrains-mono` on arch should net you all the required dependencies.
The bar is started with `eww open bar_Window`, i would recommend adding  this to your startup commands in `hyprland.lua`. 
## Features 
This bar features custom icons for your workspaces, which adjust depending on the open application on that workspace. You can adjust the icons and corresponding applications by changing the dictionary at the start of `scripts/workspaces-fetcher.sh`. The bar has a bluetooth and wifi manager utility as well as a media player and audio controls. The audio controls allows for changing the default audio output, the name of the default speakers is usually quite ugly, one can change the formatting in the audio manager by changing the `SINK_RENAMES` in `scripts/audio-control.sh`. The icons for different applications can be changed there too. The checkbox on the system control center can be used to block sleep, it should now work across all systems, but requires `systemd-inhibit`. For a rounded look, remove the `border-radius: 0px;` line in `eww.scss`.
## Known issues
1. The audio sink selector always defaults back to `Laptop Speakers`, changing it works but it does not show the right output.
2. The bluetooth scripts returns inconsequential errors in `eww logs`.
3. Fan speed will not work on all devices, and can be disabled by commenting out the relevant sections in `modules/system-control.yuck`.
4. Adding new wifi connections will not work for all security systems, use nmtui/nmcli to create the connection and it should then be accessible in the network widget.
