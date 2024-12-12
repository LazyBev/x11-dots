#!/bin/bash

set -eau

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Variables
user=$(whoami)

# Backup the pacman.conf before modifying
sudo cp /etc/pacman.conf /etc/pacman.conf.bak || { echo "Failed to back up pacman.conf"; exit 1;}

# Configuring pacman.conf
sudo sed -i "/Color/s/^#//g" /etc/pacman.conf || { echo "Failed to update pacman.conf"; exit 1; }
sudo sed -i "/ParallelDownloads/s/^#//g" /etc/pacman.conf || { echo "Failed to update pacman.conf"; exit 1; }
sudo sed -i "/#\\[multilib\\]/s/^#//" /etc/pacman.conf || { echo "Failed to update pacman.conf"; exit 1; }
sudo sed -i "/#Include = \\/etc\\/pacman\\.d\\/mirrorlist/s/^#//" /etc/pacman.conf || { echo "Failed to update pacman.conf"; exit 1; }
sudo sed -i '/#DisableSandbox/a ILoveCandy' /etc/pacman.conf || { echo "Failed to update pacman.conf"; exit 1; }

# Check if yay is installed
if ! command -v yay &> /dev/null; then
    read -p "Install yay [y/N]: " yay_choice
    case $yay_choice in
        y | Y)
            # Install yay
            echo "Installing yay package manager..."
            git clone https://aur.archlinux.org/yay-bin.git
            sudo chown "$user:$user" -R yay-bin && cd yay-bin
            makepkg -si && cd .. && rm -rf yay
            ;;
        *)
            echo "Exiting. Please install yay to proceed."
            exit 1
            ;;
    esac
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

case "$de_choice" in
    1 | gnome | GNOME)
        echo "Installing GNOME..."
        sudo pacman -Sy --noconfirm gnome gnome-shell gnome-session gdm
        sudo systemctl enable gdm.service
        ;;
    2 | plasma | KDE | kde | KDE_Plasma | kde_plasma)
        echo "Installing KDE Plasma..."
        sudo pacman -Sy --noconfirm plasma kde-applications sddm
        sudo systemctl enable sddm.service
        ;;
    3 | xfce | XFCE)
        echo "Installing XFCE..."
        sudo pacman -Sy --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
        sudo systemctl enable lightdm.service
        ;;
    4 | mate | MATE)
        echo "Installing MATE..."
        sudo pacman -Sy --noconfirm mate mate-extra lightdm
        sudo systemctl enable lightdm.service
        ;;
    5 | i3 | I3 | i3wm | I3WM)
        echo "Installing i3..."
        sudo pacman -Sy --noconfirm i3 ly dmenu kitty ranger
        sudo systemctl enable ly.service
        if [ -d "$HOME/dotfiles/i3" ]; then
            echo "Copying i3 configuration..."
            sudo cp -rpf "$HOME/dotfiles/i3" "$HOME/.config/"
        else
            echo "No i3 configuration found in ~/dotfiles. Skipping config copy."
        fi
        ;;
    *)
        echo "Invalid choice. Installing i3 by default..."
        sudo pacman -Sy --noconfirm i3 ly dmenu kitty ranger
        sudo systemctl enable ly.service
        if [ -d "$HOME/dotfiles/i3" ]; then
            echo "Copying i3 configuration..."
            sudo cp -rpf "$HOME/dotfiles/i3" "$HOME/.config/"
        else
            echo "No i3 configuration found in ~/dotfiles. Skipping config copy."
        fi
        ;;
esac

# Browser
echo "Select a browser to install:"
echo "1) Firefox"
echo "2) Brave"
echo "3) Librewolf"
echo "4) Chromium"
read -p "Enter your choice (1-4): " choice
echo ""

case "$choice" in
    1)
        echo "Installing Firefox..."
        yay -Sy --noconfirm firefox
        ;;
    2)
        echo "Installing Brave..."
        yay -Sy --noconfirm brave-bin
        ;;
    3)
        echo "Installing LibreWolf..."
        yay -Sy --noconfirm librewolf-bin
        ;;
    4)
        echo "Installing Chromium..."
        yay -Sy --noconfirm chromium
        ;;
    *)
        echo "Invalid choice. Installing firefox by default..."
        yay -Sy --noconfirm firefox
        exit 1
        ;;
esac

# Text Editor
echo "Select a text editor to install:"
echo "1) Vim"
echo "2) Neovim"
echo "3) Nano"
echo "4) Emacs"
echo "5) Sublime Text"
read -p "Enter your choice (1-5): " choice
echo ""

case "$choice" in
    1)
        echo "Installing Vim..."
        yay -Sy --noconfirm vim
        ;;
    2)
        echo "Installing Neovim..."
        yay -Sy --noconfirm neovim vim
        if [ -d "$HOME/dotfiles/nvim" ]; then
            echo "Copying neovim configuration..."
            sudo cp -rpf "$HOME/dotfiles/nvim" "$HOME/.config/"
        else
            echo "No neovim configuration found in ~/dotfiles. Skipping config copy."
        fi
        ;;
    3)
        echo "Installing Nano..."
        yay -Sy --noconfirm nano
        ;;
    4)
        echo "Installing Emacs..."
        yay -Sy --noconfirm emacs
        ;;
    5)
        echo "Installing Sublime Text..."
        yay -Sy --noconfirm sublime-text
        ;;
    *)
        echo "Invalid choice. Installing neovim by default..."
        yay -Sy --noconfirm neovim vim
        if [ -d "$HOME/dotfiles/nvim" ]; then
            echo "Copying neovim configuration..."
            sudo cp -rpf "$HOME/dotfiles/nvim" "$HOME/.config/"
        else
            echo "No neovim configuration found in ~/dotfiles. Skipping config copy."
        fi
        ;;
