#!/bin/bash

set -eau

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Variables
user=$(whoami)

# Update pacman.conf
sudo bash -c '{
    sed -i "/Color/s/^#//g" /etc/pacman.conf
    sed -i "/ParallelDownloads/s/^#//g" /etc/pacman.conf
    sed -i "/ParallelDownloads/s/[0-9]\\+/2/" /etc/pacman.conf
    sed -i "/#\\[multilib\\]/s/^#//" /etc/pacman.conf
    sed -i "/#Include = \\/etc\\/pacman\\.d\\/mirrorlist/s/^#//" /etc/pacman.conf
    grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#Color/a ILoveCandy" /etc/pacman.conf
} || { echo "Failed to update pacman.conf"; exit 1; }'

# Install yay
if [[ ! -d yay-bin ]]; then
    git clone https://aur.archlinux.org/yay-bin.git
    sudo chown "$user:$user" -R yay-bin && cd yay-bin
    makepkg -si
    cd ..
else
    echo "yay-bin already exists. Skipping installation."
fi

# Install packages
packages=(steam wine winetricks firefox flatpak pulseaudio-bluetooth blueman bluez bluez-utils i3 git github-cli nmap wireshark-qt amd-ucode neovim vim john hydra aircrack-ng sqlmap hashcat nikto openbsd-netcat metasploit amd_ucode kitty systemd base xdg-desktop-portal xdg-desktop-portal-gtk base-devel efibootmgr sof-firmware mesa xf86-video-nouveau vulkan-mesa-layers lib32-vulkan-mesa-layers nvidia-prime arch-install-scripts nvidia-dkms nvidia-utils systemd linux linux-headers linux-firmware networkmanager network-manager-applet wireless_tools neofetch gvfs pavucontrol polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts adobe-source-han-sans-kr-fonts adobe-source-han-serif-kr-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts nano rofi curl make cmake meson obsidian man-db xdotool thunar nitrogen flameshot zip unzip mpv btop noto-fonts picom pulseaudio wireplumber dunst xarchiver eza thunar-archive-plugin)
yay -Syu "${packages[@]}"

# Prompt the user to install Roblox
read -p "Do you want to install Roblox? [y/N]: " choice
case $choice in
    y | Y)
        flatpak install --user https://sober.vinegarhq.org/sober.flatpakref
        ;;
    *)
        echo "Roblox installation skipped."
        ;;
esac

# Bluetooth
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

sudo systemctl restart pulseaudio

# Backup configurations
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
echo "---- Making backup at $backup_dir -----"
mkdir -p "$backup_dir"
sudo cp -rpf "$HOME/.config" "$backup_dir"
echo "----- Backup made at $backup_dir ------"

# Copy configurations
for config in dunst fcitx5 i3 nvim rofi omf; do
    sudo cp -rpf "$HOME/dotfiles/$config" "$HOME/.config/" || echo "Failed to copy $config"
done

for fonts in fonts/MartianMono fonts/SF-Mono-Powerline fonts/fontconfig; do
    sudo cp -rpf "$HOME/dotfiles/$fonts" "$HOME/.local/share/fonts/" || echo "Failed to copy $fonts"
done

mkdir -p "$HOME/.config/neofetch/" && sudo cp --parents -rpf "$HOME/dotfiles/neofetch/bk" "$HOME/.config/neofetch/"
mkdir -p "$HOME/Pictures/" && sudo cp -rpf "$HOME/dotfiles/Pictures/bgpic.jpg" "$HOME/Pictures/"
mkdir -p "$HOME/Videos/"

# Pulseaudio
sudo sed -i '/load-module module-suspend-on-idle/s/^/# /' /etc/pulse/default.pa
pulseaudio -k && pulseaudio --start

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
