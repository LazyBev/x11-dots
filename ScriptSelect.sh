#!/bin/bash

echo -n "Choose a script to run."
echo -n "1) Install My Config"
echo -n "2) Update Installed Config"
echo -n "3) Nvidia GPU Script"
echo -n "4) Gaming Script"
echo -n "5) All"
read -p ": " scr

cd Scripts

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
    for script in Config UpdateConfig Nvidia Gaming; do
        sudo chmod +x ./"$script".sh && ./"$script".sh
    done
    ;;
  
  *)
    echo "Invalid option."
    ;;
esac
