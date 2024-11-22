#!/bin/bash

set -e

user=$(whoami)

# Check if yay is installed
if ! command -v yay &> /dev/null; then
    echo "yay is not installed. Please install yay first."
    read -p "Would you like to install yay now? [y/N]: " yay_choice
    case $yay_choice in
        y | Y)
            # Install yay
            git clone https://aur.archlinux.org/yay-bin.git
            sudo chown "$user:$user" -R yay-bin && cd yay-bin
            makepkg -si && cd .. && rm -rf yay
            ;;
        *)
            echo "Exiting. Please install yay to proceed."
            exit 1
            ;;
    esac
fi

# Install required packages
yay -S steam wine flatpak winetricks

# Prompt the user to install Roblox
read -p "Do you want to install Roblox? [y/N]: " choice
case $choice in
    y | Y)
        flatpak install --user https://sober.vinegarhq.org/sober.flatpakref
        ;;
    *)
        echo "Roblox installation skipped."
        ;;
esac

# Check if the alias already exists in .bashrc
if ! grep -q "alias roblox=" ~/.bashrc; then
    echo "Adding Roblox alias to .bashrc..."
    echo "alias roblox='flatpak run org.vinegarhq.Sober'" >> ~/.bashrc
    source ~/.bashrc
else
    echo "Roblox alias already exists in .bashrc. Skipping addition."
fi

# Prompt the user to reboot
read -p "Would you like to reboot now? [y/N]: " reboot_choice
case $reboot_choice in
    y | Y)
        reboot
        ;;
    *)
        echo "Reboot skipped. Please reboot manually if necessary."
        ;;
esac
