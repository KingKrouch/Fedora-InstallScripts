#!/usr/bin/env bash
# Check the current Linux distribution, for checks that are going to be done later.
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
fi

# Run a check to see if using an unsupported distribution, and if so, exit.
case $NAME in
    ("Nobara Linux")
    echo "Nobara is being used."
    ;;
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    echo "Fedora is being used."
    ;;
    (*)
    echo "Unsupported Distro is being used. Exiting"
    exit
    ;;
esac

## ///// THE ABSOLUTE BASICS /////

# Automatically Configure DNF to be a bit faster, and gives the changes a test drive.
sudo bash -c 'echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf && echo 'defaultyes=True' >> /etc/dnf/dnf.conf
sudo dnf update -y

case $NAME in
    ("Nobara Linux")
    echo "Nobara is being used."

    # Safely remove something that causes "kde-settings conflicts with f[version]-backgrounds-kde"
    sudo rpm -e --nodeps f$(rpm -E %fedora)-backgrounds-kde
    ;;
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    echo "Fedora is being used."

    # Install third-party repositories (Via RPMFusion).
    sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
    sudo dnf group update core -y

    # Enable Flatpaks.
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    ;;
esac

# Enable System Theming with Flatpak (That way, theming is more consistent between native apps and flatpaks).
sudo flatpak override --filesystem=xdg-config/gtk-3.0

# Set up Flatseal for Flatpak permissions
flatpak install flathub com.github.tchx84.Flatseal -y

# Set up Homebrew Package Manager
sudo yum groupinstall 'Development Tools' -y
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/bryce/.bash_profile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# WIP FreeSync toggle for X11 mode for AMD GPUs, may need to be skipped or improved upon.
if grep -q "VariableRefresh" "/etc/X11/xorg.conf.d/20-amdgpu.conf"; then
    echo "Variable Refresh Rate tweak for X11 has already been done."
else
    echo 'Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
    Option "VariableRefresh" "true"' | sudo tee -a /etc/X11/xorg.conf.d/20-amdgpu.conf
fi

# Change the Swappiness level (for performance reasons) from 60 to 10. This may not be needed, hence why it's not commented anymore.
# echo "vm.swappiness=1" | sudo tee -a /etc/sysctl.conf

# Update using DNF Distro-Sync
sudo dnf distro-sync -y

## ///// TERMINAL STUFF /////

# Install fastfetch.
sudo dnf install fastfetch -y
mkdir ~/.config/fastfetch

# Set up fastfetch with my preferred configuration.
cp ./.config/fastfetch/config.conf  ~/.config/fastfetch/config.conf

# Install exa and lsd, which should replace lsd and dir. Also install thefuck for terminal command corrections, and fzf.
sudo dnf install exa lsd thefuck fzf htop cmatrix -y

# Install zsh, alongside setting up oh-my-zsh, and powerlevel10k.
sudo dnf install zsh -y && chsh -s $(which zsh) && sudo chsh -s $(which zsh)
sudo dnf install git git-lfs -y && sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"c
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
wget -O ~/.p10k.zsh https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/p10k.zsh

# Set up Powerlevel10k as the default zsh theme, alongside enabling some tweaks.
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k/powerlevel10k"/g' ~/.zshrc
echo "# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> tee -a ~/.zshrc
echo "typeset -g POWERLEVEL9K_INSTANT_PROMPT=off" >> tee -a ~/.zshrc

# Set up some ZSH plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
sed -i 's/plugins=(git)/plugins=(git emoji zsh-syntax-highlighting zsh-autosuggestions)/g' ~/.zshrc

## Add nerd-fonts for Noto and SourceCodePro font families. This will just install everything together, but I give no fucks at this point, just want things a little easier to set up.
git clone https://github.com/ryanoasis/nerd-fonts.git && cd nerd-fonts && ./install.sh && cd .. && sudo rm -rf nerd-fonts

# Append exa and lsd aliases, and neofetch alias to both the bashrc and zshrc.
echo '# Custom Commands
if [ -x /usr/bin/lsd ]; then
  alias ls='lsd'
  alias dir='lsd -l'
  alias lah='lsd -lah'
  alias lt='lsd --tree'
fi
if [ -x /usr/bin/thefuck ]; then
  eval $(thefuck --alias)
  eval $(thefuck --alias fix) # Allows triggering thefuck using the keyword 'fix'."
