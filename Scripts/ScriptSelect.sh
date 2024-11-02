#!/bin/bash

set -e
set -a
set -u

echo -e "Choose a script to run."
echo -e "1) Install My Config"
echo -e "2) Update Installed Config"
echo -e "3) Nvidia GPU Script"
echo -e "4) Gaming Script"
echo -e "5) Bluetooth Script"
echo -e "6) All"
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
