#!/bin/bash

set -e

# Variables
user=$(whoami)
root=false
help=false

# Parse arguments
for arg in "$@"; do
    case $arg in
	-r | --root)
  	    root=true
            ;;
	-h | --help)
            help=true
            ;;
	*)
  	    echo "Invalid argument. Give correct arguments"
            help=true
	    ;;
    esac
done

if ! $help; then

	# Check for root privileges
    if ! $root || [[ $EUID -ne 0 ]]; then
        echo "Please run as root or use the -r option or run this script with sudo"
        exit 1
    fi
    
    # Function to execute commands
    run_command() {
        if $root; then
            sudo "$@"
        else
            "$@"
        fi
    }


    # Check if yay is installed
    if ! command -v yay &> /dev/null; then
        echo "yay is not installed. Please install yay first."
        read -p "Would you like to install yay now? [y/N]: " yay_choice
        case $yay_choice in
            y | Y)
                # Install yay
                git clone https://aur.archlinux.org/yay-bin.git
                run_command chown "$user:$user" -R yay-bin && cd yay-bin
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
    else
        echo "Roblox alias already exists in .bashrc. Skipping addition."
    fi
else
    echo "Options:"
    echo " -r, --root       run script with sudo"
    echo " -h, --help       display this help message"
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