fi
if [ -x /usr/bin/fastfetch ]; then
  alias neofetch='fastfetch'
fi
neofetch' >> tee -a ~/.bashrc ~/.zshrc

## ///// GAMING AND GAMING TWEAKS /////

case $NAME in
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    # Install Steam and Steam-Devices.
    sudo dnf install steam steam-devices -y
    flatpak install flathub net.davidotek.pupgui2 -y

    # Install MangoHud with GOverlay, alongside Gamescope and vkBasalt.
    sudo dnf install goverlay -y && sudo dnf install vkBasalt -y && sudo dnf install gamescope -y

    # Install Lutris
    flatpak install flathub net.lutris.Lutris -y

    # Install gamemode alongside enabling the gamemode service.
    sudo dnf install gamemode -y && systemctl --user enable gamemoded.service && systemctl --user start gamemoded.service

    # Install OBS Studio.
    flatpak install flathub com.obsproject.Studio -y

    # Install GStreamer Plugin for OBS Studio, alongside some plugins.
    flatpak install com.obsproject.Studio.Plugin.Gstreamer org.freedesktop.Platform.GStreamer.gstreamer-vaapi -y
    flatpak install org.freedesktop.Platform.VulkanLayer.OBSVkCapture com.obsproject.Studio.Plugin.OBSVkCapture -y

    # Installs the needed hooks to get vkcapture in OBS to work.
    sudo dnf install obs-studio-devel obs-studio-libs -y
    git clone https://github.com/nowrep/obs-vkcapture && cd obs-vkcapture
    mkdir build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib ..
    make && sudo make install
    cd .. && cd .. & sudo rm -rf obs-vkcapture

    # Set up SuperGFXCTL and the SuperGFXCTL Plasmoid for Laptop GPU switching.
    sudo dnf copr enable gloriouseggroll/nobara
    sudo dnf install supergfxctl supergfxctl-plasmoid -y
    sudo dnf copr disable gloriouseggroll/nobara
    sudo systemctl enable supergfxd && sudo systemctl start supergfxd
    ;;
esac

flatpak install org.freedesktop.Platform.VulkanLayer.OBSVkCapture -y

# Install some useful scripts for SteamVR.
sudo dnf install python3-bluepy python3-yaml python3-psutil -y
git clone https://github.com/DavidRisch/steamvr_utils.git -b iss15_fix_v2_interface
python3 ./steamvr_utils/scripts/install.py

# Install some game launcher and emulator Flatpaks.
flatpak install flathub com.heroicgameslauncher.hgl -y
flatpak install flathub net.rpcs3.RPCS3 -y
flatpak install flathub org.yuzu_emu.yuzu -y
flatpak install flathub org.ryujinx.Ryujinx -y
flatpak install flathub org.DolphinEmu.dolphin-emu -y
flatpak install flathub net.pcsx2.PCSX2 -y
flatpak install flathub org.prismlauncher.PrismLauncher -y
flatpak install flathub dev.goats.xivlauncher -y
flatpak remote-add --if-not-exists --user launcher.moe https://gol.launcher.moe/gol.launcher.moe.flatpakrepo
flatpak install flathub org.gnome.Platform//43 # Install a specific GTK dependency for AAGL and HRWL.
flatpak install flathub com.valvesoftware.Steam.Utility.gamescope -y # Install Gamescope dependency for AAGL and HRWL.
flatpak install flathub org.freedesktop.Platform.VulkanLayer.MangoHud -y # Install MangoHud dependency for Heroic, AAGL, Lutris, and HRWL.
flatpak install flathub org.freedesktop.Platform.VulkanLayer.OBSVkCapture -y # Install OBS VkCapture layer for OBS capturing of Flatpak games.
flatpak install flathub com.valvesoftware.Steam.Utility.vkBasalt -y # Install VkBasalt for Flatpak games.
sudo flatpak override --filesystem=xdg-config/MangoHud:ro # Set up all Flatpaks to use our own MangoHUD config from GOverlay.
flatpak override --user --talk-name=com.feralinteractive.GameMode # Set up Gamemode override for MangoHUD Flatpak.
flatpak install launcher.moe moe.launcher.an-anime-game-launcher -y
flatpak install launcher.moe moe.launcher.the-honkers-railway-launcher -y
flatpak install launcher.moe moe.launcher.honkers-launcher -y
flatpak install flathub com.steamgriddb.steam-rom-manager -y

