#!/usr/bin/env bash

set -e

# Disk Partitioning
lsblk

read -p "Please enter EFI paritition: (example /dev/sda1 or /dev/nvme0n1p1): " EFI

read -p "Please enter Root(/) paritition: (example /dev/sda3 or /dev/nvme0n1p3): " ROOT 

read -p "Please enter your username: " USER 

read -p "Please enter your password: " PASSWORD

read -p "Please enter your password again: " TPASSWORD

while [ $TPASSWORD != $PASSWORD ]; 
do
    if [ $TPASSWORD == $PASSWORD ]; then
        echo "passwords match"
    else
        echo "passwords dont match"
        read -p "Please enter your password: " PASSWORD
    
        read -p "Please enter your password again: " TPASSWORD
done

# Make Filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.fat -F 32 $EFI
mkfs.ext4 $ROOT

# Mount Target
mount $ROOT /mnt
mkdir /mnt/boot
mount $EFI /mnt/boot/

# Installing Arch
sudo cp -rpf Misc/pacman.conf /mnt/etc
pacstrap -K /mnt amd_ucode systemd base base-devel efibootmgr sof-firmware --noconfirm --needed

# kernel
pacstrap /mnt mesa lib32-mesa vulkan-nouveau lib32-vulkan-nouveau lib32-libdrm libdrm systemd linux-lts linux-lts-headers linux-zen linux-zen-headers linux-firmware --noconfirm --needed

# Setup Dependencies

pacstrap /mnt networkmanager network-manager-applet wireless_tools amd_ucode neofetch gvfs polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-jp-fonts nano git rofi curl alacritty make obsidian man-db xdotool thuanr reflector nitrogen flameshot zip unzip mpv btop vim neovim picom wireplumber dunst xarchiver eza thunar-archive-plugin fish --noconfirm --needed

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

cd ..
sudo mv -f dotfiles /mnt

cat <<REALEND > /mnt/next.sh
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$ROOT | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

sudo mv -f dotfiles $USER && cd $USER

read -p "Which layout would you like?: " LAUT
loadkeys $LAUT

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

#DESKTOP ENVIRONMENT
pacman -S i3 --noconfirm --needed

# Packages
read -p "Do you have paru installed? " YN
if [ $YN == "no" || $YN == "n" ]; then
  git clone "https://aur.archlinux.org/paru.git"
  sudo chown $USER:$USER -R $USER
  cd paru 
  makepkg -sci
fi

paru -S vesktop-bin mercury-browser-bin

# Mirrors
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo reflector --verbose --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# My config
echo "---- Making backup at $USER/configBackup -----"
sudo cp -rpf $USER/.config $USER/configBackup 
echo "----- Backup made at $USER/configBackup ------"

sudo cp -rpf $USER/dotfiles/dunst $USER/.config
sudo cp -rpf $USER/dotfiles/alacritty $USER/.config
sudo cp -rpf $USER/dotfiles/nitrogen $USER/.config
sudo cp -rpf $USER/dotfiles/fcitx5 $USER/.config
sudo cp -rpf $USER/dotfiles/mozc $USER/.config
sudo cp -rpf $USER/dotfiles/fonts/SF-Mono-Powerline $USER/.local/share/fonts
sudo cp -rpf $USER/dotfiles/fonts/MartianMono $USER/.local/share/fonts
sudo cp -rpf $USER/dotfiles/fonts/fontconfig $USER/.config
sudo cp -rpf $USER/dotfiles/fish $USER/.config
sudo cp -rpf $USER/dotfiles/omf $USER/.config
sudo cp -rpf $USER/dotfiles/i3 $USER/.config
sudo cp -rpf $USER/dotfiles/nvim $USER/.config
sudo cp -rpf $USER/dotfiles/rofi $USER/.config
sudo cp -rpf $USER/dotfiles/Misc/picom.conf $USER/.config

if [[ -d $USER/Pictures ]]; then
    sudo rm -rf Pictures
    sudo cp -f Pictures/bgpic.jpg $USER/Pictures
else
    sudo cp -rpf Pictures $USER
fi

if [[ -d $USER/Videos ]]; then
    sudo rm -rf $USER/Videos/
else
    sudo mkdir $USER/Videos/
fi

sudo cp -rpf $USER/dotfiles/Misc/mkinitcpio.conf /etc/
sudo mkinitcpio -P

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

REALEND

arch-chroot /mnt sh next.sh
