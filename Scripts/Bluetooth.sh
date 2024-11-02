#!/bin/bash

set -e

sudo pacman -S bluez bluez-utils
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
lsusb | grep -i bluetooth
sudo systemctl daemon-reload
