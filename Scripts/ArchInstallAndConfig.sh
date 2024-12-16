#!/bin/bash

set -eauo pipefail

trap 'echo "An error occurred. Cleaning up..."; umount -R /mnt || true; swapoff ${disk}${disk_prefix}2 || true; exit 1' ERR
exec > >(tee -i install.log) 2>&1

pacman -Syu hwinfo

# Function to prompt for user input with a default value
export prompt() {
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
mkfs.vfat -F 32 "${disk}${disk_prefix}1"
mkfs.ext4 "${disk}${disk_prefix}3"
mkswap "${disk}${disk_prefix}2"

# Mount the filesystems
mount "${disk}${disk_prefix}3" /mnt
mkdir -p /mnt/boot
mount "${disk}${disk_prefix}1" /mnt/boot
swapon "${disk}${disk_prefix}2"

lsblk

# Install the base system
echo "Installing base system..."
pacstrap -K /mnt base base-devel sudo linux linux-headers linux-firmware grub efibootmgr "$cpu"-ucode

# Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab 

# Chroot into the new system
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

# Install Xorg
install_packages xorg-server xorg-xinit

# Desktop Enviroment
echo "Installing i3..."
install_packages i3 ly dmenu kitty ranger && systemctl enable ly.service
if [ -d "$dotfiles_dir/i3" ]; then
    echo "Copying i3 configuration..."
    cp -rpf "$dotfiles_dir/i3" "$HOME/.config/"
else
    echo "No i3 configuration found in $dotfiles_dir. Skipping config copy."
fi

# Audio

echo "Installing PipeWire and related packages..."
install_packages pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils pavucontrol
        
# Enable PipeWire services
echo "Enabling PipeWire services..."
systemctl --global enable pipewire.service wireplumber.service
        
# Configure ALSA to use PipeWire
echo "Configuring ALSA to use PipeWire..."
echo "defaults.pcm.card 0" > /etc/asound.conf
echo "defaults.ctl.card 0" >> /etc/asound.conf

# Network
echo "Installing network and internet packages..."
install_packages networkmanager 

# Enable Network
echo "Enabling essential services..."
systemctl enable NetworkManager 

# Browser
echo "Installing Firefox..."
install_packages qutebrowser

# Text Editor
install_packages neovim vim
if [ -d "$dotfiles_dir/nvim" ]; then
    echo "Copying neovim configuration..."
    cp -rpf "$dotfiles_dir/nvim" "$HOME/.config/"
else
    echo "No neovim configuration found in $dotfiles_dir. Skipping config copy."
fi

# Wine
echo "Installing Wine..."
install_packages wine winetricks

# Roblox
read -p "Do you want to install Roblox? [y/N]: " choice
case $choice in
    y | Y)
        echo "Installing Roblox..."
        install_packages flatpak
        flatpak install --user https://sober.vinegarhq.org/sober.flatpakref
        # Check if the alias already exists in .bashrc
        if ! grep -q "alias roblox=" $HOME/.bashrc; then
            echo "Adding Roblox alias to .bashrc..."
            echo "alias roblox='flatpak run org.vinegarhq.Sober'" >> $HOME/.bashrc
        else
            echo "Roblox alias already exists in .bashrc. Skipping addition."
        fi
        ;;
    *)
        echo "Roblox installation skipped."
        ;;
esac

# Steam
read -p "Do you want to install Steam [y/N]: " choice
case $choice in
    y | Y)
        echo "Installing Steam..."
        install_packages steam steam-native-runtime
        ;;
    *)
        echo "Steam installation skipped."
        ;;
esac

# Bluetooth
read -p "Do you want to install Bluetooth [y/N]: " choice
case $choice in
    y | Y)
        echo "Installing Bluetooth..."
        install_packages blueman bluez bluez-utils
        echo "Enabling Bluetooth..."
        systemctl enable bluetooth.service
        systemctl start bluetooth.service
        systemctl daemon-reload
        
        # Check if the alias already exists in .bashrc
        if ! grep -q "alias blueman=" $HOME/.bashrc; then
            echo "Adding Blueman alias to .bashrc..."
            echo "alias blueman='blueman-manager'" >> $HOME/.bashrc
            source $HOME/.bashrc
        else
            echo "Blueman alias already exists in .bashrc. Skipping addition."
        fi
        ;;
    *)
        echo "Bluetooth installation skipped."
        ;;
esac

echo "Select a graphics driver to install:"
echo "1) NVIDIA"
echo "2) AMD"
echo "3) Intel"
read -p "Enter your choice (1-3): " driver_choice
echo ""

# Default to NVIDIA if no input is provided
driver_choice=${driver_choice:-1}

case "$driver_choice" in
    1)
        echo "Installing NVIDIA drivers..."
        install_packages mesa nvidia-dkms nvidia-utils nvidia-settings nvidia-prime \
            lib32-nvidia-utils vulkan-mesa-layers lib32-vulkan-mesa-layers \
            xf86-video-nouveau opencl-nvidia lib32-opencl-nvidia

        prop=""
        NVIDIA_VENDOR="0x$(lspci -nn | grep -i nvidia | sed -n 's/.*\[\([0-9A-Fa-f]\+\):[0-9A-Fa-f]\+\].*/\1/p' | head -n 1)"
        
        # Create udev rules for NVIDIA power management
        echo "Creating udev rules for NVIDIA power management..."
        tee /etc/udev/rules.d/80-nvidia-pm.rules > /dev/null <<EOL
# Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"

# Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"

# Enable runtime PM for NVIDIA VGA/3D controller devices on adding device
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
EOL

        # Configure NVIDIA Dynamic Power Management
        echo "Configuring NVIDIA Dynamic Power Management..."
