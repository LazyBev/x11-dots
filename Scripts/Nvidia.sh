#!/bin/bash

set -e

# Variables
root=false
help=false
prop=""
NVIDIA_VENDOR="0x$(lspci -nn | grep -i nvidia | sed -n 's/.*\[\([0-9A-Fa-f]\+\):[0-9A-Fa-f]\+\].*/\1/p' | head -n 1)"

# Parse arguments
for arg in "$@"; do
    case $arg in
	-r | --root)
	    root=true
            ;;
	-h | --help)
            help=true
            ;;
        *)
  	    echo "Invalid argument. Give correct arguments"
	    help=true
	    ;;
    esac
done

if ! $help; then

    # Check for root privileges
    if ! $root || [[ $EUID -ne 0 ]]; then
        echo "Please run as root or use the -r option or run this script with sudo"
        exit 1
    fi

    # Function to execute commands
    run_command() {
        if $root; then
            sudo "$@"
        else
            "$@"
        fi
    }

    # Install the necessary packages
    run_command pacman -S --noconfirm xf86-video-nouveau vulkan-mesa-layers lib32-vulkan-mesa-layers nvidia-prime nvidia-open-dkms nvidia-utils dkms
    
    # Check available graphics providers and OpenGL renderer
    lspci -k -d ::03xx
    xrandr --listproviders && glxinfo | grep "OpenGL renderer"
    
    # Set up the offloading sink for hybrid graphics (replace radeon if necessary)
    echo "Setting offloading sink..."
    read -p "Enter the provider number for offloading sink (e.g., 1): " provider_number
    xrandr --setprovideroffloadsink $provider_number
    
    # Check OpenGL renderer for PRIME offloading and GPU power state
    DRI_PRIME=glxinfo | grep "OpenGL renderer"
    cat /sys/class/drm/card*/device/power_state

    # Creating kernel hooks
    run_command bash -c 'echo "[Trigger]" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo "Operation=Install" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo "Operation=Upgrade" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo "Operation=Remove" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo "Type=Package" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo "Target=nvidia-open-dkms" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo -e "Target=linux\n" >> /etc/pacman.d/hooks/nvidia.hook'
    
    run_command bash -c 'echo "[Action]" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo "Description=Updating NVIDIA module in initcpio" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo "Depends=mkinitcpio" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo "When=PostTransaction" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo "NeedsTargets" >> /etc/pacman.d/hooks/nvidia.hook'
    run_command bash -c 'echo "Exec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'" >> /etc/pacman.d/hooks/nvidia.hook'
    
    # Create udev rules for NVIDIA power management
    echo "Creating udev rules for NVIDIA power management..."
    run_command bash -c 'echo "# Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind" >> /etc/udev/rules.d/80-nvidia-pm.rules'
    run_command bash -c 'echo "ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"" >> /etc/udev/rules.d/80-nvidia-pm.rules'
    run_command bash -c 'echo -e "ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"\n" >> /etc/udev/rules.d/80-nvidia-pm.rules'
    
    run_command bash -c 'echo "# Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind" >> /etc/udev/rules.d/80-nvidia-pm.rules'
    run_command bash -c 'echo "ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"" >> /etc/udev/rules.d/80-nvidia-pm.rules'
    run_command bash -c 'echo -e "ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"\n" >> /etc/udev/rules.d/80-nvidia-pm.rules'
    
    run_command bash -c 'echo "# Enable runtime PM for NVIDIA VGA/3D controller devices on adding device" >> /etc/udev/rules.d/80-nvidia-pm.rules'
    run_command bash -c 'echo "ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"" >> /etc/udev/rules.d/80-nvidia-pm.rules'
    run_command bash -c 'echo "ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="$NVIDIA_VENDOR", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"" >> /etc/udev/rules.d/80-nvidia-pm.rules'

    # Configure NVIDIA Dynamic Power Management
    echo "Configuring NVIDIA Dynamic Power Management..."
    run_command bash -c 'echo "options nvidia NVreg_DynamicPowerManagement=0x02" >> /etc/modprobe.d/nvidia-pm.conf'
    
    # Check runtime power management status and suspended time for the NVIDIA device
    echo -e "\nChecking NVIDIA power management status...\n"
    cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
    cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_suspended_time

    nvidia-xconfig
else
    echo "Options:"
    echo " -r, --root       run script with sudo"
    echo " -h, --help       display this help message"
fi

# Prompt the user to reboot
read -p "Would you like to reboot now? [y/N]: " reboot_choice
case $reboot_choice in
    y | Y)
        reboot
        ;;
    *)
        echo "Reboot skipped. Please reboot manually if necessary."
        ;;
esac