# Install some Proton related stuff (for game compatibility)
flatpak install flathub com.github.Matoking.protontricks -y

# Install a Soundboard Application, for micspamming in Team Fortress 2 servers, of course! ;-)
sudo dnf copr enable rivenirvana/soundux -y && sudo dnf install soundux pipewire-devel -y

# Set up Sunshine and Moonlight Streaming.
sudo dnf install https://github.com/LizardByte/Sunshine/releases/download/v0.20.0/sunshine-fedora-$(rpm -E %fedora)-amd64.rpm -y
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' | \
sudo tee /etc/udev/rules.d/85-sunshine.rules
systemctl --user enable sunshine
sudo setcap cap_sys_admin+p $(readlink -f $(which sunshine))
flatpak install flathub com.moonlight_stream.Moonlight -y

## ///// WINE AND WINDOWS SOFTWARE /////

case $NAME in
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    # Install 64-Bit WINE Staging, alongside some needed dependencies for later.
    sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo
    dnf install winehq-staging cabextract samba-winbind -y

    # Open Explorer to initialize our Wine prefix.
    echo "Initializing Wine prefix. Please exit out of Explorer when it opens and follow any setup prompts."
    wine64 explorer

    # Set up some prerequisites for Wine.
    wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
    chmod +x winetricks
    sh winetricks corefonts # look into avoid using winetricks for vcrun6 and dotnet462 because of the painfully long install process from the GUI installer. Fuck that.
    sh winetricks dotnet48
    ;;
    ("Nobara Linux") # Use the built-in version of Winetricks instead.
    # Open Explorer to initialize our Wine prefix.
    echo "Initializing Wine prefix. Please exit out of Explorer when it opens and follow any setup prompts."
    wine64 explorer
    winetricks corefonts
    winetricks dotnet48
    ;;
esac

wget https://aka.ms/vs/17/release/vc_redist.x86.exe
wget https://aka.ms/vs/17/release/vc_redist.x64.exe
wget https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe
wine NDP462-KB3151800-x86-x64-AllOS-ENU.exe
wine vc_redist.x86.exe /quiet /norestart
wine vc_redist.x64.exe /quiet /norestart
rm vc_redist.x86.exe vc_redist.x64.exe NDP462-KB3151800-x86-x64-AllOS-ENU.exe

echo "If you plan to use Clip Studio, set concrt140 as a WineDLLOverride in winecfg to prevent crashing."

# Set up DXVK, VKD3D, and Media Foundation codecs to Wine.
# TODO: Fix the DXVK setup process, as there's no more setup script. Commented out for the time being.
#wget https://github.com/doitsujin/dxvk/releases/download/v2.2/dxvk-2.2.tar.gz
#tar -xzvf dxvk-2.2.tar.gz
#cd dxvk-2.2
#WINEPREFIX="/home/$USER/.wine" ./setup_dxvk.sh install
#cd .. && rm -rf dxvk-2.2 && rm dxvk-2.2.tar.gz
#wget https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v2.9/vkd3d-proton-2.9.tar.zst
#tar --use-compress-program=unzstd -xvf vkd3d-proton-2.9.tar.zst && cd vkd3d-proton-2.9
#WINEPREFIX="/home/$USER/.wine" ./setup_vkd3d_proton.sh install
#cd .. && rm -rf vkd3d-proton-2.9 && rm vkd3d-proton-2.9.tar.zst
#git clone https://github.com/z0z0z/mf-install && cd mf-install
#WINEPREFIX="/home/$USER/.wine" ./mf-install.sh
#cd .. && rm -rf mf-install

# Set up Bottles.
flatpak install flathub com.usebottles.bottles -y
flatpak override com.usebottles.bottles --user --filesystem=xdg-data/applications

## //// NETWORKING STUFF /////

# Install Barrier for cross-device input management
sudo dnf install barrier -y

# Set up Samba
sudo dnf install samba -y
sudo systemctl enable smb nmb && sudo systemctl start smb nmb

# Set up SSH Server on Host
sudo systemctl enable sshd && sudo systemctl start sshd

# Disable NetworkManager Wait Service (due to long boot times) if using a desktop. Assuming this based on if a battery is available.
if [ -f /sys/class/power_supply/BAT1/uevent ]
    then echo "Battery is available. Skipping disabling the NetworkManager Wait Service."
