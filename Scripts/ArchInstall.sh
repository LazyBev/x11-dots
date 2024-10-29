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
user=$(prompt "Enter the user (default: user)" "user")
password=$(prompt "Enter the password (default: password124)" "password124")
locale=$(prompt "Enter the locale (default: en_GB.UTF-8)" "en_GB.UTF-8")
timezone=$(prompt "Enter the timezone (default: Europe/London)" "Europe/London")

# Prompt for partition sizes
boot_size=$(prompt "Enter the size for the boot partition (e.g., 512M)" "512M")
root_size=$(prompt "Enter the size for the root partition (e.g., 20G)" "20G")

# Confirm disk operations
read -p "Are you sure you want to proceed with partitioning $disk? (y/n) " confirm
[[ "$confirm" != "y" ]] && exit 1

# Determine disk prefix
if [[ "$disk" == /dev/nvme* ]]; then
    disk_prefix="p"
else
    disk_prefix=""
fi

# Partition the disk
(
echo o # Create a new empty GPT partition table
echo n # New partition for boot
echo p # Primary
echo 1 # Partition number
echo   # First sector (Accept default: will start at the beginning of the disk)
echo +"$boot_size" # Size of the boot partition
echo n # New partition for root
echo p # Primary
echo 2 # Partition number
echo   # First sector (Accept default)
echo +"$root_size" # Size of the root partition
echo n # New partition for swap or additional partitions if required
echo p # Primary
echo 3 # Partition number
echo   # First sector (Accept default)
echo   # Last sector (Accept default: will use remaining space)
echo w # Write the partition table
) | fdisk "$disk"

# Format the partitions
mkfs.fat -F32 "$disk$disk_prefix"1 || { echo "Failed to format boot partition" && exit 1; }
mkfs.ext4 "$disk$disk_prefix"2 || { echo "Failed to format root partition" && exit 1; }

# Mount the filesystems
mount "$disk$disk_prefix"2 /mnt
mkdir /mnt/boot
mount "$disk$disk_prefix"1 /mnt/boot

# Swap
mkswap "$disk$disk_prefix"3 || { echo "Failed to format swap partition" && exit 1; }
swapon "$disk$disk_prefix"3 || { echo "Failed to enable swap partition" && exit 1; }

# Install the base system
pacstrap /mnt base linux linux-firmware vim

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt /bin/bash <<EOF
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

# Pacman.conf
sed -i '/Color/s/^#//g' /etc/pacman.conf
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sed -i '/#\[multilib\]/s/^#//' /etc/pacman.conf
sed -i '/#Include = \/etc\/pacman\.d\/mirrorlist/s/^#//' /etc/pacman.conf

# Install necessary packages
pacman -Syu --noconfirm grub efibootmgr systemd i3 gcc amd-ucode networkmanager network-manager-applet nvidia nvidia-dkms nvidia-utils
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Network Manager
sudo systemctl disable dhcpcd
sudo systemctl stop dhcpcd
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

EOF

# Unmount the partitions
umount -R /mnt

reboot
