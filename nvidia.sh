#!/bin/bash

# Install the necessary packages
paru -S xf86-video-nouveau vulkan-mesa-layers lib32-vulkan-mesa-layers nvidia-prime nvidia-dkms nvidia-utils

# Check available graphics providers and OpenGL renderer
xrandr --listproviders && glxinfo | grep "OpenGL renderer"

# Set up the offloading sink for hybrid graphics
xrandr --setprovideroffloadsink 1 && xrandr --setprovideroffloadsink radeon

# Check OpenGL renderer for PRIME offloading and GPU power state
DRI_PRIME=1 glxinfo | grep "OpenGL renderer"
cat /sys/class/drm/card*/device/power_state

# Create udev rules for NVIDIA power management
cd /etc/udev/rules.d
sudo tee 80-nvidia-pm.rules > /dev/null <<EOL
# Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"

# Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"

# Enable runtime PM for NVIDIA VGA/3D controller devices on adding device
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
EOL

# Configure NVIDIA Dynamic Power Management
cd /etc/modprobe.d
sudo tee nvidia-pm.conf > /dev/null <<EOL
options nvidia NVreg_DynamicPowerManagement=0x02
EOL

# Check runtime power management status and suspended time for the NVIDIA device
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_suspended_time

# Start and enable the NVIDIA persistence daemon
sudo systemctl start nvidia-persistenced.service
sudo systemctl enable nvidia-persistenced.service

# Telling the user to reboot
echo "Rebooting..."
reboot