tee /etc/modprobe.d/nvidia-pm.conf > /dev/null <<EOL
options nvidia NVreg_DynamicPowerManagement=0x02
EOL
    2)
        echo "Installing AMD drivers..."
        install_packages mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon \
            lib32-mesa lib32-mesa-vdpau mesa-vdpau \
            opencl-mesa lib32-opencl-mesa
        ;;
    3)
        echo "Installing Intel drivers..."
        install_packages mesa xf86-video-intel vulkan-intel lib32-vulkan-intel \
            lib32-mesa intel-media-driver intel-compute-runtime \
            opencl-clang lib32-opencl-clang
        ;;
    *)
        echo "Invalid option. Defaulting to NVIDIA drivers..."
        install_packages mesa nvidia-dkms nvidia-utils nvidia-settings nvidia-prime \
            lib32-nvidia-utils vulkan-mesa-layers lib32-vulkan-mesa-layers \
            xf86-video-nouveau opencl-nvidia lib32-opencl-nvidia
        ;;
esac

# Tmux
install_packages tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Backup configurations
echo "---- Making backup at $backup_dir -----"
mkdir -p "$backup_dir"
cp -rpf "$HOME/.config" "$backup_dir"
echo "----- Backup made at $backup_dir ------"

# Copy configurations from dotfiles (example for dunst, rofi, etc.)
for config in dunst fcitx5 tmux qutebrowser rofi omf; do
    if [ -d "$dotfiles_dir/$config" ]; then
        cp -rpf "$dotfiles_dir/$config" "$HOME/.config/"
    else
        echo "No configuration found for $config. Skipping."
    fi
done

# Install fonts
for font in fonts/MartianMono fonts/SF-Mono-Powerline fonts/fontconfig; do
    if [ -d "$dotfiles_dir/$font" ]; then
        cp -rpf "$dotfiles_dir/$font" "$HOME/.local/share/fonts/"
    else
        echo "No font found for $font. Skipping."
    fi
done

# XDG_DIRS
echo "export XDG_CONFIG_HOME="$HOME/.config"" >> ~/.bashrc
echo "export XDG_DATA_HOME="$HOME/.local/share"" >> ~/.bashrc
echo "export XDG_STATE_HOME="$HOME/.local/state"" >> ~/.bashrc
echo "export XDG_CACHE_HOME="$HOME/.cache"" >> ~/.bashrc
mv "$dotfiles_dir"/Scripts/tmux-sessionizer .local/bin/
echo "export PATH=".local/bin/:$PATH"" >> ~/.bashrc

sudo sed -i "s/config.load_autoconfig(False)/config.load_autoconfig/(True)" $HOME/.config/qutebrowser/config.py
mkdir -p "$HOME/.config/neofetch/" && cp --parents -rpf "$dotfiles_dir/neofetch/bk" "$HOME/.config/neofetch/"
echo "alias neofetch="neofetch --source $HOME/.config/neofetch/bk"" >> $HOME/.bashrc
mkdir -p "$HOME/Pictures/" && cp -rpf "$dotfiles_dir/Pictures/bgpic.jpg" "$HOME/Pictures/"
mkdir -p "$HOME/Videos/"

# Utilities
echo "Installing utilities..."
packages=(git lazygit github-cli xdg-desktop-portal hwinfo arch-install-scripts wireless_tools neofetch fuse2 polkit fcitx5-im fcitx5-chinese-addons fcitx5-anthy fcitx5-hangul rofi curl make cmake meson obsidian man-db man-pages mandoc xdotool nitrogen flameshot zip unzip mpv btop noto-fonts picom dunst xarchiver eza fzf)
install_packages "${packages[@]}"

# Fonts
echo "Installing fonts..."
install_packages ttf-dejavu ttf-liberation unifont ttf-joypixels

# Enable time synchronization (choose chrony or ntpd)
echo "Enabling time synchronization..."
install_packages chrony networkmanager-dispatcher-chrony
systemctl enable chronyd

# Enable power management
echo "Enabling power management..."
install_packages tlp
systemctl enable tlp

read -p "Enter in any additional packages you wanna install (Type "none" for no package)" additional
additional="${additional:-none}"

# Configure GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

read -p "Enter in any additional packages you wanna install (Type "none" for no package)" additional
additional="${additional:-none}"

# Check if the user entered additional packages
if [[ "$additional" != "none" && "$additional" != "" ]]; then
    echo "Checking if additional packages exist: $additional"
    
    # Split the entered package names into an array (in case multiple packages are entered)
    IFS=' ' read -r -a Apackages <<< "$additional"
    
    # Loop through each package to check if it exists
    for i in "${!Apackages[@]}"; do
        while ! yay -Ss "^${Apackages[$i]}$" &>/dev/null || Apackages[$i] != "none"; do
            if [[ "${Apackages[$i]}" == "none" ]]; then
                echo "Skipping package installation for index $((i + 1))"
                break
            fi
            echo "Package '${Apackages[$i]}' not found in the official repositories. Please enter a valid package."
            read -p "Enter package ${i+1} again (Type "none" for no package): " Apackages[$i]
        done
        if [[ ${Apackages[$i]} != "none" ]]; then
            echo "Package '${Apackages[$i]}' found. Installing..."
        else
            echo "No packages to install..."
        fi
    done

    # Install the valid packages
    install_packages "${Apackages[@]}"
else
    echo "No additional packages will be installed."
fi
EOF

set +a

# Unmount the partitions
echo "Unmounting partitions..."
umount -R /mnt

reboot
