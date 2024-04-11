#!/bin/bash 
cd ..
sudo git clone https://aur.archlinux.org/yay-bin.git 
cd yay-bin
makepkg -sci
cd ../dotfiles
# yay -S man vesktop-bin curl wget vim neovim nitrogen flameshot zip unzip mpv cmake alacritty picom wireplumber lolcat gvfs dunst xarchiver thunar thunar-archive-plugin lxappearance eza fish bottom wine-staging fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts fcitx5-im 
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
sudo cp -rp fcitx5 ../.config
sudo cp -rp mozc ../.config
sudo cp -rp fonts ~/.local/share
sudo cp -rp fish ../.config
sudo cp -rp i3 ../.config
sudo cp -rp nvim ../.config
sudo cp -rp rofi ../.config
sudo cp -rp picom.conf ../.config
sudo cp -rp pacman.conf /etc
# Custom command i added to fish config
tofish
links https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.29/bedrock-linux-0.7.29-x86_64.sh
