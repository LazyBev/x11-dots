#!/bin/bash
set -eo pipefail

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Variables
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
dotfiles_dir="$HOME/dotfiles"

# Backup configurations 
if [ -d "$HOME/.config" ]; then 
    echo "---- Making backup at $backup_dir -----"
    mkdir -p "$backup_dir"
    sudo cp -rpf "$HOME/.config" "$backup_dir"
    echo "----- Backup made at $backup_dir ------"
fi 

if [ -d "$dotfiles_dir" ]; then
    echo ""
else
    sudo pacman -Sy git && cd ..
    rm -rf dotfiles && cd $HOME
    git clone https://github.com/LazyBev/dotfiles && cd dotfiles/Scripts
fi

cd "$dotfiles_dir"

for config in background picom dunst fcitx5 ghostty mov-cli i3 polybar neofetch nvim rofi tmux; do
    rm -rf $HOME/.config/$config 
done

for config in home background picom dunst fcitx5 ghostty mov-cli i3 polybar neofetch nvim rofi tmux; do
    stow $config --adopt 
done

source .bashrc
chmod +x $HOME/.config/polybar/launch_polybar.sh
chmod +x $HOME/.config/polybar/polybar-fcitx5-script.sh
mkdir -p $HOME/Videos
