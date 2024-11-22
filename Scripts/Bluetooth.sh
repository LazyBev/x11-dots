#!/bin/bash

set -e

sudo pacman -S bluez bluez-utils blueman
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
sudo systemctl daemon-reload
echo "alias blueman='blueman-manager'" >> ~/.bashrc
source ~/.bashrc
echo -e "Make sure to reboot..."
