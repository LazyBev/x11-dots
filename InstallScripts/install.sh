#!/bin/bash

sudo pacman -Syu 
sudo mkdir Pictures 
sudo mkdir Videos 
sudo setxkbmap -layout gb 
sudo git clone https://aur.archlinux.org/paru.git 
cd ~/paru 
sudo makepkg -si 
cd ~ 
paru -S man i3 mercury-browser-bin picom zip unzip neofetch fcitx5-im lolcat polkit gvfs alsa-utils pipewire pipewire-pulse pavucontrol dunst xarchiver thunar thunar-archive-plugin lxappearance eza rofi fish bottom neovim nitrogen alacritty 
cd ~/.config 
sudo rm -rf i3 
sudo rm -rf mozc
sudo rm -rf fish 
sudo rm -rf nvim 
sudo rm -rf fcitx
sudo rm -rf fcitx5
sudo rm -rf /etc/pacman.conf 
sudo rm -rf /etc/xdg/picom.conf 
sudo rm -rf omf 
sudo rm -rf nitrogen
sudo ln -s ~/dotfiles/nitrogen
sudo ln -s ~/dotfiles/fcitx5
sudo ln -s ~/dotfiles/fcitx
sudo ln -s ~/dotfiles/mozc 
sudo ln -s ~/dotfiles/fonts ~/.local/share
sudo ln -s ~/dotfiles/omf  
sudo ln -s ~/dotfiles/fish  
sudo ln -s ~/dotfiles/i3  
sudo ln -s ~/dotfiles/nvim  
sudo ln -s ~/dotfiles/rofi  
sudo ln -s ~/dotfiles/pacman.conf /etc
sudo ln -s ~/dotfiles/picom.conf /etc/xdg  
sudo chsh $USER -s /bin/fish  
gitdot 
cd ~
clear  
read -p "Press enter in order for changes to take place..."  
sudo reboot