else sudo systemctl disable NetworkManager-wait-online.service
fi

## ///// DEVELOPMENT/PROGRAMMING TOOLS AND GAME ENGINE STUFF /////

case $NAME in
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    # Set up Kernel-Devel
    sudo dnf install kernel-devel -y

    # Install RenderDoc and Vulkan Tools. I still need to find a workaround for installing RenderDoc on Nobara.
    sudo dnf install renderdoc -y && sudo dnf install vulkan-tools -y
    ;;
esac

# Set up Unity Hub and Jetbrains
sudo sh -c 'echo -e "[unityhub]\nname=Unity Hub\nbaseurl=https://hub.unity3d.com/linux/repos/rpm/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://hub.unity3d.com/linux/repos/rpm/stable/repodata/repomd.xml.key\nrepo_gpgcheck=1" > /etc/yum.repos.d/unityhub.repo' && sudo dnf update && sudo dnf install unityhub -y && sudo dnf install GConf2 -y
mkdir $HOME/Applications && cd $HOME/Applications && wget -O jetbrains-toolbox.tar.gz https://download.jetbrains.com/toolbox/jetbrains-toolbox-1.24.11947.tar.gz && tar xvzf jetbrains-toolbox.tar.gz && cd .. && echo "Make sure to remove the 'jetbrains-toolbox' executable from the extracted folder before running! Preferably copy it to '/opt' before running."

# Install Epic Asset Manager (For Unreal Engine)
flatpak install flathub io.github.achetagames.epic_asset_manager -y

# Install Docker.
sudo dnf install dnf-plugins-core -y
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin gnome-terminal -y
sudo dnf install https://desktop.docker.com/linux/main/amd64/docker-desktop-4.20.1-x86_64.rpm -y
sudo groupadd docker && sudo usermod -aG docker $USER
sudo systemctl enable docker && sudo systemctl start docker

# Install Distrobox and Podman (So Distrobox doesn't use Docker instead).
sudo dnf install podman distrobox -y

# Install MinGW64, CMake, Ninja Build
sudo dnf install mingw64-\* cmake ninja-build -y --skip-broken

# Install Ghidra.
flatpak install flathub org.ghidra_sre.Ghidra -y && sudo flatpak override org.ghidra_sre.Ghidra --filesystem=/mnt

# Install Visual Studio Code.
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' && sudo dnf check-update && sudo dnf install code -y

# Install several dependencies for CheatEngine-Proton-Helper
sudo dnf install python3-vdf yad xdotool -y

# Install a hex editor
sudo dnf install okteta -y

# Install GitHub Desktop
sudo rpm --import https://rpm.packages.shiftkey.dev/gpg.key
sudo sh -c 'echo -e "[shiftkey-packages]\nname=GitHub Desktop\nbaseurl=https://rpm.packages.shiftkey.dev/rpm/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://rpm.packages.shiftkey.dev/gpg.key" > /etc/yum.repos.d/shiftkey-packages.repo'
sudo dnf install github-desktop -y

# Install .NET Runtime/SDK and Mono (for Rider and C# applications)
sudo dnf install dotnet mono-devel -y

# Install Java
sudo dnf install java -y

## ///// VIRTUALIZATION /////

