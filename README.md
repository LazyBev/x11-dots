# 🌿 My Dotfiles

Welcome to my dotfiles repository! This is where I keep my personalized system configurations, crafted for efficiency, aesthetics, and a smooth workflow. 🚀

## ✨ Features

- **Minimalist & Clean** 🧼 – Simple and effective configurations.
- **Optimized for Arch Linux** 🏴 – Tailored for a fast and lightweight experience.
- **Terminal-First Setup** 💻 – Focused on CLI tools and TUI applications.
- **Custom Theming** 🎨 – Aesthetic colors and fonts for a visually pleasing setup.
- **Wayland-Centric** 🌙 – Built with Wayland and Hyprland in mind.

## 📂 Structure

📦 **dotfiles** (Wayland version)  
├── `.zshrc`               # Zsh shell configuration  
├── `.config/`             # Configuration files for various applications  
│   ├── `nvim/`            # Neovim setup  
│   ├── `ghostty/`         # Terminal emulator config  
│   ├── `hypr/`            # Hyprland window manager setup  
│   ├── `waybar/`          # Custom status bar  
│   ├── `rofi/`            # Application launcher config  
│   ├── `dunst/`           # Notification daemon config  
│   └── `tmux/`            # Terminal multiplexer config  
└── `README.md`            # This file

## 🚀 Installation

If you're new to Linux or a long-time user and want to use my config, you need to be running **Arch Linux**, and I have an Arch install script ready for you! :3

(Sidenote: There comes a point in every Linux user's lifetime where they just use Arch (btw), and my time was roughly a week after my first time with Linux, when I was using Linux Mint) 😭

To use my Arch install script, run these commands:

```bash
git clone https://github.com/username/dotfiles.git ~/dotfiles # Clone the repo
cd ~/.dotfiles; chmod +x Scripts/ArchInstall.sh
./Scripts/ArchInstall.sh
```
```bash
git clone https://github.com/username/dotfiles.git ~/dotfiles # Clone the repo
cd ~/.dotfiles; chmod +x Scripts/Conf.sh
./Scripts/Conf.sh  # Run the installation script
```

```bash
# Install stow via package manager and make sure you have the packages my configs use
stow <dir> --adopt # Adopt isn't necessary unless the dirs already exist
```
