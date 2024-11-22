#!/bin/bash

set -e

sudo pacman -S bluez bluez-utils blueman pulseaudio-bluetooth
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
sudo systemctl daemon-reload

# Check if the alias already exists in .bashrc
if ! grep -q "alias blueman=" ~/.bashrc; then
    echo "Adding Blueman alias to .bashrc..."
    echo "alias blueman='blueman-manager'" >> ~/.bashrc
    source ~/.bashrc
else
    echo "Blueman alias already exists in .bashrc. Skipping addition."
fi

read -p "Would you like to reboot now? [y/N]: " reboot_choice
case $reboot_choice in
    y | Y)
        run_command reboot
        ;;
    *)
        echo "Reboot skipped. Please reboot manually if necessary."
        ;;
esac
