#!/bin/bash

set -eaun
exec > >(tee -i /var/log/arch_install.log) 2>&1

trap 'echo "An error occurred. Cleaning up..."; umount -R /mnt || true; swapoff ${disk}${disk_prefix}3 || true; exit 1' ERR

# Function to prompt for user input with a default value
prompt() {
    local prompt_text="$1"
    local default_value="$2"
    read -p "$prompt_text [$default_value]: " input
    echo "${input:-$default_value}"
}

# Ask for user input
disk=$(prompt "Enter the disk to install Arch Linux (e.g., /dev/sda)" "/dev/sda")

# Validate disk input
if [[ ! -b "$disk" ]]; then
    echo "Error: $disk is not a valid block device."
    exit 1
fi 

hostname=$(prompt "Enter the hostname (default: archlinux)" "archlinux")
user=$(prompt "Enter the username (default: user)" "user")
password=$(prompt "Enter the password (default: password124)" "password124")
keyboard=$(prompt "Enter key map for keyboard (default: UK)" "uk")
locale=$(prompt "Enter the locale (default: en_GB.UTF-8)" "en_GB.UTF-8")
timezone=$(prompt "Enter the timezone (default: Europe/London)" "Europe/London")

echo "Initializing pacman keyring..."
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --refresh-keys

# Partitioning
echo "Launching cfdisk for manual partitioning..."
cfdisk "$disk"

# Determine disk prefix for NVMe or standard drives
if [[ "$disk" == /dev/nvme* ]]; then
    disk_prefix="p"
else
    disk_prefix=""
fi

# Validate partition existence
if [[ ! -e "${disk}${disk_prefix}1" || ! -e "${disk}${disk_prefix}2" || ! -e "${disk}${disk_prefix}3" ]]; then
    echo "Error: Partitions not found. Please partition the disk properly and try again."
    exit 1
fi

# Format the partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${disk}${disk_prefix}1" || { echo "Failed to format boot partition"; exit 1; }
mkfs.ext4 "${disk}${disk_prefix}2" || { echo "Failed to format root partition"; exit 1; }
mkswap "${disk}${disk_prefix}3" || { echo "Failed to format swap partition"; exit 1; }

# Mount the filesystems
mount "${disk}${disk_prefix}2" /mnt
mkdir -p /mnt/boot
mount "${disk}${disk_prefix}1" /mnt/boot
swapon "${disk}${disk_prefix}3" || { echo "Failed to enable swap partition"; exit 1; }

# Install the base system
echo "Installing base system..."
pacstrap -K /mnt base linux linux-firmware grub efibootmgr systemd vim || { echo "Failed to install base system"; exit 1; }

# Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt /bin/bash <<EOF
set -e

# Set timezone
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

# Localization
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

# Configure pacman
sed -i '/Color/s/^#//g' /etc/pacman.conf
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sed -i '/#\[multilib\]/s/^#//' /etc/pacman.conf
sed -i '/#Include = \/etc\/pacman\.d\/mirrorlist/s/^#//' /etc/pacman.conf

# Install additional packages
pacman -Syu --noconfirm pavucontrol kitty gcc pulseaudio-bluetooth bluez bluez-utils networkmanager network-manager-applet
pacman -S --noconfirm xorg-server xorg-init i3 grub "$cpu_ucode"-ucode

# Configure GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable NetworkManager
systemctl enable bluetooth.service
EOF

# Unmount the partitions
echo "Unmounting partitions..."
umount -R /mnt || { echo "Failed to unmount partitions"; exit 1; }

# Confirm reboot
read -p "Installation complete. Reboot now? (y/n): " confirm
if [[ "$confirm" == "y" ]]; then
    echo "Rebooting..."
    reboot
else
    echo "Reboot skipped. Exiting."
fi
