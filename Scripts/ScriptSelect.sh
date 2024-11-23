#!/bin/bash

set -e

echo -e "Choose a script to run."
echo -e "1) Install My Config"
echo -e "2) Update Installed Config"
echo -e "3) Nvidia GPU Script"
echo -e "4) Gaming Script"
echo -e "5) Bluetooth Script"
echo -e "6) All"
read -p ": " scr

for FILE in Config.sh UpdateConfig.sh Nvidia.sh Gaming.sh Bluetooth.sh All.sh; do
    # Check if the file is executable
    if [[ -x "$FILE" ]]; then
        echo "The file '$FILE' is executable."
    else
        echo "Making '$FILE' executable."
        sudo chmod +x "$FILE"
    fi
done

case "$scr" in
  1)
    ./Config.sh
    ;;
  
  2)
    ./UpdateConfig.sh
    ;;
  
  3)
    ./Nvidia.sh -r
    ;;

  4)
    ./Gaming.sh -r
    ;;
  
  5)
    ./Bluetooth.sh -r
    ;;
    
  6)
    ./All.sh
    ;;
    
  *)
    echo "Invalid option."
    ;;
esac
