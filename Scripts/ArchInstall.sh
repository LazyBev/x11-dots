#!/bin/bash

set -eau

# Function to prompt for user input with a default value
prompt() {
    local prompt_text="$1"
    local default_value="$2"
    read -p "$prompt_text [$default_value]: " input
    echo "${input:-$default_value}"
}

# Ask for user input
disk=$(prompt "Enter the disk to install Arch Linux (e.g., /dev/sda)" "/dev/sda")
hostname=$(prompt "Enter the hostname (default: archlinux)" "archlinux")
user=$(prompt "Enter the username (default: user)" "user")
password=$(prompt "Enter the password (default: password124)" "password124")
keyboard=$(prompt "Enter key map for keyboard (default: UK)" "uk")
locale=$(prompt "Enter the locale (default: en_GB.UTF-8)" "en_GB.UTF-8")
timezone=$(prompt "Enter the timezone (default: Europe/London)" "Europe/London")

echo "Initializing pacman keyring..."
sudo pacman-key --init

echo "Populating Arch Linux keyring..."
sudo pacman-key --populate archlinux

echo "Refreshing pacman keys..."
sudo pacman-key --refresh-keys

# Partitioning 
cfdisk $disk

# CPU Microcode selection
cpu_ucode=$(prompt "Enter CPU microcode (options: amd, intel):" "amd")

# Confirm disk operations
read -p "Are you sure you want to proceed with partitioning $disk? (y/n) " confirm
[[ "$confirm" != "y" ]] && exit 1

# Determine disk prefix
if [[ "$disk" == /dev/nvme* ]]; then
    disk_prefix="p"
else
    disk_prefix=""
fi

# Format the partitions
mkfs.fat -F32 "$disk$disk_prefix"1 || { echo "Failed to format boot partition"; exit 1; }
mkfs.ext4 "$disk$disk_prefix"2 || { echo "Failed to format root partition"; exit 1; }
mkswap "$disk$disk_prefix"3 || { echo "Failed to format swap partition"; exit 1; }

# Mount the filesystems
mount "$disk$disk_prefix"2 /mnt
mkdir -p /mnt/boot
mount "$disk$disk_prefix"1 /mnt/boot

# Enable swap
swapon "$disk$disk_prefix"3 || { echo "Failed to enable swap partition"; exit 1; }

# Install the base system
pacstrap -K /mnt base linux linux-firmware grub efibootmgr systemd vim || { echo "Failed to install base system"; exit 1; }

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt <<EOF
# Set timezone
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

# Localization
echo "$locale UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$locale" > /etc/locale.conf

# Hostname
echo "$hostname" > /etc/hostname

# Set root password
echo "root:$password" | chpasswd

# Create a new user
useradd -m -G wheel "$user"
echo "$user:$password" | chpasswd

# Enable sudo for wheel group
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Pacman configuration
sed -i '/Color/s/^#//g' /etc/pacman.conf
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sed -i '/#\[multilib\]/s/^#//' /etc/pacman.conf
sed -i '/#Include = \/etc\/pacman\.d\/mirrorlist/s/^#//' /etc/pacman.conf

# Install necessary packages based on selections
sudo pacman -Syu --noconfirm pavucontrol kitty gcc pulseaudio-bluetooth bluez bluez-utils "$cpu_ucode"-ucode networkmanager network-manager-applet pulseaudio 

# Install graphical
sudo pacman -S --noconfirm intel-media-driver Mesa xf86-video-amdgpu xf86-video-ati xorg-init xorg-server vulkan-intel libva-mesa-driver vulkan-radeon xf86-video-nouveau i3

# GRUB Bootloader installation
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB || { echo "Failed to install GRUB"; exit 1; }
grub-mkconfig -o /boot/grub/grub.cfg || { echo "Failed to generate GRUB configuration"; exit 1; }

# Network Manager setup
systemctl disable dhcpcd
systemctl stop dhcpcd
systemctl enable NetworkManager
systemctl start NetworkManager

# Bluetooth
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
lsusb | grep -i bluetooth
sudo systemctl daemon-reload
sudo systemctl restart pulseaudio

# Pulseaudio
sudo sed -i '/load-module module-suspend-on-idle/s/^/# /' /etc/pulse/default.pa
pulseaudio -k && pulseaudio --start

EOF

# Unmount the partitions
umount -R /mnt || { echo "Failed to unmount partitions"; exit 1; }

echo "Installation complete. Rebooting now."
reboot
