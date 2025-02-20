# 🌿 My Dotfiles

Welcome to my **dotfiles** repository! This is where I keep my personalized system configurations, crafted for efficiency, aesthetics, and a smooth workflow. 🚀

## ✨ Features

- **Minimalist & Clean** 🧼 – Simple and effective configurations.
- **Optimized for Arch Linux** 🏴 – Tailored for a fast and lightweight experience.
- **Terminal-First Setup** 💻 – Focused on CLI tools and TUI applications.
- **Custom Theming** 🎨 – Aesthetic colors and fonts for a visually pleasing setup.

## 📂 Structure

```bash
📦 dotfiles (X11 vers)
├── .zshrc               # zsh shell configuration
├── .config/             # Configuration files for various applications
│   ├── nvim/            # Neovim setup
│   ├── ghostty/         # Terminal emulator config
│   ├── i3/              # i3 window manager setup
│   ├── polybar/         # Custom status bar
│   ├── rofi/            # Application launcher config
│   ├── dunst/           # Notification daemon config
│   ├── fcitx5/          # Input method config
│   └── tmux/            # Terminal multiplexer config
└── README.md            # This file
```

## 🚀 Installation

If your new to linux or a long time user and want to use my config, you have to use arch and i so happen to provide a arch install script you can use :3

(Sidenote: there comes to a point in every linux users lifetime where they just use arch (btw), and my time was roughly a week after my first time with linux (i used linux mint) 😭)

To use my arch install script run these commands
```sh
git clone https://github.com/LazyBev/dotfiles.git ~/dotfiles # Dont run this command if you already have my repo cloned
cd ~/.dotfiles; chmod +x Scripts/ArchInstall.sh.sh
./Scripts/ArchInstall.sh
```

To install these dotfiles, you can clone the repository and set up symlinks:

```sh
git clone https://github.com/LazyBev/dotfiles.git ~/dotfiles # Dont run this command if you already have my repo cloned
cd ~/.dotfiles; chmod +x Scripts/Conf.sh
./Scripts/Conf.sh  # Run the installation script
```

Alternatively, you can manually link specific dirs to your config:

```sh
# Install stow via package manager and make sure you have the packages my configs use
stow <dir> --adopt # adopt isnt necessary unless the dirs already exist
```

## 🛠 Overview

- **Shell**: Bash 🐚
- **Editor**: Neovim ✍️
- **Terminal**: Ghostty 🖥️
- **WM**: i3 🖼️
- **Fonts**: Meslo Nerd Font 🔤
- **Launcher**: Rofi 🚀
- **Notifications**: Dunst 🔔
- **Input Method**: Fcitx5 🌐
- **Multiplexer**: Tmux 🔄
- **Bar**: Polybar 📊
- **Browser**: Firefox 🌍

## 🎨 Screenshot
COMING SOON
