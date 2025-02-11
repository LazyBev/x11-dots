#!/bin/bash

read -p "Enter the hostname [gentuwu]: " hostname
: ${hostname:=gentuwu}
export $hostname

read -p "Enter the username [user]: " user
: ${user:=user}
export $user

read -sp "Enter the password [1234]: " password
echo ""
: ${password:=1234}
export $password

read -p "Enter key map for keyboard [uk]: " keyboard
: ${keyboard:=uk}
export $keyboard

read -p "Enter the locale [en_GB.UTF-8]: " locale
: ${locale:=en_GB.UTF-8}
export $locale

read -p "Enter the timezone [Europe/London]: " timezone
: ${timezone:=Europe/London}
export $timezone

intel_cpu=$(hwinfo --cpu | head -n6 | grep "Intel")
amd_cpu=$(hwinfo --cpu | head -n6 | grep "AMD")
export cpu=""

if [[ -n "$intel_cpu" ]]; then
    echo "Intel CPU detected."
    cpu="intel"
elif [[ -n "$amd_cpu" ]]; then
    echo "AMD CPU detected."
    cpu="amd"
else
    echo "No Intel or AMD CPU detected, or hwinfo could not detect the CPU."
fi
