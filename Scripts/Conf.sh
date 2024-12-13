#!/bin/bash

set -euo pipefail

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Variables
user=$(whoami)
yay_choice=""
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
de_choice=""
browser_choice=""
editor_choice=""
audio_choice=""
driver_choice=""
dotfiles_dir=$(pwd)

# Check if yay is installed
if ! command -v yay &> /dev/null; then
    echo "Yay is not installed, this config uses yay to install packages"
    read -p "Install yay [y/N]: " yay_choice
    case $yay_choice in
        y | Y)
            # Install yay
            echo "Installing yay package manager..."
            cd ~
            git clone https://aur.archlinux.org/yay-bin.git
            sudo chown "$user:$user" -R yay-bin && cd yay-bin
            makepkg -si && cd .. && rm -rf yay
            cd "$dotfiles_dir"
            ;;
        *)
            echo "Exiting. Please install yay to proceed."
            exit 1
            ;;
    esac
fi

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
    sudo sed -i "$change" /etc/pacman.conf || { echo "Failed to update pacman.conf"; exit 1; }
done

# Custom bash theme
echo "Adding custom bash theme"
if grep -i "LS_COLORS" ~/.bashrc; then
    sudo sed -i '/LS_COLORS/c\export LS_COLORS="di=35;1:fi=33:ex=36;1"' ~/.bashrc
else
    echo 'export LS_COLORS="di=35;1:fi=33:ex=36;1"' >> ~/.bashrc
fi

# Adding parse_git_branch function
if ! grep -q "parse_git_branch" ~/.bashrc; then
    echo '' >> ~/.bashrc
    echo '# Function to parse the current Git branch' >> ~/.bashrc
    echo 'parse_git_branch() {' >> ~/.bashrc
    echo '    git branch 2>/dev/null | grep -E "^\*" | sed -E "s/^\* (.+)/(\1)/"' >> ~/.bashrc
    echo '}' >> ~/.bashrc
fi

