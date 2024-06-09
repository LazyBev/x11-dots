#!/bin/bash 

set -e

read -p "Do you have paru installed? " YN
if [ $YN == "no" ]; then
  git clone "https://aur.archlinux.org/paru.git"
  sudo chown $USER:$USER -R ~
  cd paru 
  makepkg -sci
fi

paru -S amd-ucode alacritty reflector rofi curl nitrogen flameshot zip unzip mpv btop vim neovim picom wireplumber dunst xarchiver eza thunar thunar-archive-plugin fish make obsidian man-db xdotool vesktop-bin mercury-browser-bin neofetch gvfs polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-jp-fonts

echo "---- Making backup at ~/configBackup -----"
sudo cp -rpf ~/.config ~/configBackup 
echo "----- Backup made at ~/configBackup ------"

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

paru -S base base-devel efibootmgr sof-firmware amd_ucode mesa lib32-mesa vulkan-nouveau lib32-vulkan-nouveau lib32-libdrm libdrm linux-lts linux-lts-headers linux-zen linux-zen-headers linux-firmware grub

sudo cp -rpf ~/dotfiles/Misc/mkinitcpio.conf /etc/
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
reboot
