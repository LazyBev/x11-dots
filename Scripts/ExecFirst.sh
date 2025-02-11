#!/bin/bash

set -ae

read -p "Enter the hostname [gentuwu]: " hostname
: ${hostname:=gentuwu}

read -p "Enter the username [user]: " user
: ${user:=user}

read -sp "Enter the password [1234]: " password
echo ""
: ${password:=1234}

read -p "Enter key map for keyboard [uk]: " keyboard
: ${keyboard:=uk}

read -p "Enter the locale [en_GB.UTF-8]: " locale
: ${locale:=en_GB.UTF-8}

read -p "Enter the timezone [Europe/London]: " timezone
: ${timezone:=Europe/London}

intel_cpu=$(hwinfo --cpu | head -n6 | grep "Intel")
amd_cpu=$(hwinfo --cpu | head -n6 | grep "AMD")
cpu=""

if [[ -n "$intel_cpu" ]]; then
    echo "Intel CPU detected."
    cpu="intel"
elif [[ -n "$amd_cpu" ]]; then
    echo "AMD CPU detected."
    cpu="amd"
else
    echo "No Intel or AMD CPU detected, or hwinfo could not detect the CPU."
fi

bash -c "
chmod +x ./ArchHalfInstall.sh
./ArchHalfInstall.sh
"
