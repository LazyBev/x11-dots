#!/bin/bash

echo "---- Making backup at ~/configBackup -----"
sudo cp -rpf ../.config ../configBackup 
echo "----- Backup made at ~/configBackup ------"

sudo cp -rpf tmux ../.config
sudo cp -rpf dunst ../.config
sudo cp -rpf alacritty ../.config
sudo cp -rpf Pictures/bgpic.jpg ../Pictures
sudo cp -rpf nitrogen ../.config
sudo cp -rpf fcitx5 ../.config
sudo cp -rpf mozc ../.config
sudo cp -rpf fonts/fontconfig ../.config
sudo cp -rpf fonts/MartianMono ~/.local/share/fonts
sudo cp -rpf fonts/SF-Mono-Powerline ~/.local/share/fonts
sudo cp -rpf fish ../.config
sudo cp -rpf i3 ../.config
sudo cp -rpf nvim ../.config
sudo cp -rpf rofi ../.config
sudo cp -rpf omf ../.config
sudo cp -rpf picom.conf ../.config
sudo cp -rpf pacman.conf /etc

echo "Press Mod + Shift + c to refresh i3 config"
