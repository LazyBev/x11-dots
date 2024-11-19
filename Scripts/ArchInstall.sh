#!/bin/bash

set -eau

trap 'echo "An error occurred. Cleaning up..."; umount -R /mnt || true; swapoff ${disk}${disk_prefix}2 || true; exit 1' ERR
exec > >(tee -i install.log) 2>&1

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
export password=""; read -sp "Enter the password: " password; echo
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

if [[ $auto == "auto" ]]; then
    # Prompt for partition sizes
    read -p "Enter size for /boot partition (e.g., 512M): " boot_size
    read -p "Enter size for swap partition (e.g., 2G): " swap_size
    read -p "Enter size for /root partition (e.g., 25G): " root_size
    echo "The remaining space will be used for /home."

    # Partition the disk
    echo "Creating partitions on $disk..."
    parted "$disk" mklabel gpt # Create a new GPT partition table

    # Create the /boot partition
    parted -a optimal "$disk" mkpart primary fat32 1MiB "$boot_size"
    parted "$disk" set 1 boot on # Set boot flag for /boot partition

    # Create the swap partition
    parted -a optimal "$disk" mkpart primary linux-swap "$boot_size" "$swap_size"

    # Create the / partition
    parted -a optimal "$disk" mkpart primary ext4 "$swap_size" "$root_size"
else 
    echo "Launching cfdisk for manual partitioning"
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
mkfs.ext4 "${disk}${disk_prefix}3"
mkswap "${disk}${disk_prefix}2"

# Mount the filesystems
mount "${disk}${disk_prefix}3" /mnt
mount --mkdir "${disk}${disk_prefix}1" /mnt/boot
swapon "${disk}${disk_prefix}2"
for mntpnt in dev proc sys run; do 
    mount --bind /"$mntpnt" /mnt/"mntpnt"
done 

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

case $de_choice in
    1) sudo pacman -Sy --noconfirm gnome gnome-shell gnome-session gdm ;;
    2) sudo pacman -Sy --noconfirm plasma kde-applications sddm ;;
    3) sudo pacman -Sy --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter ;;
    4) sudo pacman -Sy --noconfirm mate mate-extra lightdm ;;
    5) sudo pacman -Sy --noconfirm i3 ly dmenu kitty ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
esac 

# Install Xorg
sudo pacman -Syu --noconfirm xorg-server xorg-xinit mesa

# Install PulseAudio and related packages
echo "Installing and configuring PulseAudio..."
sudo pacman -Sy --noconfirm pulseaudio pulseaudio-alsa pulseaudio-bluetooth alsa-utils pavucontrol pacmd pactl

# Network and Internet
echo "Installing network and internet packages..."
sudo pacman -Sy --noconfirm networkmanager nm-connection-editor firefox

# Utilities
echo "Installing utilities..."
sudo pacman -Sy --noconfirm nano htop neofetch file-roller

# Fonts
echo "Installing fonts..."
sudo pacman -Sy --noconfirm ttf-dejavu ttf-liberation

# Enable Network
echo "Enabling essential services..."
sudo systemctl enable NetworkManager 

# Enable time synchronization (choose chrony or ntpd)
echo "Enabling time synchronization..."
sudo pacman -Sy --noconfirm chrony
sudo systemctl enable chronyd

# Enable power management (useful for laptops)
echo "Enabling power management..."
sudo pacman -Sy --noconfirm tlp
sudo systemctl enable tlp

# Enable multilib repository (already handled, but confirm)
echo "Configuring multilib repository..."
sudo sed -i '/#\[multilib\]/s/^#//' /etc/pacman.conf
sudo sed -i '/#Include = \/etc\/pacman\.d\/mirrorlist/s/^#//' /etc/pacman.conf

# Desktop environment services (already enabled in your script)
case $de_choice in
    1) systemctl enable gdm ;;
    2) systemctl enable sddm ;;
    3) systemctl enable lightdm ;;
    4) systemctl enable lightdm ;;
    5) systemctl enable ly ;;
    *) exit 1 ;;
esac

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
