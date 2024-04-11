#!/bin/bash

set -e

echo "This is intended to be run on an (fresh???) arch ISO and must be UEFI mode. This will NOT work on a already installed system. Must have some knowledge on disk partioning"
read -p "Lets choose a keyboard layout. Read the list and check which one you want (ENTER to contnue.)" && localectl list-keymaps
clear

read -p "Which layout would you like?: " LAUT
echo "loadkeys $LAUT" && loadkeys $LAUT
cp -rp pacman.conf /etc

cd ~
pacman -Syy wget reflector --noconfirm 

# Testing internet connection.
echo "Testing your internet connection."
echo "Test One."

for i in "One" "Two" "Three"; do
    echo "Test $i."
    if wget -q --spider https://google.com; then
        break
    else
        read -p "You aren't connected"
        exit 1
    fi
done

echo "Connected successfully."

# Choosing drives to partition.

lsblk
echo "This is for gpt type partions... (quit now if this is not for you)"
read -p "What drive do you want to install to? (e.g. /dev/sda, /dev/nvme0n1): " DRIVE

# Partitioning drives.

sudo wipefs -a -f $DRIVE
sudo cfdisk $DRIVE

if [ $DRIVE == "/dev/nvme0n1" ]; then
    DRIVEb+="$DRIVE"p1
    DRIVEr+="$DRIVE"p2
else
    DRIVEb+="$DRIVE"1
    DRIVEr+="$DRIVE"2
fi

# Formatting and mounting drives.
echo "mkfs.ext4 $DRIVEr" && mkfs.ext4 $DRIVEr

echo "mkfs.fat -F 32 $DRIVEb" && mkfs.fat -F 32 $DRIVEb

echo "mount $DRIVEr /mnt" && mount $DRIVEr /mnt
echo "mount -m $DRIVEb /mnt/boot/efi" && mount -m $DRIVEb /mnt/boot/efi

cd dotfiles 
cp -rp reflector.conf /etc/xdg/reflector
systemctl enable reflector.serivce
systemctl start reflector.service

cd ~
echo "pacstrap -K /mnt base base-devel linux linux-firmware" && pacstrap -K /mnt base linux-zen linux-firmware grub efibootmgr sof-firmware --noconfirm --needed

echo "genfstab -U /mnt >> /mnt/etc/fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# Creating basic directory.
cd dotfiles
if [[ -d ~/mnt/Pictures ]]; then
    echo "Pictures dir exists"
else
    cp -r Pictures /mnt
fi

if [[ -d ~/mnt/Videos ]]; then
    echo "Videos dir exists" 
else
    cp -r Videos /mnt
fi

cd /
read -p "which country do you reside in? (capital letter for first letter): " COUN
echo "echo $COUN >> etc/xdg/reflector/reflector.conf" && echo $COUN >> etc/xdg/reflector/reflector.conf

# Entering the new system.
echo "arch-chroot /mnt /bin/bash"

arch-chroot /mnt<<"END_COMMANDS"

# Installing CPU packages.
read -p "what cpu do you have (AMD or INTEL)?: " CPU
if [ $CPU == "AMD" ]; then
    sudo pacman -Syu amd-ucode zip unzip mpv cmake vim neovim nitrogen picom neofetch curl xorg xorg-drivers xorg-server xorg-apps xorg-xinit xorg-xinput nvidia-utils i3 lightdm lightdm-gtk-greeter rofi networkmanager alsa-utils pipewire pipewire-pulse wireplumber picom polkit alacritty --noconfirm --needed
elif [ $CPU == "INTEL" ]; then
    sudo pacman -Syu intel-ucode zip unzip mpv cmake neofetch curl xorg xorg-drivers xorg-server xorg-apps xorg-xinit xorg-xinput nvidia-utils i3 lightdm lightdm-gtk-greeter rofi networkmanager alsa-utils pipewire pipewire-pulse wireplumber picom polkit alacritty --noconfirm --needed 
fi

# Configuring basic system options.
read -p "What is your location in the order of the continent then city? (e.g. Europe/London, Europe/Brussels, Asia/Tokyo): " TZ
echo "ln -sf /usr/share/zoneinfo/$TZ /etc/localtime"
ln -sf /usr/share/zoneinfo/$TZ /etc/localtime

echo "date"
date

read -p "Is this correct?" CHOICE
if [ CHOICE == "YES" ]; then
    echo "Yippe"
else
    timedatectl set-timezone $TZ
fi

# Setting up users.
read -p "username: " USERn
useradd -mG wheel,audio,video,lp,kvm -s /bin/bash $USERn
passwd $USERn
echo "sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers"
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Installing dotfiles.
cd ~/dotfiles
sudo cp -rp 
sudo cp -rp fcitx5 ../.config
sudo cp -rp mozc ../.config
sudo cp -rp fonts ~/.local/share
sudo cp -rp omf ../.config
sudo cp -rp fish ../.config
sudo cp -rp i3 ../.config
sudo cp -rp nvim ../.config
sudo cp -rp rofi ../.config
sudo cp -rp picom.conf ../.config
sudo cp -rp pacman.conf /etc
cd ~

su $USERn
# This is a custom command in my fish config 
tofish

# Installing Yet Another Yoghurt package manager.
echo "sudo git clone https://aur.archlinux.org/yay-bin.git"
sudo git clone https://aur.archlinux.org/yay-bin.git 
cd yay-bin
makepkg -sci

# Hostname setup.
read -p "Choose a hostname for your machine:" HOSTNAME
sudo echo $HOSTNAME >> /etc/hostname

# Grub, file systems, systemctl and all that shit.
sudo passwd
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm
systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
systemctl --user enable wireplumber
sudo grub-install /boot/efi $DRIVE
sudo grub-mkconfig -o /boot/grub/grub.cfg

# bye bye
END_COMMANDS
umount -R /mnt
echo "Reboot please, or if you would like to tinker with new installation before using it run ,,arch-chroot /mnt,,"
