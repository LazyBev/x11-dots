#!/bin/bash
set -eo pipefail

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

yay -Syu iwd zsh tlp stow stremio fastfetch cargo fcitx5-im fcitx5-chinese-addons fcitx5-anthy fcitx5-hangul ttf-dejavu ttf-liberation ttf-joypixels ttf-meslo-nerd noto-fonts adobe-source-han-mono-jp-fonts adobe-source-han-mono-hk-fonts adobe-source-han-mono-kr-fonts adobe-source-han-mono-tw-fonts adobe-source-han-mono-otc-fonts adobe-source-han-mono-cn-fonts tmux blueman bluez bluez-utils steam steam-native-runtime flatpak wine winetricks neovim lua ripgrep vim librewolf-bin pulseaudio wireplumber pulseaudio-alsa alsa-utils pavucontrol ghostty i3 ranger xorg xorg-server xorg-xinit acpi git lazygit github-cli polybar xdg-desktop-portal hwinfo arch-install-scripts wireless_tools fuse2 polkit polkit-gnome rofi curl make cmake meson obsidian man-db man-pages xdotool feh thunar wget qutebrowser flameshot zip unzip mpv btop picom dunst xarchiver eza fzf
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh; sh install.sh; rm -rf install.sh;
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH_CUSTOM/plugins/zsh-autocomplete
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

git clone https://gitlab.torproject.org/tpo/core/arti.git
cd arti && cargo build -p arti --release;
sudo cp target/release/arti /usr/local/bin/
cd .. && rm -rf arti
sudo tee ~/.config/arti/arti-config.toml <<ART
[network]
socks_port = 9050
ART

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

for config in background picom dunst fcitx5 ghostty mov-cli i3 polybar fastfetch nvim rofi tmux; do
    rm -rf $HOME/.config/$config 
done

for config in home background picom dunst fcitx5 ghostty mov-cli i3 polybar fastfetch nvim rofi tmux; do
    stow $config --adopt 
done

source .bashrc
chmod +x $HOME/.config/polybar/launch_polybar.sh
chmod +x $HOME/.config/polybar/polybar-fcitx5-script.sh
