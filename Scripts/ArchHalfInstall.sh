#!/bin/bash

set -eao pipefail

cfdisk ${disk}

if ${disk} == "/dev/nvme0n1"; then
    mkfs.ext4 "${disk}p3"
    mkswap "${disk}p2"
    mkfs.fat -F 32 "${disk}p1"

    mount "${disk}p3" /mnt
    mount --mkdir "${disk}p1" /mnt/boot
    swapon "${disk}p2"
else
    mkfs.ext4 "${disk}3"
    mkswap "${disk}2"
    mkfs.fat -F 32 "${disk}1"

    mount "${disk}3" /mnt
    mount --mkdir "${disk}1" /mnt/boot
    swapon "${disk}2"
fi

echo "Installing base system..."
pacstrap -K /mnt base base-devel sudo linux linux-headers linux-firmware grub efibootmgr iwd grep git sed "$cpu"-ucode

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab 

# Chroot into the new system
echo "Chrooting into system..."
arch-chroot /mnt <<EOF
set -euo pipefail

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

timedatectl set-ntp true
loadkeys "$keyboard"

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
#echo 'export LS_COLORS="di=35;1:fi=33:ex=36;1"' >> $HOME/.bashrc
#echo 'export PS1='\[\033[01;34m\][\[\033[01;35m\]\u\[\033[00m\]:\[\033[01;36m\]\h\[\033[00m\] <> \[\033[01;34m\]\w\[\033[01;34m\]] \[\033[01;33m\]'' >> $HOME/.bashrc

# Ls alias
echo 'alias ls="eza -al --color=auto"' >> $HOME/.bashrc

# Dotfiles
cd $HOME
rm -rf dotfiles
git clone https://github.com/LazyBev/dotfiles.git

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

# Creating user
if who | grep -q "^$user\b"; then
    useradd -m -G wheel "$user"
    echo "$user:$password" | chpasswd
    echo "%wheel ALL=(ALL) ALL" | tee -a /etc/sudoers > /dev/null
    usermod -aG audio,video,lp,input "$user"
    echo "User $user created and configured."
fi
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

set +a

# Unmount the partitions
echo "Unmounting partitions..."
umount -R /mnt

reboot
