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

sudo cp -rp fcitx5 ../.config
sudo cp -rp mozc ../.config
sudo cp -rp fonts ~/.local/share
sudo cp -rp fish ../.config
sudo cp -rp i3 ../.config
sudo cp -rp nvim ../.config
sudo cp -rp rofi ../.config
sudo cp -rp picom.conf ../.config
sudo cp -rp pacman.conf /etc

read -p "Do you want bedrock linux? " YN
if [ $YN == "yes" ]; then
  curl -LO https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.29/bedrock-linux-0.7.29-x86_64.sh
  chmod +x bedrock-linux-0.7.29-x86_64.sh
  ./bedrock-linux-0.7.29-x86_64.sh
fi

read -p "Do you want nix package manager? " YN
if [ $YN == "yes" ]; then
  sh <(curl -L https://nixos.org/nix/install) --daemon
fi

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
