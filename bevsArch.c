#include <stdio.h> 
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

// Initializing variables
char root[100], efi[100], user[100], pass[100], tpass[100], y[10], laut[100];
void disk();
void prof();
void arch();
void chr();

void disk() {
    // Partition disks
    system("lsblk");
    printf("Please enter EFI partition: (example /dev/sda1 or /dev/nvme0n1p1): ");
    scanf("%s", efi);
    printf("Please enter ROOT partition: (example /dev/sda1 or /dev/nvme0n1p1): ");
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
    system("pacstrap -K /mnt amd_ucode systemd base base-devel efibootmgr sof-firmware mesa lib32-mesa systemd linux-lts linux-lts-headers linux-zen linux-zen-headers linux-firmware networkmanager network-manager-applet wireless_tools neofetch gvfs pavucontrol polkit-gnome lxappearance bottom fcitx5-im fcitx5-mozc adobe-source-han-sans-jp-fonts adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-jp-fonts nano git rofi curl alacritty make obsidian man-db xdotool thuanr reflector nitrogen flameshot zip unzip mpv btop vim neovim picom wireplumber dunst xarchiver eza thunar-archive-plugin fish --noconfirm --needed");
    system("genfstab -U /mnt >> /mnt/etc/fstab");
    system("cd ..");
    system("sudo mv -f dotfiles /mnt");
}

void chr() {
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
    printf("---- Making backup at /home/%s/configBackup -----", user);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/.config /home/%s/configBackup", user, user);
    system(command);
    printf("----- Backup made at /home/%s/configBackup ------", user);

    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/dunst /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/alacritty /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/nitrogen /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/fcitx5 /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/mozc /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/fonts/SF-Mono-Powerline /home/%s/.local/share/fonts", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/fonts/MartianMono /home/%s/.local/share/fonts", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/fonts/fontconfig /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/fish /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/omf /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/i3 /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/nvim /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/rofi /home/%s/.config", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/Misc/picom.conf /home/%s/.config", user, user);
    system(command);

    snprintf(command, sizeof(command), "if [ -d /home/%s/Pictures ]; then sudo rm -rf /home/%s/Pictures; fi", user, user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -f Pictures/bgpic.jpg /home/%s/Pictures", user);
    system(command);
    snprintf(command, sizeof(command), "sudo cp -rpf Pictures /home/%s", user);
    system(command);

    snprintf(command, sizeof(command), "if [ -d /home/%s/Videos ]; then sudo rm -rf /home/%s/Videos/; else sudo mkdir /home/%s/Videos/; fi", user, user, user);
    system(command);

    snprintf(command, sizeof(command), "sudo cp -rpf /home/%s/dotfiles/Misc/mkinitcpio.conf /etc/", user);
    system(command);
    system("sudo mkinitcpio -P");

    system("curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish");
}

int main(void) {
    disk();
    prof();
    arch();
    chr();

    return 0;
}
