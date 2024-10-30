#!/bin/bash

set -eau

# Variables
user=$(whoami)

# Packages
git clone https://aur.archlinux.org/yay-bin.git
sudo chown "$user:$user" -R yay-bin && cd yay-bin 
makepkg -si && cd ..

yay -Syu steam wine firefox flatpak bluez bluez-utils i3 git github-cli nmap wireshark-qt amd-ucode neovim vim john hydra aircrack-ng sqlmap hashcat nikto openbsd-netcat metasploit amd_ucode kitty systemd base xdg-desktop-portal xdg-desktop-portal-gtk base-devel efibootmgr sof-firmware mesa xf86-video-nouveau vulkan-mesa-layers lib32-vulkan-mesa-layers nvidia-prime arch-install-scripts nvidia-dkms nvidia-utils systemd linux linux-headers linux-firmware networkmanager network-manager-applet wireless_tools neofetch gvfs pavucontrol polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts adobe-source-han-sans-kr-fonts adobe-source-han-serif-kr-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts nano rofi curl make cmake meson obsidian man-db xdotool thunar nitrogen flameshot zip unzip mpv btop emacs noto-fonts picom pulseaudio wireplumber dunst xarchiver eza thunar-archive-plugin
flatpak install --user https://sober.vinegarhq.org/sober.flatpakref

# Bluetooth
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
lsusb | grep -i bluetooth
sudo systemctl daemon-reload

# My config
echo "---- Making backup at $HOME/configBackup -----"
sudo cp -rpf "$HOME/.config" "$HOME/configBackup"
echo "----- Backup made at $HOME/configBackup ------"

# Copy configurations
for config in dunst fcitx5 mozc fish i3 nvim rofi omf; do
    sudo cp -rpf "$HOME/dotfiles/$config" "$HOME/.config/";
done

for fonts in fonts/MartianMono fonts/SF-Mono-Powerline fonts/fontconfig; do
    sudo cp -rpf "$HOME/dotfiles/$fonts" "$HOME/.local/share/fonts/";
done

mkdir -p "$HOME/.config/neofetch/" && sudo cp --parents -rpf "$HOME/dotfiles/neofetch/bk" "$HOME/.config/neofetch/"
mkdir -p "$HOME/Pictures/" && sudo cp -rpf "$HOME/dotfiles/Pictures/bgpic.jpg" "$HOME/Pictures/"
mkdir -p "$HOME/Videos/"

# Pacman.conf
sed -i '/Color/s/^#//g' /etc/pacman.conf
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sed -i '/#\[multilib\]/s/^#//' /etc/pacman.conf
sed -i '/#Include = \/etc\/pacman\.d\/mirrorlist/s/^#//' /etc/pacman.conf

~/.config/emacs/bin/doom install
~/.config/emacs/bin/doom sync

# Install the necessary packages
prop=""
NVIDIA_VENDOR="0x10de"

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

# Start and enable the NVIDIA persistence daemon
echo "Starting and enabling NVIDIA persistence daemon..."
sudo systemctl start nvidia-persistenced.service
sudo systemctl enable nvidia-persistenced.service
    
yay -S fish

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
chsh -s /usr/bin/fish

reboot
