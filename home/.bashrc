#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
alias ls="eza -al --color=auto"
alias roblox='flatpak run org.vinegarhq.Sober'
alias delcache='sudo pacman -Scc; sudo pacman -Sc; sudo sync; echo 1 | sudo tee /proc/sys/vm/drop_caches; sudo sync; echo 2 | sudo tee /proc/sys/vm/drop_caches; sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches; sudo swapoff -a; sudo swapon -a; rm -rf .cache'
alias blueman='blueman-manager'
alias discord='flatpak run com.discordapp.Discord'
alias neofetch='neofetch --source $HOME/.config/neofetch/bk'
alias yt='source $HOME/yt/bin/activate; mov-cli -s youtube '
export XDG_CONFIG_HOME=/home/lazybev/.config
export XDG_DATA_HOME=/home/lazybev/.local/share
export XDG_STATE_HOME=/home/lazybev/.local/state
export XDG_CACHE_HOME=/home/lazybev/.cache
export PATH=.local/bin/:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_SYNC_TO_VBLANK=0
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export VK_LAYER_PATH=/usr/share/vulkan/explicit_layer.d
