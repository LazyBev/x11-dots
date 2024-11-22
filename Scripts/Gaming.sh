#!/bin/bash

set -e

yay -S steam wine flatpak winetricks

read -p "Do you want to install roblox? [y/N]: " choice
case $choice in
    y | Y)
        flatpak install --user https://sober.vinegarhq.org/sober.flatpakref
        ;;
    *)
        echo "Roblox installation skipped."
        ;;
esac

echo "alias roblox='flatpak run org.vinegarhq.Sober'" >> ~/.bashrc

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
