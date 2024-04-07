#!/bin/bash

sudo pacman -Syu 
cd ~
if [ -d ~/Pictures]; then
  echo Pictures dir exists
else
  sudo mkdir Pictures
fi
if [ -d ~/Videos]; then
  echo Videos dir exists
else
  sudo mkdir Videos
fi
sudo setxkbmap -layout gb 
sudo git clone https://aur.archlinux.org/yay-bin.git 
cd ~/yay-bin
makepkg -si 
cd ~ 
yay -S man i3 mpv mercury-browser-bin flameshot picom zip unzip neofetch lolcat polkit gvfs alsa-utils pipewire pipewire-pulse pavucontrol dunst xarchiver thunar thunar-archive-plugin lxappearance eza rofi fish bottom neovim nitrogen alacritty 
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
fish
cd ~/.config 
sudo rm -rf i3 
sudo rm -rf rofi
sudo rm -rf mozc
sudo rm -rf fish 
sudo rm -rf nvim 
sudo rm -rf fcitx
sudo rm -rf fcitx5
sudo rm -rf /etc/pacman.conf 
sudo rm -rf /etc/xdg/picom.conf 
sudo rm -rf ~/.local/share/fonts
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
cd ~
sudo chsh $USER -s /bin/fish  
gitdot
read -p "Rebooting in order for changes to take place..."  
sudo reboot
