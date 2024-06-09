#!/usr/bin/env bash

set -e

echo "Please enter EFI paritition: (example /dev/sda1 or /dev/nvme0n1p1): "
read EFI

echo "Please enter Root(/) paritition: (example /dev/sda3): "
read ROOT 

echo "Please enter your username: "
read USER 

echo "Please enter your password: "
read PASSWORD

echo "Please enter your password again: "
read PASSWORD 

# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 -n "EFISYSTEM" "${EFI}"
mkfs.ext4 -L "ROOT" "${ROOT}"

# mount target
mount -t ext4 "${ROOT}" /mnt
mkdir /mnt/boot
mount -t vfat "${EFI}" /mnt/boot/

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux BASE on Main Drive       --"
echo "--------------------------------------"
pacstrap -K /mnt amd_ucode base base-devel efibootmgr sof-firmware --noconfirm --needed

# kernel
pacstrap /mnt mesa lib32-mesa vulkan-nouveau lib32-vulkan-nouveau lib32-libdrm libdrm linux-lts linux-lts-headers linux-zen linux-zen-headers linux-firmware grub
 --noconfirm --needed

echo "--------------------------------------"
echo "-- Setup Dependencies               --"
echo "--------------------------------------"

pacstrap /mnt networkmanager network-manager-applet wireless_tools amd_ucode nano git curl --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

cat <<REALEND > /mnt/next.sh
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "Setup Language to US and set locale"
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

echo "gentuwu" > /etc/hostname

echo "-------------------------------------------------"
echo "Display and Audio Drivers"
echo "-------------------------------------------------"

pacman -S xorg xorg-server pipewire-pulse pipewire --noconfirm --needed

systemctl enable NetworkManager

#DESKTOP ENVIRONMENT
pacman -S i3 --noconfirm --needed

echo "-------------------------------------------------"
echo "Packages"
echo "-------------------------------------------------"

read -p "Do you have paru installed? " YN
if [ $YN == "no" ]; then
  cd ~
  git clone "https://aur.archlinux.org/paru.git"
  sudo chown $USER:$USER -R ~
  cd paru 
  makepkg -sci
  cd ~/dotfiles
fi

paru -S alacritty reflector rofi curl nitrogen flameshot zip unzip mpv btop vim neovim picom wireplumber dunst xarchiver eza thunar thunar-archive-plugin fish make obsidian man-db xdotool vesktop-bin mercury-browser-bin neofetch gvfs polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-jp-fonts

sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo reflector --verbose --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

echo "-------------------------------------------------"
echo "My config"
echo "-------------------------------------------------"

echo "---- Making backup at ~/configBackup -----"
sudo cp -rpf ~/.config ~/configBackup 
echo "----- Backup made at ~/configBackup ------"

sudo cp -rpf ~/dotfiles/tmux ~/.config
sudo cp -rpf ~/dotfiles/dunst ~/.config
sudo cp -rpf ~/dotfiles/alacritty ~/.config
sudo cp -rpf ~/dotfiles/nitrogen ~/.config
sudo cp -rpf ~/dotfiles/fcitx5 ~/.config
sudo cp -rpf ~/dotfiles/mozc ~/.config
sudo cp -rpf ~/dotfiles/fonts/SF-Mono-Powerline ~/.local/share/fonts
sudo cp -rpf ~/dotfiles/fonts/MartianMono ~/.local/share/fonts
sudo cp -rpf ~/dotfiles/fonts/fontconfig ~/.config
sudo cp -rpf ~/dotfiles/fish ~/.config
sudo cp -rpf ~/dotfiles/omf ~/.config
sudo cp -rpf ~/dotfiles/i3 ~/.config
sudo cp -rpf ~/dotfiles/nvim ~/.config
sudo cp -rpf ~/dotfiles/rofi ~/.config
sudo cp -rpf ~/dotfiles/Misc/picom.conf ~/.config
sudo cp -rpf ~/dotfiles/Misc/pacman.conf /etc

if [[ -d ~/Pictures ]]; then
    sudo cp -f Pictures/bgpic.jpg ~/Pictures
else
    sudo cp -rpf Pictures ~
fi

if [[ -d ~/Videos ]]; then
    echo "Videos dir exists"
else
    sudo cp -rpf Videos ~
    sudo rm -rf ~/Videos/
fi

echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"

REALEND


arch-chroot /mnt sh next.sh
