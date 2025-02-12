#!/bin/bash
set -eo pipefail

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Variables
yay_choice=""
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
de_choice=""
browser_choice=""
editor_choice=""
audio_choice=""
driver_choice=""
dotfiles_dir="$HOME/dotfiles"

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
#echo 'export LS_COLORS="di=35;1:fi=33:ex=36;1"' >> $HOME/.bashrc
#echo 'export PS1='\[\033[01;34m\][\[\033[01;35m\]\u\[\033[00m\]:\[\033[01;36m\]\h\[\033[00m\] <> \[\033[01;34m\]\w\[\033[01;34m\]] \[\033[01;33m\]'' >> $HOME/.bashrc

# Ls alias
echo 'alias ls="eza -al --color=auto"' >> $HOME/.bashrc

# Install yay 
cd ~
echo "Installing yay package manager..."
git clone https://aur.archlinux.org/yay-bin.git
sudo chown "$user:$user" -R $HOME/yay-bin
cd yay-bin && makepkg -si && cd .. && rm -rf yay-bin
cd "$dotfiles_dir"

# Install Xorg
echo "Installing xorg..."
yay -Sy  xorg xorg-server xorg-xinit

# Desktop Enviroment
echo "Installing i3..."
yay -Sy  i3 ly dmenu ranger
if [ -d "$dotfiles_dir/i3" ]; then
    echo "Copying i3 configuration..."
    sudo cp -rpf "$dotfiles_dir/i3" "$HOME/.config/"
else
    echo "No i3 configuration found in $dotfiles_dir. Skipping config copy."
fi

# Ghostty Term
echo "Installing ghostty..."
yay -Sy  ghostty
if [ -d "$dotfiles_dir/ghostty" ]; then
    echo "Copying ghostty configuration..."
    cp -rpf "$dotfiles_dir/ghostty" "$HOME/.config/"
else
    echo "No ghostty configuration found in $dotfiles_dir. Skipping config copy."
fi

# Installing PipeWire services
echo "Installing PipeWire and related packages..."
yay -Sy  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils pavucontrol
        
# Configure ALSA to use PipeWire
echo "Configuring ALSA to use PipeWire..."
echo tee /etc/asound.conf <<ASOUND
defaults.pcm.card 0
defaults.ctl.card 0
ASOUND

# Browser
echo "Installing firefox..."
yay -Sy  firefox

# Text Editor
yay -Sy  neovim vim
if [ -d "$dotfiles_dir/nvim" ]; then
    echo "Copying neovim configuration..."
    sudo cp -rpf "$dotfiles_dir/nvim" "$HOME/.config/"
else
    echo "No neovim configuration found in $dotfiles_dir. Skipping config copy."
fi
rm -rf ~/.config/nvim
yay -Sy  lua
git clone https://luajit.org/git/luajit.git
cd luajit && make && sudo make install
cd .. && git clone https://github.com/LazyVim/LazyVim.git ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Wine
echo "Installing Wine..."
yay -Sy  wine winetricks

