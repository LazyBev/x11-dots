#!/bin/bash

echo "Arch Install, if you do not wish to continue type NO. else YES: "
read CHOICE
if [ CHOICE == "YES" ] then
  clear
else 
  exit 1
fi
cd ~
sudo pacman -Sy wget
echo "Checking internet connection..."
echo "Test one"
wget -q --spider http://google.com
if [ $? -eq 0 ]; then
    echo "Internet is connected"
else
    echo "Test two"
    wget -q --spider http://google.com
    if [ $? -eq 0 ]; then
        echo "Internet is connected"
    else
        echo "Test three"
        wget -q --spider http://google.com
        if [ $? -eq 0 ]; then
            echo "Internet is connected"
        else
            read -p "Please connect to the internet... (ENTER to quit)"
            exit 1
        fi
    fi
fi
echo "Enter in path to the drive do you wanna alter? (e.g. /dev/sda, /dev/nvme0n1): "
read DRIVE
echo "sudo wipefs -a -f $DRIVE"
sudo wipefs -a -f $DRIVE
echo "Dont make swap, it will break the install..."
read CHOICE
sudo cfdisk $DRIVE
if [ $DRIVE == "/dev/nvme0n1" ] then 
  DRIVEr+="$DRIVE"p2
else 
  DRIVEr+="$DRIVE"2
fi
if [ $DRIVE == "/dev/nvme0n1" ] then 
  DRIVEb+="$DRIVE"p1
else 
  DRIVEb+="$DRIVE"1
fi
echo "mkfs.ext4 $DRIVEr"
mkfs.ext4 $DRIVEr
echo "mkfs.fat -F 32 $DRIVEb"
mkfs.fat -F 32 $DRIVEb
echo "mount $DRIVEr /mnt"
mount $DRIVEr /mnt
echo "mount --mkdir $DRIVEb /mnt/boot"
mount --mkdir $DRIVEb /mnt/boot
echo "pacstrap -K /mnt base base-devel linux linux-firmware"
pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr sof-firmware vim
echo "genfstab -U /mnt >> /mnt/etc/fstab"
genfstab /mnt > /mnt/etc/fstab
echo "arch-chroot /mnt /bin/bash"
arch-chroot /mnt /bin/bash
cd ~
echo "what cpu do you have (AMD or INTEL)?: "
read CPU
echo "touch la.sh"
touch la.sh
if [ $CPU == "AMD" ] then
  sudo pacman -Syu amd-ucode zip unzip mpv cmake neofetch curl xorg xorg-drivers xorg-server xorg-apps xorg-xinit xorg-xinput nvidia-utils i3 lightdm rofi networkmanager alsa-utils pipewire pipewire-pulse pavucontrol picom polkit alacritty --noconfirm --needed
elif [ $CPU == "INTEL" ]
  sudo pacman -Syu intel-ucode zip unzip mpv cmake neofetch curl xorg xorg-drivers xorg-server xorg-apps xorg-xinit xorg-xinput nvidia-utils i3 lightdm rofi networkmanager alsa-utils pipewire pipewire-pulse pavucontrol picom polkit alacritty --noconfirm --needed
fi 
if [[ -d ~/Pictures ]] then 
  echo "Pictures dir exists"
else
  sudo mkdir Pictures
fi
if [[ -d ~/Videos ]] then 
  echo "Videos dir exists" 
else
  sudo mkdir Videos
fi
echo "sudo git clone https://aur.archlinux.org/yay-bin.git"
sudo git clone https://aur.archlinux.org/yay-bin.git 
cd ~/yay-bin
makepkg -si 
cd ~
yay -S man mercury-browser-bin flameshot lolcat gvfs dunst xarchiver thunar thunar-archive-plugin lxappearance eza fish bottom neovim nitrogen
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
fish
sudo chsh $USER -s /bin/fish
exit
cd /mnt/.config 
sudo ln -sf ~/dotfiles/nitrogen
sudo ln -sf ~/dotfiles/fcitx5
sudo ln -sf ~/dotfiles/fcitx
sudo ln -sf ~/dotfiles/mozc 
sudo ln -sf ~/dotfiles/fonts ~/.local/share
sudo ln -sf ~/dotfiles/omf  
sudo ln -sf ~/dotfiles/fish  
sudo ln -sf ~/dotfiles/i3  
sudo ln -sf ~/dotfiles/nvim  
sudo ln -sf ~/dotfiles/rofi  
sudo ln -sf ~/dotfiles/pacman.conf /etc
sudo ln -sf ~/dotfiles/picom.conf /etc/xdg  
cd ~
sudo mkdir /etc/hostname
echo "Choose a hostname:"
read HOSTNAME
echo $HOSTNAME >> sudo /etc/hostname
mkinitcpio -P
passwd
gitdot
"Rebooting in order for changes to take place..." 
sleep 2
sudo reboot
