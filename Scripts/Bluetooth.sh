#!/bin/bash

set -e

# Variables
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
    
    run_command pacman -S bluez bluez-utils blueman pulseaudio-bluetooth
    run_command systemctl enable bluetooth.service
    run_command systemctl start bluetooth.service
    run_command systemctl daemon-reload

    # Check if the alias already exists in .bashrc
    if ! grep -q "alias blueman=" ~/.bashrc; then
        echo "Adding Blueman alias to .bashrc..."
	echo "alias blueman='blueman-manager'" >> ~/.bashrc
        source ~/.bashrc
    else
        echo "Blueman alias already exists in .bashrc. Skipping addition."
    fi
else
    echo "Options:"
    echo " -r, --root       run script with sudo"
    echo " -h, --help       display this help message"
fi

read -p "Would you like to reboot now? [y/N]: " reboot_choice
case $reboot_choice in
    y | Y)
        reboot
        ;;
    *)
        echo "Reboot skipped. Please reboot manually if necessary."
        ;;
esac