if grep -Eq 'vmx|svm' /proc/cpuinfo; then
    echo "Virtualization is enabled. Setting up virtualization packages."
    # Installs Virtual Machine related packages
    sudo dnf -y group install Virtualization -y

    # Set up GRUB Bootloader to use IOMMU based on the CPU type used
    cpu_vendor=$(grep -m 1 vendor_id /proc/cpuinfo | cut -d ":" -f 2 | tr -d '[:space:]')
    if [ "$cpu_vendor" = "GenuineIntel" ]; then
        echo "CPU vendor is Intel. Setting up Intel IOMMU boot parameters."
        sudo grubby --update-kernel=ALL --args="intel_iommu=on iommu=pt video=vesafb:off,efifb:off"
        # If you want iGPU passthrough for some reason, you can add "i915.modeset=0" to the end of the intel parameters.
    elif [ "$cpu_vendor" = "AuthenticAMD" ]; then
        echo "CPU vendor is AMD. Setting up AMD IOMMU boot parameters."
        sudo grubby --update-kernel=ALL --args="amd_iommu=on iommu=pt video=vesafb:off,efifb:off"
    else
        echo "Unknown CPU vendor. Skipping."
    fi
    sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg

    # Set up user permissions with libvirt
    sudo usermod -a -G libvirt $(whoami) && sudo usermod -a -G kvm $(whoami) && sudo usermod -a -G input $(whoami)
    sudo sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/g' /etc/libvirt/libvirtd.conf
    sudo sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/g' /etc/libvirt/libvirtd.conf

    # Add needed GPU Passthrough Hooks (This will be commented out for the time being, as it's not automated).
	# sudo mkdir -p /etc/libvirt/hooks
	# sudo wget 'https://raw.githubusercontent.com/PassthroughPOST/VFIO-Tools/master/libvirt_hooks/qemu' -O /etc/libvirt/hooks/qemu
	# sudo chmod +x /etc/libvirt/hooks/qemu

	# Make the directories for our VM Release/Prepare Scripts
	# sudo mkdir '/etc/libvirt/hooks/qemu.d'
	# sudo mkdir '/etc/libvirt/hooks/qemu.d/Win11' && sudo mkdir '/etc/libvirt/hooks/qemu.d/Win11/prepare' && sudo mkdir '/etc/libvirt/hooks/qemu.d/Win11/prepare/begin' && sudo mkdir '/etc/libvirt/hooks/qemu.d/Win11/release' && sudo mkdir '/etc/libvirt/hooks/qemu.d/Win11/release/end'

	# sudo echo -e "#!/bin/bash
	# Helpful to read output when debugging
	# set -x

	# Load the config file with our environmental variables
	# source \"/etc/libvirt/hooks/kvm.conf\"

	# Stop your display manager. If you're on KDE, it'll be sddm.service. Gnome users should use killall gdm-x-session instead
	# systemctl stop sddm.service
	# pulse_pid=$(pgrep -u YOURUSERNAME pulseaudio)
	# pipewire_pid=$(pgrep -u YOURUSERNAME pipewire-media)
	# kill $pulse_pid
	# kill $pipewire_pid

	# Unbind VTconsoles
	# echo 0 > /sys/class/vtconsole/vtcon0/bind
	# echo 0 > /sys/class/vtconsole/vtcon1/bind

	# Avoid a race condition by waiting a couple of seconds. This can be calibrated to be shorter or longer if required for your system
	# sleep 4

	# Unload all Radeon drivers

	# modprobe -r amdgpu
	# modprobe -r gpu_sched
	# modprobe -r ttm
	# modprobe -r drm_kms_helper
	# modprobe -r i2c_algo_bit
	# modprobe -r drm
	# modprobe -r snd_hda_intel

	# Unbind the GPU from display driver
	# virsh nodedev-detach $VIRSH_GPU_VIDEO
	# virsh nodedev-detach $VIRSH_GPU_AUDIO

	# Load VFIO kernel module
	# modprobe vfio
	# modprobe vfio_pci
	# modprobe vfio_iommu_type1
	# " >> '/etc/libvirt/hooks/qemu.d/Win11/prepare/begin/start.sh'
	# sudo chmod +x '/etc/libvirt/hooks/qemu.d/Win11/prepare/begin/start.sh'

	# sudo echo -e "#!/bin/bash
	# Helpful to read output when debugging
	# set -x

	# Load the config file with our environmental variables
	# source \"/etc/libvirt/hooks/kvm.conf\"

	# Unload all the vfio modules
	# modprobe -r vfio_pci
	# modprobe -r vfio_iommu_type1
	# modprobe -r vfio

	# Reattach the GPU
	# virsh nodedev-reattach $VIRSH_GPU_VIDEO
	# virsh nodedev-reattach $VIRSH_GPU_AUDIO

	# Load all Radeon drivers
	# modprobe amdgpu
	# modprobe gpu_sched
	# modprobe ttm
	# modprobe drm_kms_helper
	# modprobe i2c_algo_bit
	# modprobe drm
	# modprobe snd_hda_intel

	# Start your display manager
	# systemctl start sddm.service
	# " >> '/etc/libvirt/hooks/qemu.d/Win11/release/end/stop.sh'
	# sudo chmod +x '/etc/libvirt/hooks/qemu.d/Win11/release/end/stop.sh'

	# sudo echo -e "VIRSH_GPU_VIDEO=pci_0000_0a_00_0
	# VIRSH_GPU_AUDIO=pci_0000_0a_00_1" >> '/etc/libvirt/hooks/kvm.conf'

	# Download the RX 6700XT VBIOS that I use specifically (An ASUS ROG STRIX OC Edition)
	# sudo wget -O ~/GPU.rom https://www.techpowerup.com/vgabios/230897/Asus.RX6700XT.12288.210301.rom
	# sudo chmod -R 660 ~/GPU.rom && sudo chown $(whoami):$(whoami) ~/GPU.rom

    # Finally restart the Libvirt service.
    sudo systemctl restart libvirtd.service
