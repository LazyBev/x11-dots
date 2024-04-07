#!/bin/bash

echo "This is intended to be run on an arch ISO. This will NOT work on a already installed system."

sudo cp -rp ~/dotfiles/pacman.conf /etc

cd ~

pacman -Syy wget

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

echo "Please do NOT make a swap partition. It will break the install. (ENTER to continue)"

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

echo "mount --mkdir $DRIVEb /mnt/boot/efi"
mkdir -p /mnt/boot/efi
mount $DRIVEb /mnt/boot/efi

echo "pacstrap -K /mnt base base-devel linux linux-firmware"
pacstrap -K /mnt base base-devel linux linux-headers linux-firmware grub efibootmgr sof-firmware vim neovim nitrogen

echo "genfstab -U /mnt >> /mnt/etc/fstab"
genfstab /mnt -U > /mnt/etc/fstab

# Entering the new system.
echo "arch-chroot /mnt /bin/bash"

arch-chroot /mnt /bin/bash<<"END_COMMANDS"

echo "what cpu do you have (AMD or INTEL)?: "
read CPU

# Installing CPU packages.
if [ $CPU == "AMD" ]; then
    echo sudo pacman -Syu amd-ucode zip unzip mpv cmake neofetch curl xorg xorg-drivers xorg-server xorg-apps xorg-xinit xorg-xinput nvidia-utils i3 lightdm rofi networkmanager alsa-utils pipewire pipewire-pulse pavucontrol picom polkit alacritty --noconfirm --needed
elif [ $CPU == "INTEL" ]; then
    sudo pacman -Syu intel-ucode zip unzip mpv cmake neofetch curl xorg xorg-drivers xorg-server xorg-apps xorg-xinit xorg-xinput nvidia-utils i3 lightdm rofi networkmanager alsa-utils pipewire pipewire-pulse pavucontrol picom polkit alacritty --noconfirm --needed 
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
makepkg -sci

# Installing packages and moving to fish.
cd ~
yay -S man mercury-browser-bin flameshot lolcat gvfs dunst xarchiver thunar thunar-archive-plugin lxappearance eza fish bottom vesktop-bin wine-staging fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts fcitx5-im steam
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
useradd -mG wheel,audio,video,lp,kvm -s /bin/bash $USERn
passwd $USERn

# Installing dotfiles.
cd ~/.config 
sudo cp -rp ~/dotfiles/nitrogen
sudo cp -rp ~/dotfiles/fcitx5
sudo cp -rp ~/dotfiles/fcitx
sudo cp -rp ~/dotfiles/mozc 
sudo cp -rp ~/dotfiles/fonts ~/.local/share
sudo cp -rp ~/dotfiles/omf  
sudo cp -rp ~/dotfiles/fish  
sudo cp -rp ~/dotfiles/i3  
sudo cp -rp ~/dotfiles/nvim  
sudo cp -rp ~/dotfiles/rofi  
sudo cp -rp ~/dotfiles/picom.conf 
sudo cp -rp ~/dotfiles/pacman.conf /etc
cd ~

# Hostname setup.
echo "Choose a hostname for your machine:"
read HOSTNAME
sudo echo $HOSTNAME >> /etc/hostname

# Grub, file systems, systemctl and all that shit.
sudo passwd
sudo echo "echo %wheel ALL=(ALL) ALL >> EDITOR=nano visudo"
sudo echo "%wheel ALL=(ALL) ALL" >> EDITOR=nano visudo
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo grub-install /boot $DRIVE

# bye bye
END_COMMANDS
umount -a