# Roblox
read -p "Do you want to install Roblox? [y/N]: " choice
case $choice in
    y | Y)
        echo "Installing Roblox..."
        yay -Sy  flatpak
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
        yay -Sy  steam steam-native-runtime
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
        yay -Sy  blueman bluez bluez-utils
        echo "Enabling Bluetooth..."
        sudo systemctl enable bluetooth.service
        sudo systemctl start bluetooth.service
        sudo systemctl daemon-reload
        
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
        yay -Sy  mesa nvidia-dkms nvidia-utils nvidia-settings nvidia-prime \
            lib32-nvidia-utils vulkan-mesa-layers lib32-vulkan-mesa-layers \
            xf86-video-nouveau opencl-nvidia lib32-opencl-nvidia

        prop=""
        NVIDIA_VENDOR="0x$(lspci -nn | grep -i nvidia | sed -n 's/.*\[\([0-9A-Fa-f]\+\):[0-9A-Fa-f]\+\].*/\1/p' | head -n 1)"
        
        # Create udev rules for NVIDIA power management
        echo "Creating udev rules for NVIDIA power management..."
        sudo mv "$dotfiles_dir/Misc/80-nvidia-pm.rules" /etc/udev/rules.d/

        # Configure NVIDIA Dynamic Power Management
        echo "Configuring NVIDIA Dynamic Power Management..."
        sudo mv "$dotfiles_dir/Misc/nvidia-pm.conf" /etc/modprobe.d/
        ;;
    2)
        echo "Installing AMD drivers..."
        yay -Sy  mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon \
            lib32-mesa lib32-mesa-vdpau mesa-vdpau \
            opencl-mesa lib32-opencl-mesa
        ;;
    3)
        echo "Installing Intel drivers..."
        yay -Sy  mesa xf86-video-intel vulkan-intel lib32-vulkan-intel \
            lib32-mesa intel-media-driver intel-compute-runtime \
            opencl-clang lib32-opencl-clang
        ;;
    *)
        echo "Invalid option. Defaulting to NVIDIA drivers..."
        yay -Sy  mesa nvidia-dkms nvidia-utils nvidia-settings nvidia-prime \
            lib32-nvidia-utils vulkan-mesa-layers lib32-vulkan-mesa-layers \
            xf86-video-nouveau opencl-nvidia lib32-opencl-nvidia
        ;;
esac

# Tmux
yay -Sy  tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
if [ -e "$dotfiles_dir/tmux-sessionizer" ]; then
        cp -rpf "$dotfiles_dir/Scripts/tmux-sessionizer" "/bin"
    else
        echo "No tmux-sessionizer file found. SKipping installtion"
fi

# Utilities
echo "Installing utilities..."
packages=(git lazygit github-cli qutebrowser xdg-desktop-portal hwinfo arch-install-scripts wireless_tools neofetch fuse2 polkit fcitx5-im fcitx5-chinese-addons fcitx5-anthy fcitx5-hangul rofi curl make cmake meson obsidian man-db man-pages mandoc xdotool nitrogen flameshot zip unzip mpv btop noto-fonts picom dunst xarchiver eza fzf)
yay -Sy  "${packages[@]}"

# Backup configurations
echo "---- Making backup at $backup_dir -----"
mkdir -p "$backup_dir"
cp -rpf "$HOME/.config" "$backup_dir"
echo "----- Backup made at $backup_dir ------"

# Clearing configs
for config in dunst fcitx5 tmux qutebrowser i3 nvim rofi ghostty; do
    rm -rf "~/.config/$config"
done

# Copy configurations from dotfiles (example for dunst, rofi, etc.)
for config in dunst fcitx5 tmux qutebrowser i3 nvim rofi ghostty; do
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
echo "export PATH=".local/bin/:$PATH"" >> ~/.bashrc

mkdir -p "$HOME/.config/neofetch/" && cp -rf "$dotfiles_dir/neofetch/bk" "$HOME/.config/neofetch/"
echo "alias neofetch='neofetch --source $HOME/.config/neofetch/bk'" >> $HOME/.bashrc
mkdir -p "$HOME/Pictures/" && cp -rpf "$dotfiles_dir/Pictures/bgpic.jpg" "$HOME/Pictures/"
mkdir -p "$HOME/Videos/"
sudo mv "$dotfiles_dir/Misc/picom.conf" "$HOME/.config"

# Fonts
echo "Installing fonts..."
yay -Sy  ttf-dejavu ttf-liberation unifont ttf-joypixels

# Enable power management
echo "Enabling power management..."
yay -Sy  tlp
sudo systemctl enable tlp

# Network
echo "Installing network and internet packages..."
yay -Sy  iwd

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
    yay -Sy  "${Apackages[@]}"
else
    echo "No additional packages will be installed."
fi

reboot