else
    echo "Virtualization is not enabled. Skipping."
fi

## ///// ANDROID APP COMPATIBILITY /////
sudo dnf install waydroid -y
sudo systemctl enable --now waydroid-container
sudo waydroid init -s GAPPS -r lineage -c https://ota.waydro.id/system -v https://ota.waydro.id/vendor
cd ~/ && sudo dnf install lzip -y
git clone https://github.com/casualsnek/waydroid_script
cd waydroid_script
sudo python3 -m pip install -r requirements.txt
sudo python3 ./main.py install magisk
sudo python3 ./main.py install libhoudini
sudo python3 ./main.py install widevine
sudo python3 ./main.py install smartdock
sudo python3 main.py hack hidestatusbar
echo "Make sure to run 'sudo waydroid shell' followed by the command listed here: https://docs.waydro.id/faq/google-play-certification"
cd ..

# Install Yabridge (For VST Plugins, I'm going to assume you will set up a DAW on your own accords).
sudo dnf copr enable patrickl/yabridge-stable -y && sudo dnf install yabridge -y

# Install Compatibility Related Stuff for Autodesk Maya and Mudbox.
sudo dnf copr enable dioni21/compat-openssl10 -y && sudo dnf install pcre-utf16 -y && sudo dnf install compat-openssl10 -y
sudo dnf install libpng15 csh audiofile libXp rocm-opencl5.4.3 -y
mkdir $HOME/maya
mkdir $HOME/maya/2024
echo -e "MAYA_OPENCL_IGNORE_DRIVER_VERSION=1\nMAYA_CM_DISABLE_ERROR_POPUPS=1\nMAYA_COLOR_MGT_NO_LOGGING=1\nTMPDIR=/tmp\nMAYA_NO_HOME=1" >> $HOME/maya/2023/Maya.env
echo "Please download and install Autodesk Maya on your own accord. The dependencies and compatibility tweaks for Fedora should be taken care of now."
echo -e "LD_LIBRARY_PATH="/usr/autodesk/mudbox2024/lib"" >> $HOME/.profile

case $NAME in
    ("Fedora") # Install some flatpaks that are already taken care of in Nobara's setup process.
    flatpak install flathub org.blender.Blender -y
    flatpak install flathub org.kde.kdenlive -y
    ;;
esac

case $NAME in
    ("Nobara Linux")
    sudo dnf install rocm-meta -y # Need to figure out if this applies to Fedora too.
    ;;
esac
# TODO: Add Dracut regeneration just in case the AMD GPU Switcher drivers have been installed on Nobara.

flatpak install flathub org.kde.krita -y
flatpak install flathub org.gimp.GIMP -y

## ///// GENERAL DESKTOP USAGE /////

# Install the tiled window management KWin plugin, Bismuth.
sudo dnf install bismuth qt -y

# Use Librewolf instead of Firefox.
sudo dnf config-manager --add-repo https://rpm.librewolf.net/librewolf-repo.repo
sudo dnf install librewolf -y
sudo dnf remove firefox -y

# Install Microsoft Edge as a secondary web browser.
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo dnf install microsoft-edge-stable -y

# Install Warpinator for file transfers.
flatpak install flathub org.x.Warpinator -y

# Install the BETTER partition manager.
sudo dnf install gnome-disk-utility -y

# Remove some KDE Plasma bloatware that comes installed for some reason.
sudo dnf remove libreoffice-\* akregator ksysguard dnfdragora kfind kmag kmail kcolorchooser kmouth korganizer kmousetool kruler kaddressbook kcharselect konversation elisa-player kmahjongg kpat kmines dragonplayer kamoso kolourpaint krdc krfb -y

# Install Input-Remapper (For Razer Tartarus Pro)
sudo dnf install python3-evdev python3-devel gtksourceview4 python3-pydantic python-pydbus xmodmap -y
sudo pip install evdev -U && sudo pip uninstall key-mapper  && sudo pip install --no-binary :all: git+https://github.com/sezanzeb/input-remapper.git
sudo systemctl enable input-remapper && sudo systemctl restart input-remapper

