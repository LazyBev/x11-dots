#!/bin/bash
set -eo pipefail

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Variables
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
dotfiles_dir="$HOME/dotfiles"

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
yay -Sy xorg xorg-server xorg-xinit

# Desktop Enviroment
echo "Installing i3..."
yay -Sy i3 ly dmenu ranger

# Ghostty Term
echo "Installing ghostty..."
yay -Sy ghostty

# Installing PipeWire services
echo "Installing PipeWire and related packages..."
yay -Sy pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils pavucontrol
        
# Configure ALSA to use PipeWire
echo "Configuring ALSA to use PipeWire..."
echo tee /etc/asound.conf <<ASOUND
defaults.pcm.card 0
defaults.ctl.card 0
ASOUND

# Browser
echo "Installing firefox..."
yay -Sy firefox

# Text Editor
yay -Sy neovim vim
git clone https://github.com/NvChad/starter ~/.config/nvim && nvim

rm -rf ~/.config/nvim
yay -Sy lua
cd "$dotfiles_dir/Scripts" && git clone https://luajit.org/git/luajit.git
cd luajit && make && sudo make install
cd .. && rm -rf luajit 
git clone https://github.com/LazyVim/LazyVim.git ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Wine
echo "Installing Wine..."
yay -Sy wine winetricks

# Roblox
echo "Installing Roblox..."
yay -Sy flatpak
flatpak install --user https://sober.vinegarhq.org/sober.flatpakref
if ! grep -q "alias roblox=" $HOME/.bashrc; then
    echo "Adding Roblox alias to .bashrc..."
    echo "alias roblox='flatpak run org.vinegarhq.Sober'" >> $HOME/.bashrc
else
    echo "Roblox alias already exists in .bashrc. Skipping addition."
fi

# Discord
echo "Installing Roblox..."
flatpak install --user com.discordapp.Discord
if ! grep -q "alias discord=" $HOME/.bashrc; then
    echo "Adding Discord alias to .bashrc..."
    echo "alias discord='flatpak run com.discordapp.Discord'" >> $HOME/.bashrc
else
    echo "Discord alias already exists in .bashrc. Skipping addition."
fi
touch discord
DC="$HOME/discord"
sudo echo 'flatpak run com.discordapp.Discord' >> $DC
sudo mv $DC /bin

# Steam
echo "Installing Steam..."
yay -Sy steam steam-native-runtime

# Bluetooth
echo "Installing Bluetooth..."
yay -Sy blueman bluez bluez-utils
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
        
        # Append NVIDIA environment variables to .bashrc if they aren't already set
        grep -qxF 'export __GL_THREADED_OPTIMIZATIONS=1' $HOME/.bashrc || echo 'export __GL_THREADED_OPTIMIZATIONS=1' >> $HOME/.bashrc
        grep -qxF 'export __GL_SYNC_TO_VBLANK=0' $HOME/.bashrc || echo 'export __GL_SYNC_TO_VBLANK=0' >> $HOME/.bashrc
        grep -qxF 'export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json' $HOME/.bashrc || echo 'export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json' >> $HOME/.bashrc
        grep -qxF 'export VK_LAYER_PATH=/usr/share/vulkan/explicit_layer.d' $HOME/.bashrc || echo 'export VK_LAYER_PATH=/usr/share/vulkan/explicit_layer.d' >> $HOME/.bashrc
        
        # Configure NVIDIA power settings
        sudo nvidia-smi -pm 1
        
        # Set NVIDIA kernel module options
        echo "options nvidia NVreg_UsePageAttributeTable=1
        options nvidia_drm modeset=1
        options nvidia NVreg_RegistryDwords="PerfLevelSrc=0x2222"
        options nvidia NVreg_EnablePCIeGen3=1 NVreg_EnableMSI=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
        
        # Apply NVIDIA settings
        sudo nvidia-xconfig --cool-bits=28
        sudo nvidia-smi -i 0 -pm 1
        
        # Prompt user for power limit
        read -p "Enter desired power limit (in watts): " WATTS
        if [[ $WATTS =~ ^[0-9]+$ ]]; then
            sudo nvidia-smi -i 0 -pl $WATTS
        else
            echo "Invalid input. Skipping power limit configuration."
        fi
        
        # Disable auto-boost and set clock speeds
        sudo nvidia-smi --auto-boost-default=0
        sudo nvidia-smi -i 0 -ac 5001,2000
        
        # Enable and start NVIDIA persistence daemon
        sudo systemctl enable nvidia-persistenced.service
        sudo systemctl start nvidia-persistenced.service
        
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
        
        # Append NVIDIA environment variables to .bashrc if they aren't already set
        grep -qxF 'export __GL_THREADED_OPTIMIZATIONS=1' $HOME/.bashrc || echo 'export __GL_THREADED_OPTIMIZATIONS=1' >> $HOME/.bashrc
        grep -qxF 'export __GL_SYNC_TO_VBLANK=0' $HOME/.bashrc || echo 'export __GL_SYNC_TO_VBLANK=0' >> $HOME/.bashrc
        grep -qxF 'export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json' $HOME/.bashrc || echo 'export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json' >> $HOME/.bashrc
        grep -qxF 'export VK_LAYER_PATH=/usr/share/vulkan/explicit_layer.d' $HOME/.bashrc || echo 'export VK_LAYER_PATH=/usr/share/vulkan/explicit_layer.d' >> $HOME/.bashrc
        
        # Configure NVIDIA power settings
        sudo nvidia-smi -pm 1
        
        # Set NVIDIA kernel module options
        echo "options nvidia NVreg_UsePageAttributeTable=1
        options nvidia_drm modeset=1
        options nvidia NVreg_RegistryDwords="PerfLevelSrc=0x2222"
        options nvidia NVreg_EnablePCIeGen3=1 NVreg_EnableMSI=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
        
        # Apply NVIDIA settings
        sudo nvidia-xconfig --cool-bits=28
        sudo nvidia-smi -i 0 -pm 1
        
        # Prompt user for power limit
        read -p "Enter desired power limit (in watts): " WATTS
        if [[ $WATTS =~ ^[0-9]+$ ]]; then
            sudo nvidia-smi -i 0 -pl $WATTS
        else
            echo "Invalid input. Skipping power limit configuration."
        fi
        
        # Disable auto-boost and set clock speeds
        sudo nvidia-smi --auto-boost-default=0
        sudo nvidia-smi -i 0 -ac 5001,2000
        
        # Enable and start NVIDIA persistence daemon
        sudo systemctl enable nvidia-persistenced.service
        sudo systemctl start nvidia-persistenced.service
        
        # Regenerate initramfs
        sudo mkinitcpio -P
        
        # Apply udev rules immediately
        sudo udevadm control --reload-rules && sudo udevadm trigger
        ;;
