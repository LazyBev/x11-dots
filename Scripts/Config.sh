#!/bin/bash

set -eau

user=$(whoami)

# Pacman.conf
sed -i '/Color/s/^#//g' /etc/pacman.conf
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sed -i '/#\[multilib\]/s/^#//' /etc/pacman.conf
sed -i '/#Include = \/etc\/pacman\.d\/mirrorlist/s/^#//' /etc/pacman.conf

# Packages
git clone https://aur.archlinux.org/yay-bin.git
sudo chown "$user:$user" -R yay-bin && cd yay-bin 
makepkg -si && cd ..

yay -Syu firefox arch-install-scripts flatpak nvidia-dkms nvidia-utils nmap wireshark-qt amd-ucode neovim vim john hydra aircrack-ng sqlmap hashcat nikto openbsd-netcat metasploit amd_ucode kitty systemd base xdg-desktop-portal xdg-desktop-portal-gtk base-devel efibootmgr sof-firmware mesa lib32-mesa vulkan-mesa-layers lib32-vulkan-mesa-layers systemd linux linux-headers linux-firmware networkmanager network-manager-applet wireless_tools neofetch gvfs pavucontrol polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts adobe-source-han-sans-kr-fonts adobe-source-han-serif-kr-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts nano rofi curl make cmake meson obsidian man-db xdotool thunar nitrogen flameshot zip unzip mpv btop emacs noto-fonts picom pulseaudio wireplumber dunst xarchiver eza thunar-archive-plugin

# My config
echo "---- Making backup at $HOME/configBackup -----"
sudo cp -rpf "$HOME/.config" "$HOME/configBackup"
echo "----- Backup made at $HOME/configBackup ------"

# Copy configurations
for config in dunst fcitx5 fish i3 nvim rofi omf; do
    sudo cp -rpf "$HOME/dotfiles/$config" "$HOME/.config/";
done

for fonts in fonts/MartianMono fonts/SF-Mono-Powerline fonts/fontconfig; do
    sudo cp -rpf "$HOME/dotfiles/$fonts" "$HOME/.local/share/fonts/";
done

mkdir -p "$HOME/.config/neofetch/" && sudo cp --parents -rpf "$HOME/dotfiles/neofetch/bk" "$HOME/.config/neofetch/"
mkdir -p "$HOME/Pictures/" && sudo cp -rpf "$HOME/dotfiles/Pictures/bgpic.jpg" "$HOME/Pictures/"
mkdir -p "$HOME/Videos/"

~/.config/emacs/bin/doom install
~/.config/emacs/bin/doom sync
    
yay -S fish

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
chsh -s /usr/bin/fish

reboot
