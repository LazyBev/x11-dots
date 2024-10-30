#!/bin/bash

set -eau

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Variables
user=$(whoami)

# Update pacman.conf
{
    sed -i '/Color/s/^#//g' /etc/pacman.conf
    sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
    sed -i '/#\[multilib\]/s/^#//' /etc/pacman.conf
    sed -i '/#Include = \/etc\/pacman\.d\/mirrorlist/s/^#//' /etc/pacman.conf
} || { echo "Failed to update pacman.conf"; exit 1; }

# Install yay
if [[ ! -d yay-bin ]]; then
    git clone https://aur.archlinux.org/yay-bin.git
    sudo chown "$user:$user" -R yay-bin && cd yay-bin
    makepkg -si
    cd ..
else
    echo "yay-bin already exists. Skipping installation."
fi

# Install packages
packages=(firefox arch-install-scripts flatpak nvidia-dkms nvidia-utils nmap wireshark-qt amd-ucode neovim vim john hydra aircrack-ng sqlmap hashcat nikto openbsd-netcat metasploit amd_ucode kitty systemd base xdg-desktop-portal xdg-desktop-portal-gtk base-devel efibootmgr sof-firmware mesa lib32-mesa vulkan-mesa-layers lib32-vulkan-mesa-layers systemd linux linux-headers linux-firmware networkmanager network-manager-applet wireless_tools neofetch gvfs pavucontrol polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts adobe-source-han-sans-kr-fonts adobe-source-han-serif-kr-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts nano rofi curl make cmake meson obsidian man-db xdotool thunar nitrogen flameshot zip unzip mpv btop emacs noto-fonts picom pulseaudio wireplumber dunst xarchiver eza thunar-archive-plugin)
yay -Syu "${packages[@]}"

# Backup configurations
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
echo "---- Making backup at $backup_dir -----"
mkdir -p "$backup_dir"
sudo cp -rpf "$HOME/.config" "$backup_dir"
echo "----- Backup made at $backup_dir ------"

# Copy configurations
for config in .emacs.d dunst fcitx5 fish i3 nvim rofi omf; do
    sudo cp -rpf "$HOME/dotfiles/$config" "$HOME/.config/" || echo "Failed to copy $config"
done

for fonts in fonts/MartianMono fonts/SF-Mono-Powerline fonts/fontconfig; do
    sudo cp -rpf "$HOME/dotfiles/$fonts" "$HOME/.local/share/fonts/" || echo "Failed to copy $fonts"
done

mkdir -p "$HOME/.config/neofetch/" && sudo cp --parents -rpf "$HOME/dotfiles/neofetch/bk" "$HOME/.config/neofetch/"
mkdir -p "$HOME/Pictures/" && sudo cp -rpf "$HOME/dotfiles/Pictures/bgpic.jpg" "$HOME/Pictures/"
mkdir -p "$HOME/Videos/"

# Install Doom Emacs
if [[ ! -d ~/.config/emacs ]]; then
    git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
    ~/.config/emacs/bin/doom install
else
    echo "Doom Emacs is already installed."
fi

# Install Starship
curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init bash)"' >> ~/.bashrc
chsh -s /bin/bash

reboot
