#!/bin/bash

set -e
set -a
set -u

echo -n "Choose a script to run."
echo -n "1) Install My Config"
echo -n "2) Update Installed Config"
echo -n "3) Nvidia GPU Script"
echo -n "4) Gaming Script"
echo -n "5) Bluetooth Script"
echo -n "6) All"
read -p ": " scr

case "$scr" in
  1)
    sudo chmod +x ./Config.sh
    ./Config.sh
    ;;
  
  2)
    sudo chmod +x ./UpdateConfig.sh
    ./UpdateConfig.sh
    ;;
  
  3)
    sudo chmod +x ./Nvidia.sh
    ./Nvidia.sh
    ;;

  4)
    sudo chmod +x ./Gaming.sh
    ./Gaming.sh
    ;;
  
  5)
    sudo chmod +x ./Bluetooth.sh
    ./Bluetooth.sh
    ;;
    
  6)
    sudo chmod +x ./All.sh
    ./All.sh
    ;;
    
  *)
    echo "Invalid option."
    ;;
esac
