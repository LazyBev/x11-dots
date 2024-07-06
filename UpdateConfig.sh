#!/bin/bash

echo "---- Making backup at $HOME/configBackup -----"
sudo cp -rpf $HOME/.config $HOME/configBackup 
echo "----- Backup made at $HOME/configBackup ------"

sudo cp -rpf $HOME/dotfiles/neofetch/bk $HOME/.config/neofetch
sudo cp -rpf $HOME/dotfiles/tmux $HOME/.config
sudo cp -rpf $HOME/dotfiles/dunst $HOME/.config
sudo cp -rpf $HOME/dotfiles/Pictures/bgpic.jpg ../Pictures
sudo cp -rpf $HOME/dotfiles/nitrogen $HOME/.config
sudo cp -rpf $HOME/dotfiles/fcitx5 $HOME/.config
sudo cp -rpf $HOME/dotfiles/ mozc $HOME/.config
sudo cp -rpf $HOME/dotfiles/fonts/fontconfig $HOME/.config
sudo cp -rpf $HOME/dotfiles/fonts/MartianMono $HOME/.local/share/fonts
sudo cp -rpf $HOME/dotfiles/fonts/SF-Mono-Powerline $HOME/.local/share/fonts
sudo cp -rpf $HOME/dotfiles/fish $HOME/.config
sudo cp -rpf $HOME/dotfiles/i3 $HOME/.config
sudo cp -rpf $HOME/dotfiles/nvim $HOME/.config
sudo cp -rpf $HOME/dotfiles/rofi $HOME/.config
sudo cp -rpf $HOME/dotfiles/omf $HOME/.config
sudo cp -rpf $HOME/dotfiles/Misc/picom.conf $HOME/.config
sudo cp -rpf $HOME/dotfiles/Misc/pacman.conf /etc

echo "Press Mod + Shift + c to refresh i3 config"