case $NAME in
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    # Install and set up OpenRGB.
    sudo modprobe i2c-dev && sudo modprobe i2c-piix4 && sudo dnf install openrgb -y
    sudo udevadm control --reload-rules && sudo udevadm trigger
    sudo grubby --update-kernel=ALL --args="acpi_enforce_resources=lax"
    sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg

    # Install Discord (Nobara has it's own version, so that goes here).
    flatpak install flathub com.discordapp.Discord

    # Enable support for flatpak Discord to use Discord Rich Presence for non-sandboxed applications.
    mkdir -p ~/.config/user-tmpfiles.d
    echo 'L %t/discord-ipc-0 - - - - app/com.discordapp.Discord/discord-ipc-0' > ~/.config/user-tmpfiles.d/discord-rpc.conf
    systemctl --user enable --now systemd-tmpfiles-setup.service
    ;;
esac

# Install CoreCtrl for CPU power management purposes.
sudo dnf install corectrl -y
cp /usr/share/applications/org.corectrl.corectrl.desktop ~/.config/autostart/org.corectrl.corectrl.desktop
sudo grubby --update-kernel=ALL --args="amdgpu.ppfeaturemask=0xffffffff"
sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg

# Install some Flatpaks that I personally use.
flatpak install flathub org.mozilla.Thunderbird -y
flatpak install flathub org.qbittorrent.qBittorrent -y

# Install and Setup OneDrive.
sudo dnf install onedrive -y && sudo systemctl stop onedrive@$USER.service && sudo systemctl disable onedrive@$USER.service && systemctl --user enable onedrive && systemctl --user start onedrive
echo "Make sure to run onedrive --synchronize when you can."

# Install Mullvad VPN.
sudo dnf install https://mullvad.net/media/app/MullvadVPN-2023.3_x86_64.rpm -y

# Set up OnlyOffice.
flatpak install flathub org.onlyoffice.desktopeditors -y


## ///// MEDIA CODECS AND SUCH /////

case $NAME in
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    # Install Mesa Freeworld, so we can get FFMPEG back.
    sudo dnf install mesa-vdpau-drivers -y
    sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
    sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y

    # Add some optional codecs
    sudo dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
    sudo dnf groupupdate sound-and-video -y
    sudo dnf install @multimedia @sound-and-video ffmpeg-libs gstreamer1-plugins-{bad-*,good-*,base} gstreamer1-plugin-openh264 gstreamer1-libav lame* -y

    # Install Media Codecs and Plugins.
    sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y && sudo dnf install lame\* --exclude=lame-devel -y && sudo dnf group upgrade --with-optional Multimedia -y
    sudo dnf install vlc -y
    ;;
esac

# Install FFMPEG for Flatpak
flatpak install flathub org.freedesktop.Platform.ffmpeg-full

# Install Better Fonts
sudo dnf copr enable dawid/better_fonts -y && sudo dnf install fontconfig-font-replacements -y --skip-broken && sudo dnf install fontconfig-enhanced-defaults -y --skip-broken

# ///// TPM AUTOMATIC DECRYPTION (This is gonna need work before I can automate LUKS encryption on the boot drive to decrypt via TPM) /////
## Do this part in the LiveUSB environment (for Nobara) to convert from a LUKS to LUKS2 encryption system. #This might not be necessary with bogstandard Fedora, but it is with Nobara.
#case $NAME in
    #("Nobara Linux")
    #sudo cryptsetup --debug convert /dev/nvme0n1p3 --type=luks2
    #;;
#esac
#sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7+8 /dev/nvme0n1p3
#sudo sed -ie '/^luks-/s/$/,tpm2-device=auto/' /etc/crypttab # This might have to be "sudo sed -ie '/^luks-/s/$/,tpm2-device=auto,discard/' /etc/crypttab" instead, I'm unsure because I have two of them in this same script. lol.
# The following command will no longer be needed, from dracut 056 on
#sudo echo 'install_optional_items+=" /usr/lib64/libtss2* /usr/lib64/libfido2.so.* /usr/lib64/cryptsetup/libcryptsetup-token-systemd-tpm2.so "' > /etc/dracut.conf.d/tss2.conf
#sudo dracut --regenerate-all -force