# PS1
if grep -i "PS1" ~/.bashrc; then
    sudo sed -i '/PS1/c\export PS1='\[\033[01;34m\][\[\033[01;35m\]\u\[\033[00m\]:\[\033[01;36m\]\h\[\033[00m\] <> \[\033[01;34m\]\w\[\033[01;34m\]] \[\033[01;33m\]$(parse_git_branch)\[\033[00m\]'' ~/.bashrc
else
    echo 'export PS1='\[\033[01;34m\][\[\033[01;35m\]\u\[\033[00m\]:\[\033[01;36m\]\h\[\033[00m\] <> \[\033[01;34m\]\w\[\033[01;34m\]] \[\033[01;33m\]$(parse_git_branch)\[\033[00m\]'' >> ~/.bashrc
fi

# Ls alias
if grep -i "alias ls" ~/.bashrc; then
    sudo sed -i '/alias ls/c\alias ls="eza -al --color=auto"' ~/.bashrc
else
    echo 'alias ls="eza -al --color=auto"' >> ~/.bashrc
fi

# Desktop Enviroment
echo "Select a desktop environment to install:"
echo "1) GNOME"
echo "2) KDE Plasma"
echo "3) XFCE"
echo "4) MATE"
echo "5) i3 (Window Manager)"
read -p "Enter your choice (1-5): " de_choice
echo ""

# Default to i3 if no input is provided
de_choice=${de_choice:-5}

case "$de_choice" in
    1 | gnome | GNOME)
        echo "Installing GNOME..."
        install_packages gnome gnome-shell gnome-session gdm && sudo systemctl enable gdm.service
        ;;
    2 | plasma | KDE | kde | KDE_Plasma | kde_plasma)
        echo "Installing KDE Plasma..."
        install_packages plasma kde-applications sddm && sudo systemctl enable sddm.service
        ;;
    3 | xfce | XFCE)
        echo "Installing XFCE..."
        install_packages xfce4 xfce4-goodies lightdm lightdm-gtk-greeter && sudo systemctl enable lightdm.service
        ;;
    4 | mate | MATE)
        echo "Installing MATE..."
        install_packages mate mate-extra lightdm && sudo systemctl enable lightdm.service
        ;;
    5 | i3 | I3 | i3wm | I3WM)
        echo "Installing i3..."
        install_packages i3 ly dmenu kitty ranger && sudo systemctl enable ly.service
        if [ -d "$dotfiles_dir/i3" ]; then
            echo "Copying i3 configuration..."
            sudo cp -rpf "$dotfiles_dir/i3" "$HOME/.config/"
        else
            echo "No i3 configuration found in $dotfiles_dir. Skipping config copy."
        fi
        ;;
    *)
        echo "Invalid choice. Installing i3 by default..."
        install_packages i3 ly dmenu kitty ranger && sudo systemctl enable ly.service
        if [ -d "$dotfiles_dir/i3" ]; then
            echo "Copying i3 configuration..."
            sudo cp -rpf "$dotfiles_dir/i3" "$HOME/.config/"
        else
            echo "No i3 configuration found in $dotfiles_dir. Skipping config copy."
        fi
        ;;
esac

# Browser
echo "Select a browser to install:"
echo "1) Firefox"
echo "2) Brave"
echo "3) Librewolf"
echo "4) Chromium"
read -p "Enter your choice (1-4): " browser_choice
echo ""

# Default to firefox if no input is provided
browser_choice=${browser_choice:-1}

case "$browser_choice" in
    1)
        echo "Installing Firefox..."
        install_packages firefox
        ;;
    2)
        echo "Installing Brave..."
        install_packages brave-bin
        ;;
    3)
        echo "Installing LibreWolf..."
        install_packages librewolf-bin
        ;;
    4)
        echo "Installing Chromium..."
        install_packages chromium
        ;;
    *)
        echo "Invalid choice. Installing firefox by default..."
        install_packages firefox
        ;;
esac

# Text Editor
echo "Select a text editor to install:"
echo "1) Vim"
echo "2) Neovim"
echo "3) Nano"
echo "4) Emacs"
echo "5) Sublime Text"
read -p "Enter your choice (1-5): " editor_choice
echo ""

# Default to neovim if no input is provided
editor_choice=${editor_choice:-2}

case "$editor_choice" in
    1)
        echo "Installing Vim..."
        install_packages vim
        ;;
    2)
        echo "Installing Neovim..."
        install_packages neovim vim
        if [ -d "$dotfiles_dirnvim" ]; then
            echo "Copying neovim configuration..."
            sudo cp -rpf "$dotfiles_dir/nvim" "$HOME/.config/"
        else
            echo "No neovim configuration found in $dotfiles_dir. Skipping config copy."
        fi
        ;;
    3)
        echo "Installing Nano..."
        install_packages nano
        ;;
    4)
        echo "Installing Emacs..."
        install_packages emacs
        ;;
    5)
        echo "Installing Sublime Text..."
        install_packages sublime-text
        ;;
    *)
        echo "Invalid choice. Installing neovim by default..."
        install_packages neovim vim
        if [ -d "$dotfiles_dir/nvim" ]; then
            echo "Copying neovim configuration..."
            sudo cp -rpf "$dotfiles_dir/nvim" "$HOME/.config/"
        else
            echo "No neovim configuration found in $dotfiles_dir. Skipping config copy."
        fi
        ;;
esac


# Audio
read -p "Do you want to install PipeWire or PulseAudio? [pipewire]: " audio_choice

case $audio_choice in
    pulse | Pulse | pulseaudio | Pulseaudio)
        echo "Selected PulseAudio installation."
        # Check if PipeWire is installed and remove it if present
        if pacman -Q pipewire &>/dev/null; then
            echo "PipeWire detected. Removing it to avoid conflicts..."
            sudo pacman -Rns --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
        fi
        
        # Install PulseAudio and related packages
        echo "Installing PulseAudio and related packages..."
        install_packages pulseaudio pulseaudio-alsa alsa-utils pavucontrol
        
        # Disable PipeWire services if they were previously enabled
        echo "Disabling PipeWire services..."
        sudo systemctl --global disable pipewire.service wireplumber.service || true
        
        # Enable PulseAudio services
        echo "Enabling PulseAudio services..."
        sudo systemctl --global enable pulseaudio.service pulseaudio.socket
        sudo sed -i '/load-module module-suspend-on-idle/s/^/# /' /etc/pulse/default.pa
        
        # Configure ALSA to use PulseAudio
        echo "Configuring ALSA to use PulseAudio..."
        sudo bash -c 'echo "defaults.pcm.card 0" > /etc/asound.conf'
        sudo bash -c 'echo "defaults.ctl.card 0" >> /etc/asound.conf'
        ;;
    *)
        echo "Selected PipeWire installation."
        # Check if PulseAudio is installed and remove it if present
        if pacman -Q pulseaudio &>/dev/null; then
            echo "PulseAudio detected. Removing it to avoid conflicts..."
            sudo pacman -Rns --noconfirm pulseaudio pulseaudio-alsa
        fi
        
        # Install PipeWire and related packages
        echo "Installing PipeWire and related packages..."
        install_packages pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils pavucontrol
        
        # Disable PulseAudio service if it was previously enabled
        echo "Disabling PulseAudio services..."
        sudo systemctl --global disable pulseaudio.service pulseaudio.socket || true
        
        # Enable PipeWire services
        echo "Enabling PipeWire services..."
        sudo systemctl --global enable pipewire.service wireplumber.service
        
        # Configure ALSA to use PipeWire
        echo "Configuring ALSA to use PipeWire..."
        sudo bash -c 'echo "defaults.pcm.card 0" > /etc/asound.conf'
        sudo bash -c 'echo "defaults.ctl.card 0" >> /etc/asound.conf'
        ;;
