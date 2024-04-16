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

paru -S steam obsidian man xdotool vesktop-bin curl rofi mercury-browser-bin wget vim neovim neofetch nitrogen flameshot zip unzip mpv cmake alacritty picom wireplumber gvfs polkit-gnome dunst xarchiver thunar thunar-archive-plugin lxappearance eza fish bottom wine-staging fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-jp-fonts fish

echo "---- Making backup at ~/configBackup -----"
cp -rpf ~/.config ~/configBackup 
echo "----- Backup made at ~/configBackup ------"

sudo cp -rpf ~/dotfiles/tmux ~/.config
sudo cp -rpf ~/dotfiles/dunst ~/.config
sudo cp -rpf ~/dotfiles/alacritty ~/.config
sudo cp -rpf ~/dotfiles/nitrogen ~/.config
sudo cp -rpf ~/dotfiles/fcitx5 ~/.config
sudo cp -rpf ~/dotfiles/mozc ~/.config
sudo cp -rpf ~/dotfiles/fonts/SF-Mono-Powerline ~/.local/share/fonts
sudo cp -rpf ~/dotfiles/fonts/MartianMono ~/.local/share/fonts
sudo cp -rpf ~/dotfiles/fonts/fontconfig ~/.config
sudo cp -rpf ~/dotfiles/fish ~/.config
sudo cp -rpf ~/dotfiles/omf ~/.config
sudo cp -rpf ~/dotfiles/i3 ~/.config
sudo cp -rpf ~/dotfiles/nvim ~/.config
sudo cp -rpf ~/dotfiles/rofi ~/.config
sudo cp -rpf ~/dotfiles/picom.conf ~/.config
sudo cp -rpf ~/dotfiles/pacman.conf /etc

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

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
alacritty -e fish | tofish

echo "Press Mod + Shift + c to refresh i3 config, also reboot"
