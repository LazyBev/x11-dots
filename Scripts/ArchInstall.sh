#!/bin/bash

set -eao pipefail

trap 'echo "An error occurred. Cleaning up..."; umount -R /mnt || true; swapoff ${disk}${disk_prefix}2 || true; exit 1' ERR
exec > >(tee -i install.log) 2>&1

pacman -Sy hwinfo

# Function to prompt for user input with a default value
prompt() {
    local prompt_text="$1"
    local default_value="$2"
    read -p "$prompt_text [$default_value]: " input
    echo "${input:-$default_value}"
}

lsblk

# Ask for user input
disk=$(prompt "Enter the disk to install Arch Linux (e.g., /dev/nvme0n1)" "/dev/nvme0n1")

# Validate disk input
if [[ ! -b "$disk" ]]; then
    echo "Error: $disk is not a valid block device."
    exit 1
fi 

hostname=$(prompt "Enter the hostname" "gentuwu")
user=$(prompt "Enter the username" "user")
password=""
read -sp "Enter the password [1234]: " password
echo ""
password=${password:-1234}
keyboard=$(prompt "Enter key map for keyboard" "uk")
locale=$(prompt "Enter the locale" "en_GB.UTF-8")
timezone=$(prompt "Enter the timezone" "Europe/London")
intel_cpu=$(hwinfo --cpu | head -n6 | grep "Intel")
amd_cpu=$(hwinfo --cpu | head -n6 | grep "AMD")
cpu=""

# Determine which CPU is present
if [[ -n "$intel_cpu" ]]; then
    echo "Intel CPU detected."
    cpu="intel"
elif [[ -n "$amd_cpu" ]]; then
    echo "AMD CPU detected."
    cpu="amd"
else
    echo "No Intel or AMD CPU detected, or hwinfo could not detect the CPU."
fi


timedatectl set-ntp true
loadkeys "$keyboard"

# Confirm disk operations
read -p "WARNING: This will erase all data on $disk. Continue? (y/n): " confirm
[[ "$confirm" != "y" ]] && exit 1

lsblk 

auto=$(prompt "Manual or auto disk partitioning" "auto")

# Wipe the disk and partition
echo "Wiping $disk and creating partitions..."
wipefs -af "$disk"

if [[ $auto == "auto" ]]; then
    # Automatically calculate partition sizes based on disk size
    disk_size=$(lsblk -b -n -d -o SIZE "$disk" | awk '{print int($1 / 1024 / 1024)}')
    boot_size=1024
    root_size=$((disk_size - boot_size))

    echo "Auto-partitioning: /boot=${boot_size}MiB, /root=${root_size}MiB"
    parted "$disk" mklabel gpt
    parted "$disk" mkpart primary fat32 1MiB "${boot_size}MiB"
    parted "$disk" set 1 boot on
    parted "$disk" mkpart primary ext4 "$((boot_size))MiB" "$((disk_size - boot_size))MiB"
else
    echo "Launching cfdisk for manual partitioning"
    cfdisk "$disk"
fi

# Validate partition existence
if [[ ! -e "${disk}p1" || ! -e "${disk}p2" || ! -e "${disk}p3" ]]; then
    echo "Error: Partitions not found. Please partition the disk properly and try again."
    exit 1
fi

# Format the partitions
echo "Formatting partitions..."
mkfs.vfat -F 32 "${disk}p1"
mkfs.ext4 "${disk}p3"
mkswap "${disk}p2"

# Mount the filesystems
mount "${disk}p3" /mnt
mkdir -p /mnt/boot
mount "${disk}p1" /mnt/boot
swapon "${disk}p2"

lsblk

# Install the base system
echo "Installing base system..."
pacstrap -K /mnt base base-devel sudo linux linux-headers linux-firmware grub efibootmgr "$cpu"-ucode

# Generate fstab
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
de_choice=""
browser_choice=""
editor_choice=""
audio_choice=""
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
cp /etc/pacman.conf /etc/pacman.conf.bak || { echo "Failed to back up pacman.conf"; exit 1;}

echo "Modifying /etc/pacman.conf"
for change in "${pacman_conf[@]}"; do
    sed -i "$change" /etc/pacman.conf || { echo "Failed to update pacman.conf"; exit 1; }
done

# Custom bash theme
echo "Adding custom bash theme"
if grep -i "LS_COLORS" $HOME/.bashrc; then
    sed -i '/LS_COLORS/c\export LS_COLORS="di=35;1:fi=33:ex=36;1"' $HOME/.bashrc
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
    sed -i '/PS1/c\export PS1='\[\033[01;34m\][\[\033[01;35m\]\u\[\033[00m\]:\[\033[01;36m\]\h\[\033[00m\] <> \[\033[01;34m\]\w\[\033[01;34m\]] \[\033[01;33m\]$(parse_git_branch)\[\033[00m\]'' $HOME/.bashrc
else
    echo 'export PS1='\[\033[01;34m\][\[\033[01;35m\]\u\[\033[00m\]:\[\033[01;36m\]\h\[\033[00m\] <> \[\033[01;34m\]\w\[\033[01;34m\]] \[\033[01;33m\]$(parse_git_branch)\[\033[00m\]'' >> $HOME/.bashrc
fi

# Ls alias
if grep -i "alias ls" $HOME/.bashrc; then
    sed -i '/alias ls/c\alias ls="eza -al --color=auto"' $HOME/.bashrc
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
install_packages networkmanager 

# Enable Network
echo "Enabling essential services..."
systemctl enable NetworkManager 
EOF

set +a

# Unmount the partitions
echo "Unmounting partitions..."
umount -R /mnt

reboot
