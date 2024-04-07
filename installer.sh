#!/bin/bash

echo "This is intended to be run on an arch ISO. This will NOT work on a already installed system."

cd ~

pacman -Sy wget

# Testing internet connection.
echo "Testing your internet connection."
echo "Test One."

wget -q --spider http://google.com/

    if [ $? -eq 0 ]; then
        echo "Connected to the internet successfully."
    else
        echo "Test Two."
        wget -q --spider http://google.com

        if [ $? -eq 0 ]; then
            echo "Connected to the internet successfully."
        else

        echo "Test Three."
        wget -q --spider http://google.com

        if [ $? -eq 0 ]; then
            echo "Connected to the internet successfully."
        else
            read -p "You aren't connected to the internet. Please connect. [ENTER TO QUIT]"
            exit 1
        fi
    fi
fi

# Choosing drives to partition.

lsblk

echo "What drive do you want to install to? (e.g. /dev/sda, /dev/nvme0n1): "

read DRIVE

echo "sudo wipefs -a -f $DRIVE"
sudo wipefs -a -f $DRIVE

echo "Please do NOT make a swap partition. It will break the install."

# Partitioning drives.
read CHOICE
sudo cfdisk $DRIVE

if [ $DRIVE == "/dev/nvme0n1" ]; then 
  DRIVEr+="$DRIVE"p2
else 
  DRIVEr+="$DRIVE"2
fi
if [ $DRIVE == "/dev/nvme0n1" ]; then 
  DRIVEb+="$DRIVE"p1
else 
  DRIVEb+="$DRIVE"1
fi

# Formatting and mounting drives.
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

mv dotfiles /mnt

# Entering the new system.
echo "arch-chroot /mnt /bin/bash"

arch-chroot /mnt /bin/bash

cd ~

echo "what cpu do you have (AMD or INTEL)?: "
read CPU

# Installing CPU packages.
if [ $CPU == "AMD" ]; then
    echo sudo pacman -Syu amd-ucode zip unzip mpv cmake neofetch curl xorg xorg-drivers xorg-server xorg-apps xorg-xinit xorg-xinput nvidia-utils i3 lightdm rofi networkmanager alsa-utils pipewire pipewire-pulse pavucontrol picom polkit alacritty --noconfirm --needed >> la.sh
    sudo chmod +x la.sh
elif [ $CPU == "INTEL" ];
    sudo pacman -Syu intel-ucode zip unzip mpv cmake neofetch curl xorg xorg-drivers xorg-server xorg-apps xorg-xinit xorg-xinput nvidia-utils i3 lightdm rofi networkmanager alsa-utils pipewire pipewire-pulse pavucontrol picom polkit alacritty --noconfirm --needed >> la.sh
    sudo chmod +x la.sh
fi 

# Creating basic directory.
if [[ -d ~/Pictures ]]; then 
    echo "Pictures dir exists"
else
    sudo mkdir Pictures
fi

if [[ -d ~/Videos ]]; then 
    echo "Videos dir exists" 
else
    sudo mkdir Videos
fi

# Installing Yet Another Yoghurt package manager.
echo "sudo git clone https://aur.archlinux.org/yay-bin.git"
sudo git clone https://aur.archlinux.org/yay-bin.git 
cd yay-bin
makepkg -si

# Installing packages and moving to fish.
cd ~
yay -S man mercury-browser-bin flameshot lolcat gvfs dunst xarchiver thunar thunar-archive-plugin lxappearance eza fish bottom neovim nitrogen vesktop-bin wine fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts fcitx5-im steam
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
fish

# Configuring basic system options.
echo "What is your location in the order of the continent then city? (e.g. Europe/London, Europe/Brussels, Asia/Tokyo): "
read TZ
echo "ln -sf /usr/share/zoneinfo/$TZ /etc/localtime"

ln -sf /usr/share/zoneinfo/$TZ /etc/localtime

sudo chsh $USER -s /bin/fish

echo "date"

date

echo "Is this correct?"

read CHOICE

if [ CHOICE == "YES" ]; then
    echo 
else
    echo "hwclock --systohc"
    hwclock --systohc
fi

# Setting up users.
echo "username: "
read USERn
useradd -m -G wheel -s /bin/bash $USERn
passwd $USERn

# Installing dotfiles.
cd ~/.config 
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

# Hostname setup.
sudo mkdir /etc/hostname
echo "Choose a hostname for your machine:"
read HOSTNAME
sudo echo $HOSTNAME >> /etc/hostname

# Grub, file systems, systemctl and all that shit.
sudo mkinitcpio -P
sudo passwd
sudo echo "echo %wheel ALL=(ALL) ALL >> EDITOR=nano visudo"
sudo echo "%wheel ALL=(ALL) ALL" >> EDITOR=nano visudo
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm
sudo grub-install /dev/nvme0n1
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Bye bye, install done.
exit 
umount -a
echo "Rebooting in order for changes to take place..." 
sleep 2
sudo reboot