esac

# Wine
read -p "Do you want to install Wine? [y/N]: " choice
case $choice in
    y | Y)
        echo "Installing Wine..."
        install_packages wine winetricks
        ;;
    *)
        echo "Wine installation skipped."
        ;;
esac

# Roblox
read -p "Do you want to install Roblox? [y/N]: " choice
case $choice in
    y | Y)
        echo "Installing Roblox..."
        install_packages flatpak
        flatpak install --user https://sober.vinegarhq.org/sober.flatpakref
        # Check if the alias already exists in .bashrc
        if ! grep -q "alias roblox=" ~/.bashrc; then
            echo "Adding Roblox alias to .bashrc..."
            echo "alias roblox='flatpak run org.vinegarhq.Sober'" >> ~/.bashrc
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
        install_packages steam
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
        sudo systemctl enable bluetooth.service
        sudo systemctl start bluetooth.service
        sudo systemctl daemon-reload
        
        # Check if the alias already exists in .bashrc
        if ! grep -q "alias blueman=" ~/.bashrc; then
            echo "Adding Blueman alias to .bashrc..."
            echo "alias blueman='blueman-manager'" >> ~/.bashrc
            source ~/.bashrc
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
        sudo tee /etc/udev/rules.d/80-nvidia-pm.rules > /dev/null <<EOL
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
sudo tee /etc/modprobe.d/nvidia-pm.conf > /dev/null <<EOL
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

# Install packages that i sue on my system
packages=(git lazygit github-cli xdg-desktop-portal arch-install-scripts networkmanager wireless_tools neofetch fuse2 polkit fcitx5-im fcitx5-chinese-addons fcitx5-anthy fcitx5-hangul ttf-dejavu unifont rofi curl make cmake meson obsidian man-db man-pages mandoc xdotool nitrogen flameshot zip unzip mpv btop noto-fonts picom dunst xarchiver eza fzf)
install_packages "${packages[@]}"

# Backup configurations
echo "---- Making backup at $backup_dir -----"
mkdir -p "$backup_dir"
sudo cp -rpf "$HOME/.config" "$backup_dir"
echo "----- Backup made at $backup_dir ------"

# Copy configurations from dotfiles (example for dunst, rofi, etc.)
for config in dunst fcitx5 rofi omf; do
    if [ -d "$dotfiles_dir/$config" ]; then
        sudo cp -rpf "$dotfiles_dir/$config" "$HOME/.config/"
    else
        echo "No configuration found for $config. Skipping."
    fi
done

# Install fonts
for font in fonts/MartianMono fonts/SF-Mono-Powerline fonts/fontconfig; do
    if [ -d "$dotfiles_dir/$font" ]; then
        sudo cp -rpf "$dotfiles_dir/$font" "$HOME/.local/share/fonts/"
    else
        echo "No font found for $font. Skipping."
    fi
done

mkdir -p "$HOME/.config/neofetch/" && sudo cp --parents -rpf "$dotfiles_dir/neofetch/bk" "$HOME/.config/neofetch/"
mkdir -p "$HOME/Pictures/" && sudo cp -rpf "$dotfiles_dir/Pictures/bgpic.jpg" "$HOME/Pictures/"
mkdir -p "$HOME/Videos/"

read -p "Enter in any additional packages you wanna install (Type "none" for no package)" additional
additional="${additional:-none}"

# Check if the user entered additional packages
if [[ "$additional" != "none" && "$additional" != "" ]]; then
    echo "Checking if additional packages exist: $additional"
    
    # Split the entered package names into an array (in case multiple packages are entered)
    IFS=' ' read -r -a Apackages <<< "$additional"
    
    # Loop through each package to check if it exists
    for i in "${!Apackages[@]}"; do
        while ! pacman -Ss "^${Apackages[$i]}$" &>/dev/null || Apackages[$i] != "none"; do
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

reboot
