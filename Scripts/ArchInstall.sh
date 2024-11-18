#!/bin/bash

set -eau

trap 'echo "An error occurred. Cleaning up..."; umount -R /mnt || true; swapoff ${disk}${disk_prefix}3 || true; exit 1' ERR

# Function to prompt for user input with a default value
prompt() {
    local prompt_text="$1"
    local default_value="$2"
    read -p "$prompt_text [$default_value]: " input
    echo "${input:-$default_value}"
}

lsblk

# Ask for user input
export disk=$(prompt "Enter the disk to install Arch Linux (e.g., /dev/nvme0n1)" "/dev/nvme0n1")

# Validate disk input
if [[ ! -b "$disk" ]]; then
    echo "Error: $disk is not a valid block device."
    exit 1
fi 

export hostname=$(prompt "Enter the hostname" "gentuwu")
export user=$(prompt "Enter the username" "user")
export password=$(prompt "Enter the password" "password124")
export keyboard=$(prompt "Enter key map for keyboard" "uk")
export locale=$(prompt "Enter the locale" "en_GB.UTF-8")
export timezone=$(prompt "Enter the timezone" "Europe/London")
export cpu=$(prompt "Enter your cpu's manufacturer" "amd") 

# Prompt for desktop environment selection
echo "Select a desktop environment to install:"
echo "1) GNOME"
echo "2) KDE Plasma"
echo "3) XFCE"
echo "4) MATE"
echo "5) i3 with ly (Window Manager)"
export de_choice=$(prompt "Enter your choice (1-5)" "5") 

timedatectl set-ntp true
loadkeys "$keyboard"

# Confirm disk operations
read -p "WARNING: This will erase all data on $disk. Continue? (y/n): " confirm
[[ "$confirm" != "y" ]] && exit 1

lsblk 

export auto=$(prompt "Manual or auto disk partitioning" "auto")

# Wipe the disk and partition
echo "Wiping $disk and creating partitions..."
wipefs -af "$disk"

if [[ $auto="auto" ]]; then
    # Prompt for partition sizes
    read -p "Enter size for /boot partition (e.g., 512M): " boot_size
    read -p "Enter size for swap partition (e.g., 2G): " swap_size
    read -p "Enter size for /root partition (e.g., 25G): " root_size
    echo "The remaining space will be used for /home."

    # Partition the disk
    echo "Creating partitions on $disk..."
    (
    echo g    # Create a new GPT partition table
    echo n    # Add a new partition for /boot
    echo 1    # Partition number
    echo      # Default - start at beginning of disk
    echo +$boot_size # Size of /boot partition
    echo t    # Change partition type
    echo 1    # Set partition type to EFI (or BIOS boot if legacy)
    echo n    # Add a new partition for swap
    echo 2    # Partition number
    echo      # Default - start after /boot
    echo +$swap_size # Size of swap
    echo t    # Change partition type
    echo 2    # Select swap partition
    echo 19   # Set partition type to Linux swap
    echo n    # Add a new partition for /
    echo 3    # Partition number
    echo      # Default - start after swap
    echo +$root_size # Size of / partition
    echo n    # Add a new partition for /home
    echo 4    # Partition number
    echo      # Default - start after /
    echo      # Use the remaining space
    echo w    # Write the partition table and exit
    ) | fdisk "$disk"
else 
    cfdisk "$disk"
fi 

# Determine disk prefix for NVMe or standard drives
if [[ "$disk" == /dev/nvme* ]]; then
    export disk_prefix="p"
else
    export disk_prefix=""
fi

# Validate partition existence
if [[ ! -e "${disk}${disk_prefix}1" || ! -e "${disk}${disk_prefix}2" || ! -e "${disk}${disk_prefix}3" ]]; then
    echo "Error: Partitions not found. Please partition the disk properly and try again."
    exit 1
fi

# Format the partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${disk}${disk_prefix}1"
mkfs.ext4 "${disk}${disk_prefix}2"
mkswap "${disk}${disk_prefix}3"

# Mount the filesystems
mount "${disk}${disk_prefix}2" /mnt
mkdir -p /mnt/boot
mount "${disk}${disk_prefix}1" /mnt/boot
swapon "${disk}${disk_prefix}3"

lsblk

# Install the base system
echo "Installing base system..."
pacstrap -K /mnt base linux sudo linux-firmware lib32-glibc grub efibootmgr vim "$cpu"-ucode

# Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab 

# Chroot into the new system
arch-chroot /mnt /bin/bash <<EOF
set -e 

install_packages() {
    echo "Installing packages: $*"
    sudo pacman -Sy --noconfirm $*
}

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

# Configure pacman
sed -i '/Color/s/^#//g' /etc/pacman.conf
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sed -i '/#\[multilib\]/s/^#//' /etc/pacman.conf
sed -i '/#Include = \/etc\/pacman\.d\/mirrorlist/s/^#//' /etc/pacman.conf

# Install Xorg
install_packages xorg-server xorg-xinit mesa

case $de_choice in
    1)
        install_packages gnome gnome-shell gnome-session gdm
        systemctl enable gdm
        ;;
    2)
        install_packages plasma kde-applications sddm
        systemctl enable sddm
        ;;
    3)
        install_packages xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
        systemctl enable lightdm
        ;;
    4)
        install_packages mate mate-extra lightdm
        systemctl enable lightdm
        ;;
    5)
        install_packages i3 ly
        systemctl enable ly
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Audio and media
echo "Installing audio and media packages..."
install_packages pipewire pipewire-pulse alsa-utils pavucontrol vlc

# Network and Internet
echo "Installing network and internet packages..."
install_packages networkmanager nm-connection-editor firefox

# Utilities
echo "Installing utilities..."
install_packages nano htop neofetch file-roller

# Fonts
echo "Installing fonts..."
install_packages ttf-dejavu ttf-liberation noto-font

# Enable essential services
echo "Enabling essential services..."
sudo systemctl enable NetworkManager

# Configure GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Unmount the partitions
echo "Unmounting partitions..."
umount -R /mnt

# Confirm reboot
read -p "Installation complete. Reboot now? (y/n): " confirm
if [[ "$confirm" == "y" ]]; then
    echo "Rebooting..."
    reboot
else
    echo "Reboot skipped. Exiting."
fi
