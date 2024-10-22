#!/bin/bash

# Initialize variables
efi=""
root=""
user=""
pass=""
tpass=""
laut=""

disk() {
    # Partition disks
    lsblk
    read -p "Please enter EFI partition (example /dev/sda1 or /dev/nvme0n1p1): " efi
    read -p "Please enter ROOT partition (example /dev/sda2 or /dev/nvme0n1p2): " root

    # Make the filesystems and mount to targets
    echo -e "\nCreating Filesystems..."
    mkfs.fat -F 32 "$efi"
    mkfs.ext4 "$root"
    mkdir -p /mnt/boot
    mount "$efi" /mnt/boot
    mount "$root" /mnt
}

prof() {
    read -p "Please enter your username: " user

    while true; do
        read -sp "Please enter your password: " pass
        echo
        read -sp "Please enter your password again: " tpass
        echo

        if [ "$pass" == "$tpass" ]; then
            echo "Passwords match"
            break
        else
            echo "Passwords do not match, please try again"
        fi
    done
}

arch() {
    sudo cp -rpf Misc/pacman.conf /mnt/etc
    pacstrap -K /mnt amd_ucode kitty systemd base xdg-desktop-portal xdg-desktop-portal-gtk base-devel efibootmgr sof-firmware mesa lib32-mesa systemd linux-lts linux-lts-headers linux-zen linux-zen-headers linux-firmware networkmanager network-manager-applet wireless_tools neofetch gvfs pavucontrol polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts adobe-source-han-sans-kr-fonts adobe-source-han-serif-kr-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts nano steam wine git rofi curl alacritty make cmake meson obsidian man-db xdotool thuanr reflector nitrogen flameshot zip unzip mpv btop emacs noto-fonts picom wireplumber dunst xarchiver eza thunar-archive-plugin fish --noconfirm --needed
    genfstab -U /mnt >> /mnt/etc/fstab
    cd ..
    sudo mv -f dotfiles /mnt
}

chroot_system() {
    arch-chroot /mnt <<EOF
    useradd -m $user
    usermod -aG wheel,storage,power,audio $user
    echo "$user:$pass" | chpasswd
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    mv -f /dotfiles /home/$user && cd /home/$user

    echo "Which keyboard layout would you like?"
    read -r laut
    loadkeys "$laut"

    # Setup Language to US and set locale
    sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" >> /etc/locale.conf

    ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
    hwclock --systohc

    echo "gentuwu" > /etc/hostname

    # Display and Audio Drivers
    pacman -Syu xorg xorg-server pipewire-pulse pipewire --noconfirm --needed

    systemctl enable NetworkManager
    /usr/lib/xdg-desktop-portal --replace

    # Desktop environment
    pacman -S i3 --noconfirm --needed

    # Packages
    git clone "https://aur.archlinux.org/paru.git"
    chown $user:$user -R paru
    cd paru && makepkg -sci

    paru -S vesktop-bin mercury-browser-bin

    # Mirrors
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    reflector --verbose --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

    # My config
    ./UpdateConfig.sh

    mkinitcpio -P

    git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
    ~/.config/emacs/bin/doom install
    ~/.config/emacs/bin/doom sync

    curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
EOF
}

main() {
    disk
    prof
    arch
    chroot_system
}

main
