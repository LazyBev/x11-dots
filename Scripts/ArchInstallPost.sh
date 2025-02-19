#!/bin/bash
set -eo pipefail

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Variables
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
dotfiles_dir="$HOME/dotfiles"

# Backup configurations 
if [ -d "$HOME/.config" ]; then 
    echo "---- Making backup at $backup_dir -----"
    mkdir -p "$backup_dir"
    sudo cp -rpf "$HOME/.config" "$backup_dir"
    echo "----- Backup made at $backup_dir ------"
fi 

if [ -d "$dotfiles_dir" ]; then
    echo ""
else
    sudo pacman -Sy git && cd ..
    rm -rf dotfiles && cd $HOME
    git clone https://github.com/LazyBev/dotfiles && cd dotfiles/Scripts
fi

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

# Install yay 
cd ~
echo "Installing yay package manager..."
git clone https://aur.archlinux.org/yay-bin.git
sudo chown "$user:$user" -R $HOME/yay-bin
cd yay-bin && makepkg -si && cd .. && rm -rf yay-bin
cd "$dotfiles_dir"

# Installing the needed packages i use
yay -Syu iwd tlp stow stremio fcitx5-im zsh fastfetch wget fcitx5-chinese-addons fcitx5-anthy fcitx5-hangul ttf-dejavu ttf-liberation ttf-joypixels ttf-meslo-nerd noto-fonts adobe-source-han-mono-jp-fonts adobe-source-han-mono-hk-fonts adobe-source-han-mono-kr-fonts adobe-source-han-mono-tw-fonts adobe-source-han-mono-otc-fonts adobe-source-han-mono-cn-fonts tmux blueman bluez bluez-utils steam steam-native-runtime flatpak wine winetricks neovim lua ripgrep vim librewolf-bin pulseaudio wireplumber pulseaudio-alsa alsa-utils pavucontrol ghostty i3 ranger xorg xorg-server xorg-xinit acpi git lazygit github-cli polybar xdg-desktop-portal hwinfo arch-install-scripts wireless_tools neofetch fuse2 polkit rofi curl make cmake meson obsidian man-db man-pages xdotool feh thunar qutebrowser flameshot zip unzip mpv btop picom dunst xarchiver eza fzf
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh; sh install.sh; rm -rf install.sh;
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH_CUSTOM/plugins/zsh-autocomplete
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
flatpak install flathub com.discordapp.Discord
flatpak install https://sober.vinegarhq.org/sober.flatpakref

# Arti (tor but written in rust)
git clone https://gitlab.torproject.org/tpo/core/arti.git
cd arti && cargo build -p arti --release;
sudo cp target/release/arti /usr/local/bin/
cd .. && rm -rf arti
sudo tee ~/.config/arti/arti-config.toml <<ART
[network]
socks_port = 9050
ART

# mov-cli
cd $HOME; git clone https://github.com/hpjansson/chafa.git
cd chafa && ./autogen.sh
make && sudo make install
cd $HOME && python -m venv yt
bash -c "source yt/bin/activate; pip install lxml; pip install mov-cli -U; pip install mov-cli-youtube;"

# Configure ALSA to use pulseaudio
echo "Configuring ALSA to use pulseaudio..."
echo tee /etc/asound.conf <<ASOUND
defaults.pcm.card 0
defaults.ctl.card 0
ASOUND

sudo sed -i "/load-module module-suspend-on-idle/c\# load-module module-suspend-on-idle" /etc/pulse/default.pa

touch discord
DC="$HOME/discord"
sudo echo 'flatpak run com.discordapp.Discord' >> $DC
sudo mv $DC /bin

