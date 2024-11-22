#!/bin/bash

set -e

sudo pacman -S bluez bluez-utils blueman
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
sudo systemctl daemon-reload
echo "alias blueman='blueman-manager'" >> ~/.bashrc
source ~/.bashrc

# Prompt the user to reboot
read -p "Would you like to reboot now? [y/N]: " reboot_choice
case $reboot_choice in
    y | Y)
        run_command reboot
        ;;
    *)
        echo "Reboot skipped. Please reboot manually if necessary."
        ;;
esac
