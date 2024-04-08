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
chsh $USER -s /bin/fish
cd ~/dotfiles
sudo cp -rp fcitx5 ../.config
sudo cp -rp fcitx ../.config
sudo cp -rp mozc ../.config
sudo cp -rp fonts ~/.local/share
sudo cp -rp fish ../.config
sudo cp -rp i3 ../.config
sudo cp -rp nvim ../.config
sudo cp -rp rofi ../.config
sudo cp -rp picom.conf ../.config
sudo cp -rp pacman.conf /etc
cd ~
