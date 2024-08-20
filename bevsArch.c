#include <stdio.h> 
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

// Initializing variables
char root[100], efi[100], user[100], pass[100], tpass[100], y[10], laut[100];
void disk();
void prof();
void arch();
void chroot();

void disk() {
    // Partition disks
    system("lsblk");
    printf("Please enter EFI partition: (example /dev/sda1 or /dev/nvme0n1p1): ");
    scanf("%s", efi);
    printf("Please enter ROOT partition: (example /dev/sda2 or /dev/nvme0n1p2): ");
    scanf("%s", root);

    // Make the filesystems and mounting to targets
    char command[256];
    printf("\nCreating Filesystems...\n");
    snprintf(command, sizeof(command), "mkfs.fat -F 32 %s", efi);
    system(command);
    snprintf(command, sizeof(command), "mkfs.ext4 %s", root);
    system(command);
    system("mkdir -p /mnt/boot");
    snprintf(command, sizeof(command), "mount %s /mnt/boot", efi);
    system(command);
    snprintf(command, sizeof(command), "mount %s /mnt", root);
    system(command);
}

void prof() {
    printf("Please enter your username: ");
    scanf("%s", user); 

    do {
        printf("Please enter your password: ");
        scanf("%s", pass); 

        printf("Please enter your password again: ");
        scanf("%s", tpass);

        if (strcmp(tpass, pass) == 0) {
            printf("Passwords match\n");
        } else {
            printf("Passwords do not match, please try again\n");
        }

    } while(strcmp(tpass, pass) != 0);
}

void arch() {
    system("sudo cp -rpf Misc/pacman.conf /mnt/etc");
    system("pacstrap -K /mnt amd_ucode kitty systemd base xdg-desktop-portal xdg-desktop-portal-gtk base-devel efibootmgr sof-firmware mesa lib32-mesa systemd linux-lts linux-lts-headers linux-zen linux-zen-headers linux-firmware networkmanager network-manager-applet wireless_tools neofetch gvfs pavucontrol polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts adobe-source-han-sans-kr-fonts adobe-source-han-serif-kr-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts nano steam wine git rofi curl alacritty make cmake meson obsidian man-db xdotool thuanr reflector nitrogen flameshot zip unzip mpv btop emacs noto-fonts picom wireplumber dunst xarchiver eza thunar-archive-plugin fish --noconfirm --needed");
    system("genfstab -U /mnt >> /mnt/etc/fstab");
    system("cd ..");
    system("sudo mv -f dotfiles /mnt");
}

void chroot() {
    char command[256];
    snprintf(command, sizeof(command), "useradd -m %s", user);
    system(command);

    snprintf(command, sizeof(command), "usermod -aG wheel,storage,power,audio %s", user);
    system(command);

    snprintf(command, sizeof(command), "echo %s:%s | chpasswd", user, pass);
    system(command);

    system("sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers");

    snprintf(command, sizeof(command), "sudo mv -f dotfiles /home/%s && cd /home/%s", user, user);
    system(command);

    printf("Which layout would you like?: ");
    scanf("%s", laut);
    snprintf(command, sizeof(command), "loadkeys %s", laut);
    system(command);

    // Setup Language to US and set locale
    system("sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen");
    system("locale-gen");
    system("echo \"LANG=en_US.UTF-8\" >> /etc/locale.conf");

    system("ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime");
    system("hwclock --systohc");

    system("echo \"gentuwu\" > /etc/hostname");

    // Display and Audio Drivers
    system("pacman -Syu xorg xorg-server pipewire-pulse pipewire --noconfirm --needed");

    system("systemctl enable NetworkManager");

    // Desktop environment
    system("pacman -S i3 --noconfirm --needed");

    // Packages
    printf("Do you have paru installed? ");
    scanf("%s", y);
    if (strcmp(y, "no") == 0 || strcmp(y, "n") == 0) {
        system("git clone \"https://aur.archlinux.org/paru.git\"");
        snprintf(command, sizeof(command), "sudo chown %s:%s -R paru", user, user);
        system(command);
        system("cd paru && makepkg -sci");
    }

    system("paru -S vesktop-bin mercury-browser-bin");

    // Mirrors
    system("sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak");
    system("sudo reflector --verbose --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist");

    // My config
    snprintf(command, sizeof(command), "./UpdateConfig.sh");
    system(command);

    system("sudo mkinitcpio -P");
    
    system("git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs");
    system("~/.config/emacs/bin/doom install");
    system("~/.config/emacs/bin/doom sync");
    
    system("curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish");
}

int main(void) {
    disk();
    prof();
    arch();
    chroot();

    return 0;
}
