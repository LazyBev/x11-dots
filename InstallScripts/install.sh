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
wget -q --spider http://google.com
wget -q --spider http://google.com
if [ $? -eq 0 ]; then
    echo "Internet is connected"
else
    read -p "Please connect to the internet... (ENTER to quit)"
    exit 1
fi
echo "what drive do you wanna alter? (e.g. /dev/sda, /dev/nvme0n1): "
read DRIVE
sudo wipefs -a -f $DRIVE
sudo fdisk $DRIVE
g
n
1
echo
+1G
t
1
n
2
echo
echo
wq
------- NOT FINISHED --------------

echo "pacstrap -K /mnt base base-devel linux linux-firmware"
pacstrap -K /mnt base base-devel linux linux-firmware

sudo pacman -S linux gcc zip unzip mpv cmake glibc neofetch vim curl xorg xorg-drivers xorg-server xorg-apps xorg-xinit xorg-xinput nvidia-utils i3 lightdm rofi networkmanager alsa-utils pipewire pipewire-pulse pavucontrol picom polkit alacritty --noconfirm --needed
if [ -d ~/Pictures]; then
  echo "Pictures dir exists"
else
  sudo mkdir Pictures
fi
if [ -d ~/Videos]; then
  echo "Videos dir exists"
else
  sudo mkdir Videos
fi
sudo pacman -Syu 
sudo git clone https://aur.archlinux.org/yay-bin.git 
cd ~/yay-bin
makepkg -si 
cd ~ 
yay -S man mercury-browser-bin flameshot lolcat gvfs dunst xarchiver thunar thunar-archive-plugin lxappearance eza fish bottom neovim nitrogen
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
fish
sudo chsh $USER -s /bin/fish
cd ~/.config 
sudo rm -rf i3 
sudo rm -rf rofi
sudo rm -rf mozc
sudo rm -rf fish 
sudo rm -rf nvim 
sudo rm -rf fcitx
sudo rm -rf fcitx5
sudo rm -rf /etc/pacman.conf 
sudo rm -rf /etc/xdg/picom.conf 
sudo rm -rf ~/.local/share/fonts
sudo rm -rf omf 
sudo rm -rf nitrogen
sudo ln -s ~/dotfiles/nitrogen
sudo ln -s ~/dotfiles/fcitx5
sudo ln -s ~/dotfiles/fcitx
sudo ln -s ~/dotfiles/mozc 
sudo ln -s ~/dotfiles/fonts ~/.local/share
sudo ln -s ~/dotfiles/omf  
sudo ln -s ~/dotfiles/fish  
sudo ln -s ~/dotfiles/i3  
sudo ln -s ~/dotfiles/nvim  
sudo ln -s ~/dotfiles/rofi  
sudo ln -s ~/dotfiles/pacman.conf /etc
sudo ln -s ~/dotfiles/picom.conf /etc/xdg  
cd ~  
gitdot
"Rebooting in order for changes to take place..." 
sleep 2
sudo reboot
