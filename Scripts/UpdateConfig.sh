#!/bin/bash

# Backup configurations
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
echo "---- Making backup at $backup_dir -----"
mkdir -p "$backup_dir"
sudo cp -rpf "$HOME/.config" "$backup_dir"
echo "----- Backup made at $backup_dir ------"

for config in dunst fcitx5 i3 nvim rofi omf; do
    sudo cp -rpf "$HOME/dotfiles/$config" "$HOME/.config/" || echo "Failed to copy $config"
done

for fonts in fonts/MartianMono fonts/SF-Mono-Powerline fonts/fontconfig; do
    sudo cp -rpf "$HOME/dotfiles/$fonts" "$HOME/.local/share/fonts/" || echo "Failed to copy $fonts"
done

echo "Press Mod + Shift + c to refresh i3 config"
