#!/bin/bash

echo "---- Making backup at $HOME/configBackup -----"
sudo mv $HOME/.config $HOME/configBackup 
echo "----- Backup made at $HOME/configBackup ------"

sudo mv $HOME/dotfiles/.emacs.d $HOME
sudo mv $HOME/dotfiles/neofetch/bk $HOME/.config/neofetch
sudo mv $HOME/dotfiles/dunst $HOME/.config
sudo mv $HOME/dotfiles/Pictures/bgpic.jpg ../Pictures
sudo mv $HOME/dotfiles/fcitx5 $HOME/.config
sudo mv $HOME/dotfiles/mozc $HOME/.config
sudo mv $HOME/dotfiles/fonts/fontconfig $HOME/.config
sudo mv $HOME/dotfiles/fonts/MartianMono $HOME/.local/share/fonts
sudo mv $HOME/dotfiles/fonts/SF-Mono-Powerline $HOME/.local/share/fonts
sudo mv $HOME/dotfiles/fish $HOME/.config
sudo mv $HOME/dotfiles/i3 $HOME/.config
sudo mv $HOME/dotfiles/nvim $HOME/.config
sudo mv $HOME/dotfiles/rofi $HOME/.config
sudo mv $HOME/dotfiles/omf $HOME/.config
sudo mv $HOME/dotfiles/Misc/picom.conf $HOME/.config
sudo mv $HOME/dotfiles/Misc/pacman.conf /etc

echo "Press Mod + Shift + c to refresh i3 config"
