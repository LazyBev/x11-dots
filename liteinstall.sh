echo "Are you using yay?"
read YN
if [ YN == "no" ]; then
    cd ~
    sudo git clone https://aur.archlinux.org/yay-bin.git 
    cd yay-bin
    makepkg -sci
    cd ~
fi
yay -S man curl wget vim neovim nitrogen mercury-browser-bin flameshot zip unzip mpv cmake alacritty picom wireplumber lolcat gvfs dunst xarchiver thunar thunar-archive-plugin lxappearance eza fish bottom vesktop-bin wine-staging fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts fcitx5-im steam
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
cd ~/.config 
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
sudo cp -rp ~/dotfiles/neofetch 
sudo cp -rp ~/dotfiles/pacman.conf /etc
cd ~