# Bluetooth
echo "Enabling Bluetooth..."
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
sudo systemctl daemon-reload

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
        yay -Sy --needed mesa nvidia-dkms nvidia-utils nvidia-settings nvidia-prime \
            lib32-nvidia-utils vulkan-mesa-layers lib32-vulkan-mesa-layers \
            xf86-video-nouveau opencl-nvidia lib32-opencl-nvidia
        
        # Get NVIDIA vendor ID
        NVIDIA_VENDOR="0x$(lspci -nn | grep -i nvidia | sed -n 's/.*\[\([0-9A-Fa-f]\+\):[0-9A-Fa-f]\+\].*/\1/p' | head -n 1)"
        
        # Create udev rules for NVIDIA power management
        echo "# Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
        ACTION==\"bind\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030000\", TEST==\"power/control\", ATTR{power/control}=\"auto\"
        ACTION==\"bind\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030200\", TEST==\"power/control\", ATTR{power/control}=\"auto\"

        # Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
        ACTION==\"unbind\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030000\", TEST==\"power/control\", ATTR{power/control}=\"on\"
        ACTION==\"unbind\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030200\", TEST==\"power/control\", ATTR{power/control}=\"on\"

        # Enable runtime PM for NVIDIA VGA/3D controller devices on adding device
        ACTION==\"add\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030000\", TEST==\"power/control\", ATTR{power/control}=\"auto\"
        ACTION==\"add\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030200\", TEST==\"power/control\", ATTR{power/control}=\"auto\"" | envsubst | sudo tee /etc/udev/rules.d/80-nvidia-pm.rules > /dev/null

        # Set NVIDIA kernel module options
        echo "options nvidia NVreg_UsePageAttributeTable=1
        options nvidia_drm modeset=1
        options nvidia NVreg_RegistryDwords="PerfLevelSrc=0x2222"
        options nvidia NVreg_EnablePCIeGen3=1 NVreg_EnableMSI=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
        
        # Apply NVIDIA settings
        sudo nvidia-xconfig --cool-bits=28 
        
        # Disable auto-boost and set clock speeds
        sudo nvidia-smi --auto-boost-default=0
        sudo nvidia-smi -i 0 -ac 5001,2000
        
        # Enable and start NVIDIA persistence daemon
        sudo systemctl enable nvidia-persistenced.service
        
        # Regenerate initramfs
        sudo mkinitcpio -P
        
        # Apply udev rules immediately
        sudo udevadm control --reload-rules && sudo udevadm trigger
        ;;
    2)
        echo "Installing AMD drivers..."
        yay -Sy mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon lib32-mesa lib32-mesa-vdpau mesa-vdpau opencl-mesa lib32-opencl-mesa
        ;;
    3)
        echo "Installing Intel drivers..."
        yay -Sy mesa xf86-video-intel vulkan-intel lib32-vulkan-intel lib32-mesa intel-media-driver intel-compute-runtime opencl-clang lib32-opencl-clang
        ;;
    *)
        echo "Invalid option. Defaulting to NVIDIA drivers..."
        echo "Installing NVIDIA drivers..."
        yay -Sy --needed mesa nvidia-dkms nvidia-utils nvidia-settings nvidia-prime \
            lib32-nvidia-utils vulkan-mesa-layers lib32-vulkan-mesa-layers \
            xf86-video-nouveau opencl-nvidia lib32-opencl-nvidia
        
        # Get NVIDIA vendor ID
        NVIDIA_VENDOR="0x$(lspci -nn | grep -i nvidia | sed -n 's/.*\[\([0-9A-Fa-f]\+\):[0-9A-Fa-f]\+\].*/\1/p' | head -n 1)"
        
        # Create udev rules for NVIDIA power management
        echo "# Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
        ACTION==\"bind\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030000\", TEST==\"power/control\", ATTR{power/control}=\"auto\"
        ACTION==\"bind\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030200\", TEST==\"power/control\", ATTR{power/control}=\"auto\"

        # Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
        ACTION==\"unbind\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030000\", TEST==\"power/control\", ATTR{power/control}=\"on\"
        ACTION==\"unbind\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030200\", TEST==\"power/control\", ATTR{power/control}=\"on\"

        # Enable runtime PM for NVIDIA VGA/3D controller devices on adding device
        ACTION==\"add\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030000\", TEST==\"power/control\", ATTR{power/control}=\"auto\"
        ACTION==\"add\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"$NVIDIA_VENDOR\", ATTR{class}==\"0x030200\", TEST==\"power/control\", ATTR{power/control}=\"auto\"" | envsubst | sudo tee /etc/udev/rules.d/80-nvidia-pm.rules > /dev/null

        # Set NVIDIA kernel module options
        echo "options nvidia NVreg_UsePageAttributeTable=1
        options nvidia_drm modeset=1
        options nvidia NVreg_RegistryDwords="PerfLevelSrc=0x2222"
        options nvidia NVreg_EnablePCIeGen3=1 NVreg_EnableMSI=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
        
        # Apply NVIDIA settings
        sudo nvidia-xconfig --cool-bits=28
        
        # Enable and start NVIDIA persistence daemon
        sudo systemctl enable nvidia-persistenced.service
        
        # Regenerate initramfs
        sudo mkinitcpio -P
        
        # Apply udev rules immediately
        sudo udevadm control --reload-rules && sudo udevadm trigger
        ;;
esac

cd "$dotfiles_dir"

for config in background picom dunst fcitx5 ghostty mov-cli i3 polybar neofetch nvim rofi tmux; do
    rm -rf $HOME/.config/$config 
done

for config in home background picom dunst fcitx5 ghostty mov-cli i3 polybar neofetch nvim rofi tmux; do
    stow $config --adopt 
done

source .bashrc
chmod +x $HOME/.config/polybar/launch_polybar.sh
chmod +x $HOME/.config/polybar/polybar-fcitx5-script.sh
mkdir -p $HOME/Videos

# Enable power management
sudo systemctl enable tlp

# Network
echo "Installing network and internet packages..."

# Automatically determine CPU brand (AMD or Intel)
CPU_VENDOR=$(lscpu | grep "Model name" | awk '{print $3}')
echo "Detected CPU vendor: $CPU_VENDOR"

# Add relevant kernel parameters to GRUB based on the CPU vendor
GRUB_FILE="/etc/default/grub"
if [[ "$CPU_VENDOR" == "AMD" ]]; then
    echo "Configuring GRUB for AMD (amd_pstate=active and mitigations=off)..."
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 amd_pstate=active mitigations=off"/' "$GRUB_FILE"
elif [[ "$CPU_VENDOR" == "Intel" ]]; then
    echo "Configuring GRUB for Intel (intel_pstate=active and mitigations=off)..."
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 intel_pstate=active mitigations=off"/' "$GRUB_FILE"
else
    echo "Unknown CPU vendor. No specific configurations applied."
fi

#cd $HOME
#git clone --recurse-submodules https://github.com/Tk-Glitch/PKGBUILDS.git
#cd PKGBUILD/linux-tkg
#makepkg -si

# Rebuild GRUB config
sudo grub-mkconfig -o /boot/grub/grub.cfg

reboot
