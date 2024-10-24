#!/bin/bash

set -e

main() {
    user=$(whoami)

    # Packages
    git clone "https://aur.archlinux.org/paru.git"
    chown "$user:$user" -R paru
    cd paru && makepkg -sci

    paru -S firefox nmap wireshark-qt john hydra aircrack-ng sqlmap hashcat nikto openbsd-netcat metasploit amd_ucode kitty systemd base xdg-desktop-portal xdg-desktop-portal-gtk base-devel efibootmgr sof-firmware mesa lib32-mesa xf86-video-nouveau vulkan-mesa-layers lib32-vulkan-mesa-layers nvidia-prime nvidia-lts nvidia-utils systemd linux-lts linux-lts-headers linux-zen linux-zen-headers linux-firmware networkmanager network-manager-applet wireless_tools neofetch gvfs pavucontrol polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts adobe-source-han-sans-kr-fonts adobe-source-han-serif-kr-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts nano steam wine git rofi curl alacritty make cmake meson obsidian man-db xdotool thuanr reflector nitrogen flameshot zip unzip mpv btop emacs noto-fonts picom wireplumber dunst xarchiver eza thunar-archive-plugin fish

    # Mirrors
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    reflector --verbose --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

    # My config
    echo "---- Making backup at $HOME/configBackup -----"
    sudo cp -rpf "$HOME/.config" "$HOME/configBackup"
    echo "----- Backup made at $HOME/configBackup ------"

    # Copy configurations
    for config in .emacs.d neofetch/bk dunst Pictures/bgpic.jpg fcitx5 mozc fonts/fontconfig fonts/MartianMono fonts/SF-Mono-Powerline fish i3 nvim rofi omf Misc/picom.conf; do
        sudo cp -rpf "$HOME/dotfiles/$config" "$HOME/.config"
    done

    sudo cp -rpf "$HOME/dotfiles/$dir" "$HOME/.local/share/fonts"
    sudo cp -rpf "$HOME/dotfiles/Misc/pacman.conf" /etc

    mkinitcpio -P

    # Nvidia GPU setup
    xrandr --listproviders && glxinfo | grep "OpenGL renderer"
    xrandr --setprovideroffloadsink 1 && xrandr --setprovideroffloadsink radeon

    DRI_PRIME=1 glxinfo | grep "OpenGL renderer"
    cat /sys/class/drm/card*/device/power_state

    cd /etc/udev/rules.d
    sudo tee 80-nvidia-pm.rules > /dev/null <<EOL
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
EOL

    cd /etc/modprobe.d
    sudo tee nvidia-pm.conf > /dev/null <<EOL
options nvidia NVreg_DynamicPowerManagement=0x02
EOL

    cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
    cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_suspended_time

    sudo systemctl start nvidia-persistenced.service
    sudo systemctl enable nvidia-persistenced.service

    git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
    ~/.config/emacs/bin/doom install
    ~/.config/emacs/bin/doom sync

    curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
}

main
