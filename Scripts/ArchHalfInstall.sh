#!/bin/bash

set -eao pipefail

trap 'echo "An error occurred. Cleaning up..."; umount -R /mnt || true; swapoff ${disk}${disk_prefix}2 || true; exit 1' ERR
exec > >(tee -i install.log) 2>&1

echo "Installing base system..."
pacstrap -K /mnt base base-devel sudo linux linux-headers linux-firmware grub efibootmgr network-manager "$cpu"-ucode

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab 

# Chroot into the new system
echo "Chrooting into system..."
arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Variables
HOME="/home/$user"
yay_choice=""
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
driver_choice=""
dotfiles_dir="$HOME/dotfiles"

# Install necessary packages (if not installed)
install_packages() {
    local package=$1
    if ! pacman -Qi "$package" &>/dev/null; then
        yay -Sy --noconfirm "$package"
    fi
}

# Refactor pacman.conf update
declare -a pacman_conf=(
    "s/#Color/Color/"
    "s/#ParallelDownloads/ParallelDownloads/"
    "s/#\\[multilib\\]/\\[multilib\\]/"
    "s/#Include = \\/etc\\/pacman\\.d\\/mirrorlist/Include = \\/etc\\/pacman\\.d\\/mirrorlist/"
    "/# Misc options/a ILoveCandy"
)

# Backup the pacman.conf before modifying
echo "Backing up /etc/pacman.conf"
sudo cp /etc/pacman.conf /etc/pacman.conf.bak || { echo "Failed to back up pacman.conf"; exit 1;}

echo "Modifying /etc/pacman.conf"
for change in "${pacman_conf[@]}"; do
    sed -i "$change" /etc/pacman.conf || { echo "Failed to update pacman.conf"; exit 1; }
done

# Custom bash theme
echo "Adding custom bash theme"
if grep -i "LS_COLORS" $HOME/.bashrc; then
    echo
else
    echo 'export LS_COLORS="di=35;1:fi=33:ex=36;1"' >> $HOME/.bashrc
fi

# Adding parse_git_branch function
if ! grep -q "parse_git_branch" $HOME/.bashrc; then
    echo '' >> $HOME/.bashrc
    echo '# Function to parse the current Git branch' >> $HOME/.bashrc
    echo 'parse_git_branch() {' >> $HOME/.bashrc
    echo '    git branch 2>/dev/null | grep -E "^\*" | sed -E "s/^\* (.+)/(\1)/"' >> $HOME/.bashrc
    echo '}' >> $HOME/.bashrc
fi

# PS1
if grep -i "PS1" $HOME/.bashrc; then
    echo    
else
    echo 'export PS1='\[\033[01;34m\][\[\033[01;35m\]\u\[\033[00m\]:\[\033[01;36m\]\h\[\033[00m\] <> \[\033[01;34m\]\w\[\033[01;34m\]] \[\033[01;33m\]$(parse_git_branch)\[\033[00m\]'' >> $HOME/.bashrc
fi

# Ls alias
if grep -i "alias ls" $HOME/.bashrc; then
    echo
else
    echo 'alias ls="eza -al --color=auto"' >> $HOME/.bashrc
fi

# Dotfiles
cd $HOME
git clone https://github.com/LazyBev/dotfiles.git

# Install yay
echo "Installing yay package manager..."
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin && makepkg -si && cd .. && rm -rf yay-bin

# Set timezone
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

# Localization
loadkeys "$keyboard"
echo "$locale UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$locale" > /etc/locale.conf
echo "KEYMAP=$keyboard" > /etc/vconsole.conf

# Hostname
echo "$hostname" > /etc/hostname

# Set root password
echo "root:$password" | chpasswd

# Create a new user
useradd -m -G wheel "$user"
echo "$user:$password" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
usermod -aG audio,video,lp,input "$user"

# Network
echo "Installing network and internet packages..."
install_packages networkmanager network-manager-applet

# Enable Network
echo "Enabling essential services..."
systemctl enable NetworkManager

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

set +a

# Unmount the partitions
echo "Unmounting partitions..."
umount -R /mnt

reboot
