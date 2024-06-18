#!/bin/bash 

set -e

echo "Do you have paru installed? " 
read YN
if [ $YN == "no" ]; then
  git clone "https://aur.archlinux.org/paru.git"
  sudo chown $USER:$USER -R $HOME
  cd paru 
  makepkg -sci
fi

paru -S amd-ucode kitty reflector rofi curl nitrogen pavucontrol flameshot zip unzip mpv btop vim neovim picom wireplumber dunst xarchiver eza thunar thunar-archive-plugin fish make obsidian man-db xdotool vesktop-bin mercury-browser-bin neofetch gvfs polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-jp-fonts

echo "---- Making backup at $HOME/configBackup -----"
sudo cp -rpf $HOME/.config $HOME/configBackup 
echo "----- Backup made at $HOME/configBackup ------"

sudo cp -rpf $HOME/dotfiles/dunst $HOME/.config
sudo cp -rpf $HOME/dotfiles/alacritty $HOME/.config
sudo cp -rpf $HOME/dotfiles/nitrogen $HOME/.config
sudo cp -rpf $HOME/dotfiles/fcitx5 $HOME/.config
sudo cp -rpf $HOME/dotfiles/mozc $HOME/.config
sudo cp -rpf $HOME/dotfiles/fonts/SF-Mono-Powerline $HOME/.local/share/fonts
sudo cp -rpf $HOME/dotfiles/fonts/MartianMono $HOME/.local/share/fonts
sudo cp -rpf $HOME/dotfiles/fonts/fontconfig $HOME/.config
sudo cp -rpf $HOME/dotfiles/fish $HOME/.config
sudo cp -rpf $HOME/dotfiles/omf $HOME/.config
sudo cp -rpf $HOME/dotfiles/i3 $HOME/.config
sudo cp -rpf $HOME/dotfiles/nvim $HOME/.config
sudo cp -rpf $HOME/dotfiles/rofi $HOME/.config
sudo cp -rpf $HOME/dotfiles/Misc/picom.conf $HOME/.config
sudo cp -rpf $HOME/dotfiles/Misc/pacman.conf /etc

sudo mv -f $HOME/dotfiles/Pictures $HOME
sudo mv -f $HOME/dotfiles/Videos $HOME

sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo reflector --verbose --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

paru -S base base-devel efibootmgr sof-firmware mesa lib32-mesa linux-lts linux-lts-headers linux-zen linux-zen-headers linux-firmware

sudo cp -rpf $HOME/dotfiles/Misc/mkinitcpio.conf /etc/
sudo mkinitcpio -P

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