esac

# Tmux
yay -Sy tmux

# Utilities
echo "Installing utilities..."
yay -Sy acpi git lazygit github-cli polybar xdg-desktop-portal hwinfo thunar arch-install-scripts wireless_tools neofetch fuse2 polkit fcitx5-im fcitx5-chinese-addons fcitx5-anthy rofi curl make cmake meson obsidian man-db man-pages xdotool nitrogen flameshot zip unzip mpv btop noto-fonts picom dunst xarchiver eza fzf

# Fonts
echo "Installing fonts..."
yay -Sy ttf-dejavu ttf-liberation unifont ttf-joypixels ttf-meslo-nerd fcitx5-hangul adobe-source-han-mono-jp-fonts adobe-source-han-mono-hk-fonts adobe-source-han-mono-kr-fonts adobe-source-han-mono-tw-fonts adobe-source-han-mono-otc-fonts adobe-source-han-mono-cn-fonts

# Backup configurations
backup_dir="$HOME/configBackup_$(date +%Y%m%d_%H%M%S)"
echo "---- Making backup at $backup_dir -----"
mkdir -p "$backup_dir"
sudo cp -rpf "$HOME/.config" "$backup_dir"
echo "----- Backup made at $backup_dir ------"

cd "$dotfiles_dir"
yay -Sy stow
# Copy configurations from dotfiles (example for dunst, rofi, etc.)
for config in dunst fcitx5 tmux i3 neofetch rofi ghostty; do
    stow $config
done

# XDG_DIRS
grep -qxF 'export XDG_CONFIG_HOME="$HOME/.config"' $HOME/.bashrc || echo 'export XDG_CONFIG_HOME="$HOME/.config"' >> $HOME/.bashrc
grep -qxF 'export XDG_DATA_HOME="$HOME/.local/share"' $HOME/.bashrc || echo 'export XDG_DATA_HOME="$HOME/.local/share"' >> $HOME/.bashrc
grep -qxF 'export XDG_STATE_HOME="$HOME/.local/state"' $HOME/.bashrc || echo 'export XDG_STATE_HOME="$HOME/.local/state"' >> $HOME/.bashrc
grep -qxF 'export XDG_CACHE_HOME="$HOME/.cache"' $HOME/.bashrc || echo 'export XDG_CACHE_HOME="$HOME/.cache"' >> $HOME/.bashrc
grep -qxF 'export PATH=".local/bin/:$PATH"' $HOME/.bashrc || echo 'export PATH=".local/bin/:$PATH"' >> $HOME/.bashrc

mkdir -p "$HOME/.config/neofetch/" && cp -rf "$dotfiles_dir/neofetch/bk" "$HOME/.config/neofetch/"
echo "alias neofetch='neofetch --source $HOME/.config/neofetch/bk'" >> $HOME/.bashrc
wget https://brainwreckedtech.wordpress.com/wp-content/uploads/2014/03/ika-musume-arch-linux-169.png --directory-prefix=Pictures
mkdir -p "$HOME/Videos/"

# Enable power management
echo "Enabling power management..."
yay -Sy tlp
sudo systemctl enable tlp

# Network
echo "Installing network and internet packages..."
yay -Sy iwd

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
    yay -Sy "${Apackages[@]}"
else
    echo "No additional packages will be installed."
fi

BASH_PROFILE="$HOME/.bash_profile"
if ! grep -q "startx" "$BASH_PROFILE"; then
    echo "Setting up startx auto-launch..."
    echo 'if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then exec startx; fi' >> "$BASH_PROFILE"
fi

# Configure i3 as default X session
XINITRC="$HOME/.xinitrc"
if [ ! -f "$XINITRC" ]; then
    echo "Setting i3 as the default X session..."
    sudo echo 'exec i3' > "$XINITRC"
    sudo chmod +x "$XINITRC"
elif ! grep -q "exec i3" "$XINITRC"; then
    sudo echo "Adding exec i3 to existing .xinitrc..."
    sudo echo 'exec i3' >> "$XINITRC"
fi

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
