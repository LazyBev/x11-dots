#!/bin/bash

set -ae

read -p "Enter the disk you want to write on [dev/nvme0n1]" disk
: ${disk:=nvme0n1}

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

read -p "Enter your CPU brand [amd]: " cpu
: ${cpu:=amd}

bash -c "
chmod +x ./ArchHalfInstall.sh
./ArchHalfInstall.sh
"
