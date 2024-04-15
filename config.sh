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

paru -S man xdotool vesktop-bin curl rofi mercury-browser-bin wget vim neovim neofetch nitrogen flameshot zip unzip mpv cmake alacritty picom wireplumber gvfs dunst xarchiver thunar thunar-archive-plugin lxappearance eza fish bottom wine-staging fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-jp-fonts fish

echo "---- Making backup at ~/configBackup -----"
cp -rpf ../.config ../configBackup 
echo "----- Backup made at ~/configBackup ------"

sudo cp -rpf tmux ../.config
sudo cp -rpf dunst ../.config
sudo cp -rpf alacritty ../.config
sudo cp -rpf nitrogen ../.config
sudo cp -rpf fcitx5 ../.config
sudo cp -rpf mozc ../.config
sudo cp -rpf fonts/SF-Mono-Powerline ~/.local/share
sudo cp -rpf fonts/MartianMono ~/.local/share
sudo cp -rpf fonts/fontconfig ../.config
sudo cp -rpf fish ../.config
sudo cp -rpf i3 ../.config
sudo cp -rpf nvim ../.config
sudo cp -rpf rofi ../.config
sudo cp -rpf picom.conf ../.config
sudo cp -rpf pacman.conf /etc

if [[ -d ~/Pictures ]]; then
    sudo cp -f Pictures/bgpic.jpg ~/Pictures
else
    sudo cp -rpf Pictures ~
fi

if [[ -d ~/Videos ]]; then
    echo "Videos dir exists" 
else
    sudo cp -rpf Videos ~
    sudo rm -rf ~/Videos/
fi

echo "Press Mod + Shift + c to refresh i3 config"