esac


# Audio
read -p "Do you want to install PipeWire or PulseAudio? [pipewire]: " choice
case $choice in
    pulse | Pulse | pulseaudio | Pulseaudio)
        echo "Selected PulseAudio installation."
        # Check if PipeWire is installed and remove it if present
        if pacman -Q pipewire &>/dev/null; then
            echo "PipeWire detected. Removing it to avoid conflicts..."
            sudo pacman -Rns --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
        fi
        
        # Install PulseAudio and related packages
        echo "Installing PulseAudio and related packages..."
        sudo pacman -Syu --noconfirm pulseaudio pulseaudio-alsa alsa-utils pavucontrol
        
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
        sudo pacman -Syu --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils pavucontrol
        
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
        yay -Syu wine winetricks
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
        yay -Syu flatpak
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
        yay -Syu steam
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
        yay -Syu blueman bluez bluez-utils
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
read -p "Enter your choice (1-3): " choice
echo ""

case "$choice" in
    1)
        echo "Installing NVIDIA drivers..."
        yay -Sy --noconfirm mesa nvidia-dkms nvidia-utils \ 
            xf86-video-nouveau vulkan-mesa-layers lib32-vulkan-mesa-layers nvidia-prime \
            
        ;;
    2)
        echo "Installing AMD drivers..."
        yay -Sy --noconfirm mesa xf86-video-amdgpu
        ;;
    3)
        echo "Installing Intel drivers..."
        yay -Sy --noconfirm mesa xf86-video-intel
        ;;
    *)
        echo "Invalid option, please choose a number between 1 and 5."
        ;;
esac

git github-cli

# Install packages
packages=(xdg-desktop-portal xdg-desktop-portal-gtk base-devel arch-install-scripts networkmanager wireless_tools neofetch gvfs polkit-gnome lxappearance fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts adobe-source-han-sans-kr-fonts adobe-source-han-serif-kr-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts rofi curl make cmake meson obsidian man-db xdotool nitrogen flameshot zip unzip mpv btop noto-fonts picom dunst xarchiver eza fzf)
yay -Syu "${packages[@]}"

# Backup configurations
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
echo "---- Making backup at $backup_dir -----"
mkdir -p "$backup_dir"
sudo cp -rpf "$HOME/.config" "$backup_dir"
echo "----- Backup made at $backup_dir ------"

# Copy configurations
for config in dunst fcitx5 rofi omf; do
    sudo cp -rpf "$HOME/dotfiles/$config" "$HOME/.config/" || echo "Failed to copy $config"
done

for fonts in fonts/MartianMono fonts/SF-Mono-Powerline fonts/fontconfig; do
    sudo cp -rpf "$HOME/dotfiles/$fonts" "$HOME/.local/share/fonts/" || echo "Failed to copy $fonts"
done

wget https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf
mv NotoColorEmoji.ttf ~/.local/share/fonts

mkdir -p "$HOME/.config/neofetch/" && sudo cp --parents -rpf "$HOME/dotfiles/neofetch/bk" "$HOME/.config/neofetch/"
mkdir -p "$HOME/Pictures/" && sudo cp -rpf "$HOME/dotfiles/Pictures/bgpic.jpg" "$HOME/Pictures/"
mkdir -p "$HOME/Videos/"

# Install the necessary packages
prop=""
NVIDIA_VENDOR="0x$(lspci -nn | grep -i nvidia | sed -n 's/.*\[\([0-9A-Fa-f]\+\):[0-9A-Fa-f]\+\].*/\1/p' | head -n 1)"

# Check available graphics providers and OpenGL renderer
xrandr --listproviders && glxinfo | grep "OpenGL renderer"

# Set up the offloading sink for hybrid graphics (replace radeon if necessary)
echo "Setting offloading sink..."
read -p "Enter the provider number for offloading sink (e.g., 1): " provider_number
xrandr --setprovideroffloadsink $provider_number

# Check OpenGL renderer for PRIME offloading and GPU power state
DRI_PRIME=1 glxinfo | grep "OpenGL renderer"
cat /sys/class/drm/card*/device/power_state

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

# Check runtime power management status and suspended time for the NVIDIA device
echo "Checking NVIDIA power management status..."
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_suspended_time

# Install Starship
curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init bash)"' >> ~/.bashrc

# Check if the alias already exists in .bashrc
if ! grep -q "alias blueman=" ~/.bashrc; then
    echo "Adding Blueman alias to .bashrc..."
    echo "alias blueman='blueman-manager'" >> ~/.bashrc
    source ~/.bashrc
else
    echo "Blueman alias already exists in .bashrc. Skipping addition."
fi

# Prompt the user to reboot
read -p "Would you like to reboot now? [y/N]: " reboot_choice
case $reboot_choice in
    y | Y)
        run_command reboot
        ;;
    *)
        echo "Reboot skipped. Please reboot manually if necessary."
        ;;
esac
