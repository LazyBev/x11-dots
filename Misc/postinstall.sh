sudo mkdir ~/.local/share/fonts && sudo mkdir Pictures && sudo mkdir Videos && sudo setxkbmap -layout gb && sudo pacman -Syu && sudo git clone https://aur.archlinux.org/paru.git && cd ~/paru && sudo makepkg -si && cd ~ && paru -S man i3 mercury-browser-bin picom zip unzip cowsay ponysay neofetch fcitx5-im fcitx5-mozc lolcat polkit gvfs alsa-utils pipewire pipewire-pulse pavucontrol dunst xarchiver thunar thunar-archive-plugin lxappearance gnome-extra eza rofi fish btop neovim alacritty && sudo git clone https://github.com/LazyBev/dotfiles.git && cd ~/.config && sudo rm -rf i3 && sudo rm -rf fish && sudo rm -rf nvim && sudo rm -rf /etc/pacman.conf && sudo rm -rf /etc/xdg/picom.conf && sudo rm -rf omf && sudo ln -s ~/dotfiles/omf && sudo ln -s ~/dotfiles/fish && sudo ln -s ~/dotfiles/i3 && sudo ln -s ~/dotfiles/nvim && sudo ln -s ~/dotfiles/rofi && sudo ln -s ~/dotfiles/Misc/pacman.conf /etc/pacman.conf && sudo ln -s ~/dotfiles/Misc/picom.conf /etc/xdg/picom.conf && sudo fish && sudo chsh $USER -s /bin/fish && gitdot && clear && cd ~ && read -p "Press enter in order for changes to take place..." && sudo reboot
