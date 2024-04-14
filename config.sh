#!/bin/bash 
set -e

read -p "Do you have paru installed? " YN
if [ $YN == "no" ]; then
  cd ..
  git clone "https://aur.archlinux.org/paru.git"
  sudo chown $USER:$USER -R ~
  cd paru 
  makepkg -sci
  cd ../dotfiles
fi

paru -S man xdotool vesktop-bin curl rofi mercury-browser-bin wget vim neovim neofetch lolcat nitrogen flameshot zip unzip mpv cmake alacritty picom wireplumber gvfs dunst xarchiver thunar thunar-archive-plugin lxappearance eza fish bottom wine-staging fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-jp-fonts fish

sudo cp -rp nitrogen ../.config
sudo cp -rp fcitx5 ../.config
sudo cp -rp mozc ../.config
sudo cp -rp fonts ~/.local/share
sudo cp -rp fish ../.config
sudo cp -rp i3 ../.config
sudo cp -rp nvim ../.config
sudo cp -rp rofi ../.config
sudo cp -rp picom.conf ../.config
sudo cp -rp pacman.conf /etc

cd ~
if [[ -d ~/Pictures ]]; then
    cp dotfiles/Pictures/bgpic.jpg
else
    cp -r Pictures 
fi

if [[ -d ~/Videos ]]; then
    echo "Videos dir exists" 
else
    cp -r Videos 
    sudo rm -rf Videos/
fi
