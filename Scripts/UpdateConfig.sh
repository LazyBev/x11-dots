#!/bin/bash

# Backup configurations
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
echo "---- Making backup at $backup_dir -----"
mkdir -p "$backup_dir"
sudo cp -rpf "$HOME/.config" "$backup_dir"
echo "----- Backup made at $backup_dir ------"

# Clearing configs
for config in dunst fcitx5 tmux i3 neofetch nvim rofi ghostty; do
    rm -rf "~/.config/$config"
done

# Copy configurations from dotfiles (example for dunst, rofi, etc.)
for config in dunst fcitx5 tmux i3 neofetch nvim rofi ghostty; do
    if [ -d "$dotfiles_dir/$config" ]; then
        cp -rpf "$dotfiles_dir/$config" "$HOME/.config/"
    else
        echo "No configuration found for $config. Skipping."
    fi
done

# Install fonts
for font in fonts/MartianMono fonts/SF-Mono-Powerline fonts/fontconfig; do
    if [ -d "$dotfiles_dir/$font" ]; then
        cp -rpf "$dotfiles_dir/$font" "$HOME/.local/share/fonts/"
    else
        echo "No font found for $font. Skipping."
    fi
done

echo "Press Mod + Shift + c to refresh i3 config"
