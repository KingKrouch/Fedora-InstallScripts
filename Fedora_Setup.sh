#!/usr/bin/env bash
# Function for checking for the latest GitHub release for a project.
get_latest_github_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

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
    FLATPAK_TYPE="--system" # I believe this is needed for Flatpak installation on Nobara now.
    ;;
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    echo "Fedora is being used."
    FLATPAK_TYPE=""
    ;;
    (*)
    echo "Unsupported Distro is being used. Exiting"
    exit
    ;;
esac

## ///// NIX PACKAGE MANAGER /////

# Set up Nix Package Manager (As shown here: https://github.com/dnkmmr69420/nix-installer-scripts)
case $NAME in
    ("Nobara Linux")
    echo "Nobara is being used."

    # Set up Nix without SELinux.
    curl -s https://raw.githubusercontent.com/dnkmmr69420/nix-installer-scripts/main/installer-scripts/regular-installer.sh | bash
    ;;
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    echo "Fedora is being used."

    # Set up Nix using SELinux.
    curl -s https://raw.githubusercontent.com/dnkmmr69420/nix-installer-scripts/main/installer-scripts/regular-nix-installer-selinux.sh | bash
    ;;
esac

# Add Nix packages to Desktop Environment Start Menu
sudo rm -f /etc/profile.d/nix-app-icons.sh ; sudo wget -P /etc/profile.d https://raw.githubusercontent.com/dnkmmr69420/nix-installer-scripts/main/other-files/nix-app-icons.sh

# Set up Sudo to detect Nix commands
bash <(curl -s https://raw.githubusercontent.com/dnkmmr69420/nix-installer-scripts/main/other-scripts/nix-linker.sh)

# Add NixGL support (For OpenGL & Vulkan applications, as shown here: https://github.com/nix-community/nixGL).
nix-channel --add https://github.com/guibou/nixGL/archive/main.tar.gz nixgl && nix-channel --update
nix-env -iA nixgl.auto.nixGLDefault   # or replace `nixGLDefault` with your desired wrapper

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
flatpak install flathub com.github.tchx84.Flatseal $FLATPAK_TYPE -y

# Set up Homebrew Package Manager
sudo yum groupinstall 'Development Tools' -y
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> ~/.bash_profile
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
sudo dnf install lsd fzf htop cmatrix -y
brew install exa thefuck # Use Homebrew for exa and thefuck, as they aren't available on Fedora's repositories or are currently broken on Fedora 39 (Thanks to Python 3.12)

# Install oh-my-bash alongside changing the default theme.
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
sed -i 's/OSH_THEME="font"/OSH_THEME="agnoster"/g' ~/.bashrc

# Install Powershell and Microsoft's software repositories.
sudo dnf install https://packages.microsoft.com/config/fedora/$(rpm -E %fedora)/packages-microsoft-prod.rpm -y
sudo dnf install https://github.com/PowerShell/PowerShell/releases/download/v7.3.9/powershell-7.3.9-1.rh.x86_64.rpm -y

# Install oh-my-posh for Powershell.
curl -s https://ohmyposh.dev/install.sh | sudo bash -s
# Downloads our custom powershell profile.
wget -O ~/.config/powershell/Microsoft.Powershell_profile.ps1 https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/.config/powershell/Microsoft.PowerShell_profile.ps1

# Install zsh, alongside setting up oh-my-zsh, and powerlevel10k.
sudo dnf install zsh -y && chsh -s $(which zsh) && sudo chsh -s $(which zsh)
sudo dnf install git git-lfs -y && sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"c
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
wget -O ~/.p10k.zsh https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/.p10k.zsh

# Set up Powerlevel10k as the default zsh theme, alongside enabling some tweaks.
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k/powerlevel10k"/g' ~/.zshrc
echo "# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> tee -a ~/.zshrc
echo "typeset -g POWERLEVEL9K_INSTANT_PROMPT=off" >> tee -a ~/.zshrc

# Set up some ZSH plugins.
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# TODO: Fix sed command.
sed -i 's/plugins=(git)/plugins=(git emoji zsh-syntax-highlighting zsh-autosuggestions)/g' ~/.zshrc

# Append exa and lsd aliases, and neofetch alias to both the bashrc and zshrc.
# TODO: Fix fastfetch echos.
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
if [ -x /usr/bin/pwsh ]; then
  alias powershell='pwsh'
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
    flatpak install flathub net.davidotek.pupgui2 $FLATPAK_TYPE -y

    # Install MangoHud with GOverlay, alongside Gamescope and vkBasalt.
    sudo dnf install goverlay -y && sudo dnf install vkBasalt -y && sudo dnf install gamescope -y

    # Temporary workaround for Fedora (So, you can have MangoApp working). When the fuck is MangoApp gonna work through compiling from source?
    sudo dnf install --allowerasing https://download.copr.fedorainfracloud.org/results/gloriouseggroll/nobara/fedora-38-x86_64/06517212-mangohud/mangohud-0.7.0-6.fc38.x86_64.rpm https://download.copr.fedorainfracloud.org/results/gloriouseggroll/nobara/fedora-38-i386/06517212-mangohud/mangohud-0.7.0-6.fc38.i686.rpm -y

    # Install Lutris
    flatpak install flathub net.lutris.Lutris $FLATPAK_TYPE -y

    # Install gamemode alongside enabling the gamemode service.
    sudo dnf install gamemode -y && systemctl --user enable gamemoded.service && systemctl --user start gamemoded.service

    # Install OBS Studio.
    flatpak install flathub com.obsproject.Studio $FLATPAK_TYPE -y

    # Install GStreamer Plugin for OBS Studio, alongside some plugins.
    flatpak install com.obsproject.Studio.Plugin.Gstreamer org.freedesktop.Platform.GStreamer.gstreamer-vaapi $FLATPAK_TYPE -y
    flatpak install org.freedesktop.Platform.VulkanLayer.OBSVkCapture com.obsproject.Studio.Plugin.OBSVkCapture $FLATPAK_TYPE -y

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

# Add Gamescope Session and Steam Deck Gyro DSU for Switch/WiiU emulation.
case $NAME in
    ("Fedora")
    # Setup Gamescope Session.
    git clone https://github.com/ChimeraOS/gamescope-session --recursive
    git clone https://github.com/ChimeraOS/gamescope-session-steam --recursive
    cd gamescope-session && sudo cp -r usr/* /usr
    cd ..
    cd gamescope-session-steam && sudo cp -r usr/* /usr
    cd ..
    sudo rm -rf gamescope-session gamescope-session-steam
    sudo rm -rf /usr/share/wayland-sessions/gamescope-session.desktop
    # Set up SteamDeckGyroDSU.
    bash <(curl -sL https://raw.githubusercontent.com/kmicki/SteamDeckGyroDSU/master/pkg/update.sh)
    ;;
    ("Nobara Linux") # This is for Fedora specific stuff that can safely be ignored with Fedora.
    sudo dnf install sdgyrodsu gamescope-session jupiter-hw-support jupiter-fan-control -y
    ;;
esac

# Set up Decky Loader for Steam.
curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh

# Set up some dependencies for OBS that aren't included with Nobara for some reason.
sudo dnf install libndi -y

# Set up the OBS Studio shortcut to use the propreitary AMD drivers, so AMF encoding can be used instead.
cp /usr/share/applications/com.obsproject.Studio.desktop ~/.local/share/applications
sed -i 's/^Exec=/Exec=vk_pro /' ~/.local/share/applications/com.obsproject.Studio.desktop

# Install the needed OBS-VKCapture layer for Flatpak software (Useful for games on Heroic, or the Anime Game Launchers).
flatpak install org.freedesktop.Platform.VulkanLayer.OBSVkCapture $FLATPAK_TYPE -y

# Install some useful scripts for SteamVR.
sudo dnf install python3-bluepy python3-yaml python3-psutil -y
git clone https://github.com/DavidRisch/steamvr_utils.git -b iss15_fix_v2_interface
python3 ./steamvr_utils/scripts/install.py

# Install some game launcher and emulator Flatpaks.
flatpak install flathub com.heroicgameslauncher.hgl $FLATPAK_TYPE -y
flatpak install flathub net.rpcs3.RPCS3 $FLATPAK_TYPE -y
flatpak install flathub org.yuzu_emu.yuzu $FLATPAK_TYPE -y
flatpak install flathub org.ryujinx.Ryujinx $FLATPAK_TYPE -y
flatpak install flathub org.DolphinEmu.dolphin-emu $FLATPAK_TYPE -y
flatpak install flathub net.pcsx2.PCSX2 $FLATPAK_TYPE -y
flatpak install flathub org.prismlauncher.PrismLauncher $FLATPAK_TYPE -y
flatpak install flathub io.github.vinegarhq.Vinegar $FLATPAK_TYPE -y
flatpak install flathub dev.goats.xivlauncher $FLATPAK_TYPE -y
flatpak remote-add --if-not-exists --user launcher.moe https://gol.launcher.moe/gol.launcher.moe.flatpakrepo
flatpak install flathub org.gnome.Platform//45 $FLATPAK_TYPE -y # Install a specific GTK dependency for AAGL and HRWL.
flatpak install flathub org.freedesktop.Platform.VulkanLayer.gamescope $FLATPAK_TYPE -y # Install Gamescope dependency for AAGL and HRWL.
flatpak remove com.valvesoftware.Steam.Utility.gamescope -y # Remove the old Gamescope dependency if it exists.
flatpak install flathub org.freedesktop.Platform.VulkanLayer.MangoHud $FLATPAK_TYPE -y # Install MangoHud dependency for Heroic, AAGL, Lutris, and HRWL.
flatpak install flathub org.freedesktop.Platform.VulkanLayer.OBSVkCapture $FLATPAK_TYPE -y # Install OBS VkCapture layer for OBS capturing of Flatpak games.
flatpak install flathub com.valvesoftware.Steam.Utility.vkBasalt $FLATPAK_TYPE -y # Install VkBasalt for Flatpak games.
sudo flatpak override --filesystem=xdg-config/MangoHud:ro # Set up all Flatpaks to use our own MangoHUD config from GOverlay.
flatpak override --user --talk-name=com.feralinteractive.GameMode # Set up Gamemode override for MangoHUD Flatpak.
flatpak install launcher.moe moe.launcher.an-anime-game-launcher --user -y
flatpak install launcher.moe moe.launcher.the-honkers-railway-launcher --user -y
flatpak install launcher.moe moe.launcher.honkers-launcher --user -y
flatpak install flathub com.steamgriddb.steam-rom-manager $FLATPAK_TYPE -y

# Install some Proton related stuff (for game compatibility)
flatpak install flathub com.github.Matoking.protontricks $FLATPAK_TYPE -y

# Install a Soundboard Application, for micspamming in Team Fortress 2 servers, of course! ;-)
sudo dnf copr enable rivenirvana/soundux -y && sudo dnf install soundux pipewire-devel -y

# Set up Sunshine and Moonlight Streaming.
sudo dnf install https://github.com/LizardByte/Sunshine/releases/download/v0.20.0/sunshine-fedora-$(rpm -E %fedora)-amd64.rpm -y
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' | \
sudo tee /etc/udev/rules.d/85-sunshine.rules
systemctl --user enable sunshine
sudo setcap cap_sys_admin+p $(readlink -f $(which sunshine))
flatpak install flathub com.moonlight_stream.Moonlight $FLATPAK_TYPE -y

# Fix DualSense pairing over Bluetooth. The Arch Wiki says that this is the only fix, but I could've sworn I paired before w/o this.
input_conf="/etc/bluetooth/input.conf"
userspace_hid="UserspaceHID=true"
if [ -f "$input_conf" ]; then
    # If file exists, add or modify the line UserspaceHID=true
    if ! grep -qF "$userspace_hid" "$input_conf"; then
        echo "$userspace_hid" | sudo tee -a "$input_conf" > /dev/null
    fi
else
    # If file doesn't exist, create it and add UserspaceHID=true
    echo "$userspace_hid" | sudo tee "$input_conf" > /dev/null
fi

# Disable the DualSense trackpad in desktop mode (This apparently works under X11, I don't know about Wayland).
echo 'Section "InputClass"
    Identifier "Sony Interactive Entertainment Wireless Controller Touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Ignore" "true"
EndSection' | sudo tee -a /etc/X11/xorg.conf.d/30--dualsense-touchpad.conf

# Downgrade Bluez package so DualSense controllers can actually pair properly.
#sudo dnf install bluez-5.68-1.fc39 -y
sudo dnf install https://kojipkgs.fedoraproject.org//packages/bluez/5.68/1.fc$(rpm -E %fedora)/x86_64/bluez-5.68-1.fc$(rpm -E %fedora).x86_64.rpm https://kojipkgs.fedoraproject.org//packages/bluez/5.68/1.fc$(rpm -E %fedora)/x86_64/bluez-cups-5.68-1.fc$(rpm -E %fedora).x86_64.rpm -y
echo "exclude=bluez" | sudo tee -a /etc/dnf/dnf.conf
#sudo sed -i '/exclude=bluez/d' /etc/dnf/dnf.conf # Uncomment and use this command when it's safe to update bluez.
sudo systemctl restart bluetooth.service

# Install XPadNeo drivers for Xbox controllers.
case $NAME in
    ("Fedora")
    sudo dnf copr enable sentry/xpadneo -y && sudo dnf install xpadneo -y
    ;;
esac

# Do some user permission stuff, so we don't have to dick with reinstalling the Xbox drivers through Nobara's setup GUI after a restart
sudo usermod -a -G pkg-build $USER

## ///// WINE AND WINDOWS SOFTWARE /////

case $NAME in
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    # Install 64-Bit WINE Staging, alongside some needed dependencies for later.
    dnf install wine-staging -y

    # Install Yabridge (For VST Plugins, I'm going to assume you will set up a DAW on your own accords).
    sudo dnf copr enable patrickl/yabridge -y && sudo dnf install yabridge --refresh -y

    # Install Winetricks and some other dependencies.
    sudo dnf install winetricks cabextract samba-winbind -y
    # Set up realtime, jackuser, and audiogroups alongside necessary permissions.
    echo -e '@audio\trtprio 99\n@audio\tmemlock unlimited' | sudo tee -a /etc/security/limits.conf
    sudo groupadd realtime && sudo usermod -a -G realtime $(whoami)
    sudo groupadd jackuser && sudo usermod -a -G jackuser $(whoami)
    sudo usermod -a -G audio $(whoami)
    sudo sh -c 'echo "JACK_START_SERVER=1" >> /etc/environment'
    sudo sh -c 'echo "WINEASIO_AUTOSTART_SERVER=on" >> /etc/environment'

    # Open Explorer to initialize our Wine prefix.
    echo "Initializing Wine prefix. Please exit out of Explorer when it opens and follow any setup prompts."
    wine64 explorer

    # Set up some prerequisites for Wine.
    winetricks corefonts # look into avoid using winetricks for vcrun6 and dotnet462 because of the painfully long install process from the GUI installer. Fuck that.
    winetricks dotnet48

    # Ableton Stuff (Feel free to use this if you are planning to install Ableton Live. I just have it here for reference).
    # WINEPREFIX=~/.ableton wine64 explorer
    #WINEPREFIX=$HOME/.ableton winetricks win7 quicktime72 gdiplus vb2run vcrun2008 vcrun6 vcrun2010 vcrun2013 vcrun2015 tahoma msxml3 msxml6 setupapi python27
    
    # Set our Wine Prefix to use ALSA audio, so it won't crash with WineASIO or other ASIO plugins.
    WINEPREFIX=$HOME/.wine winetricks sound=alsa
    #WINEPREFIX=$HOME/.ableton winetricks sound=alsa
    ;;
    ("Nobara Linux") # Use the built-in version of Winetricks instead.
    # Open Explorer to initialize our Wine prefix.
    echo "Initializing Wine prefix. Please exit out of Explorer when it opens and follow any setup prompts."
    wine64 explorer
    # Set up some dependencies.
    winetricks corefonts
    winetricks dotnet48
    winetricks mf
    echo "If you plan to use Clip Studio, set concrt140 as a WineDLLOverride in winecfg to prevent crashing."
    ;;
esac

# TODO: Figure out why "winetricks vcrun2015 vcrun2017 vcrun2019 vcrun2022" is slow as shit.
wget https://aka.ms/vs/17/release/vc_redist.x86.exe
wget https://aka.ms/vs/17/release/vc_redist.x64.exe
wget https://download.visualstudio.microsoft.com/download/pr/8e396c75-4d0d-41d3-aea8-848babc2736a/80b431456d8866ebe053eb8b81a168b3/ndp462-kb3151800-x86-x64-allos-enu.exe
wine64 ndp462-kb3151800-x86-x64-allos-enu.exe
wine64 vc_redist.x86.exe /quiet /norestart
wine64 vc_redist.x64.exe /quiet /norestart
rm vc_redist.x86.exe vc_redist.x64.exe NDP462-KB3151800-x86-x64-AllOS-ENU.exe

# Set up Bottles.
flatpak install flathub com.usebottles.bottles $FLATPAK_TYPE -y
flatpak override com.usebottles.bottles --user --filesystem=xdg-data/applications

## //// NETWORKING STUFF /////

# Install Barrier for cross-device input management
sudo dnf install barrier -y

# Set up Samba
sudo dnf install samba -y
sudo systemctl enable smb nmb && sudo systemctl start smb nmb
case $XDG_CURRENT_DESKTOP in
    ("KDE") # Install the KDE Plasma extension for Samba Shares, alongside setting up the needed permissions.
    sudo dnf install kdenetwork-filesharing -y
    sudo groupadd sambashares && sudo usermod -a -G sambashares $USER
    sudo mkdir /var/lib/samba/usershares && sudo chgrp sambashares /var/lib/samba/usershares && sudo chown $USER:sambashares /var/lib/samba/usershares
    ;;
esac

# Set up SSH Server on Host
sudo systemctl enable sshd && sudo systemctl start sshd

# Disable NetworkManager Wait Service (due to long boot times) if using a desktop. Assuming this based on if a battery is available.
if [ -f /sys/class/power_supply/BAT1/uevent ]
    then echo "Battery is available. Skipping disabling the NetworkManager Wait Service."
else sudo systemctl disable NetworkManager-wait-online.service
fi

## ///// DEVELOPMENT/PROGRAMMING TOOLS AND GAME ENGINE STUFF /////

# Set up Kernel-Devel
sudo dnf install kernel-devel -y

# Install RenderDoc and Vulkan Tools.
dnf copr enable kb1000/renderdoc -y
sudo dnf install renderdoc -y && sudo dnf install vulkan-tools -y

# Set up Unity Hub and Jetbrains
sudo sh -c 'echo -e "[unityhub]\nname=Unity Hub\nbaseurl=https://hub.unity3d.com/linux/repos/rpm/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://hub.unity3d.com/linux/repos/rpm/stable/repodata/repomd.xml.key\nrepo_gpgcheck=1" > /etc/yum.repos.d/unityhub.repo' && sudo dnf update && sudo dnf install unityhub -y && sudo dnf install GConf2 -y
mkdir $HOME/Applications && cd $HOME/Applications && wget -O jetbrains-toolbox.tar.gz https://download.jetbrains.com/toolbox/jetbrains-toolbox-1.24.11947.tar.gz && tar xvzf jetbrains-toolbox.tar.gz && cd .. && echo "Make sure to remove the 'jetbrains-toolbox' executable from the extracted folder before running! Preferably copy it to '/opt' before running."

# Set up Godot .NET
# Alternatively, you can run "flatpak install flathub org.godotengine.GodotSharp $FLATPAK_TYPE -y"
GODOT_VER=$(get_latest_github_release "godotengine/godot")
GODOT_ZIP="Godot_v${GODOT_VER}_mono_linux_x86_64.zip"

echo $GODOT_ZIP
echo $GODOT_VER

mkdir -p ~/Applications/Godot
wget -O ~/Applications/Godot/$GODOT_ZIP https://github.com/godotengine/godot/releases/download/$GODOT_VER/$GODOT_ZIP
wget -O ~/Applications/Godot/Icon.svg https://godotengine.org/assets/press/icon_color.svg
unzip ~/Applications/Godot/$GODOT_ZIP -d ~/Applications/Godot
mv ~/Applications/Godot/Godot_v${GODOT_VER}_mono_linux_x86_64/* ~/Applications/Godot
sudo rm -rf ~/Applications/Godot/Godot_v${GODOT_VER}_mono_linux_x86_64/ ~/Applications/Godot/$GODOT_ZIP
mv ~/Applications/Godot/Godot_v${GODOT_VER}_mono_linux.x86_64 ~/Applications/Godot/Godot

# Install Epic Asset Manager (For Unreal Engine)
flatpak install flathub io.github.achetagames.epic_asset_manager $FLATPAK_TYPE -y

# Install Docker alongside setting up DockStation.
sudo dnf install dnf-plugins-core -y
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y
sudo groupadd docker && sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
sudo systemctl enable docker && sudo systemctl start docker
wget -O ~/Applications/Dockstation.AppImage https://github.com/DockStation/dockstation/releases/download/v1.5.1/dockstation-1.5.1-x86_64.AppImage

# Install Distrobox and Podman (So Distrobox doesn't use Docker instead).
sudo dnf install podman distrobox -y

# Install MinGW64, CMake, Ninja Build
sudo dnf install mingw64-\* cmake ninja-build -y --skip-broken
sudo dnf remove mingw64-libgsf -y # This is just in case we want to install the gnome desktop via 'dnf group install -y "GNOME Desktop Environment"'.

# Install Ghidra.
flatpak install flathub org.ghidra_sre.Ghidra $FLATPAK_TYPE -y && sudo flatpak override org.ghidra_sre.Ghidra --filesystem=/mnt

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

# Install Ruby alongside some Gems.
sudo dnf install ruby ruby-devel rubygem-\* --skip-broken -y

# Install Python 2.
sudo dnf install python2 -y

# Install Rust. Alternatively, you can run this: "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh".
sudo dnf install rust -y

## ///// VIRTUALIZATION /////

# Install tools for .VHD/.VHDX mounting.
sudo dnf install libguestfs-tools -y

# Set up Virtualization Tools.
if grep -Eq 'vmx|svm' /proc/cpuinfo; then
    echo "Virtualization is enabled. Setting up virtualization packages."
    # Installs Virtual Machine related packages, alongside downloading the current stable VirtIO Guest Driver ISO.
    sudo dnf -y group install Virtualization -y
    wget -O ~/Downloads/virtio-win.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

    # Set up Cockpit for Virtual Machines (As Virt-Manager is now discontinued).
    sudo dnf install cockpit cockpit-machines -y
    sudo systemctl enable --now cockpit.socket
    sudo firewall-cmd --add-service=cockpit && sudo firewall-cmd --add-service=cockpit --permanent
    # Connect to cockpit with https://localhost:9090

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

 	# Stops our Plasma session on Wayland before stopping the display manager.
 	# systemctl --user -M $USER@ stop plasma* # This line may need to be changed from $USER to a hardcoded username to work properly.

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
 	# mkdir ~/.local/share/libvirt
	# wget -O ~/.local/share/libvirt/GPU.rom https://www.techpowerup.com/vgabios/230897/Asus.RX6700XT.12288.210301.rom
	# sudo chmod -R 660 ~/.local/share/libvirt/GPU.rom && sudo chown $(whoami):$(whoami) ~/.local/share/libvirt/GPU.rom

    # Finally restart the Libvirt service.
    sudo systemctl restart libvirtd.service
else
    echo "Virtualization is not enabled. Skipping."
fi

## ///// ANDROID APP COMPATIBILITY /////
sudo dnf install waydroid android-tools -y
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
# Some tweaks for stuff like USB controller support or stuff that requires a WiFi connection.
waydroid prop set persist.waydroid.udev true
waydroid prop set persist.waydroid.uevent true
waydroid prop set persist.waydroid.fake_wifi true
echo "Make sure to run 'sudo waydroid shell' followed by the command listed here: https://docs.waydro.id/faq/google-play-certification"
cd ..

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
    flatpak install flathub org.blender.Blender $FLATPAK_TYPE -y
    flatpak install flathub org.kde.kdenlive $FLATPAK_TYPE -y
    ;;
esac

# TODO: Add Dracut regeneration just in case the AMD GPU Switcher drivers have been installed on Nobara.

flatpak install flathub org.kde.krita $FLATPAK_TYPE -y
flatpak install flathub org.gimp.GIMP $FLATPAK_TYPE -y
flatpak install flathub org.inkscape.Inkscape $FLATPAK_TYPE -y
flatpak install flathub org.audacityteam.Audacity $FLATPAK_TYPE -y

## ///// AI STUFF /////

# Install Python 3.10 and pip.
sudo dnf install python3.10 -y
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# Install the needed ROCM runtimes on AMD (As shown here: https://medium.com/@anvesh.jhuboo/rocm-pytorch-on-fedora-51224563e5be).
# TODO: Add the rest of the setup instructions, PyTorch was just giving me issues.
case $NAME in
    ("Fedora")
    sudo dnf install rocm-opencl rocm-hip rocm-runtime  -y
    ;;
    ("Nobara Linux")
    sudo dnf install rocm-meta -y
    ;;
esac
sudo dnf install rocm-smi rocm-clinfo -y

# Set up a Fedora specific section for ROCM setup. (As shown here: https://medium.com/@anvesh.jhuboo/rocm-pytorch-on-fedora-51224563e5be).
sudo usermod -a -G video $LOGNAME

# Add a fix for PyTorch crashing on Navi 2 (AMD Radeon RX 6000) GPUs.
echo -e "\n# Fix Segmentation Fault Error for PyTorch\nexport HSA_OVERRIDE_GFX_VERSION=10.3.0" >> ~/.profile

# Set up PyTorch
python3.10 -m pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm5.6
echo "Make sure to change the 'python_cmd=' section of the stable-diffusion-webui's 'webui.sh' file to 'python3.10' instead of 'python3'."

## ///// GENERAL DESKTOP USAGE /////

# Set Wayland as the default SDDM Greeter, so we can actually see the login splash screen.
#echo "DisplayServer=wayland" | sudo tee -a /etc/sddm.conf > /dev/null

# Set up Timeshift for system backups.
case $NAME in
    ("Fedora")
    sudo dnf install timeshift -y
    ;;
esac

# Install the tiled window management KWin plugin, Bismuth.
sudo dnf install bismuth qt -y

# Add KDE Rounded Corners plugin, and then add updated desktop effects config.
sudo dnf install git cmake gcc-c++ extra-cmake-modules qt5-qttools-devel qt5-qttools-static qt5-qtx11extras-devel kf5-kconfigwidgets-devel kf5-kcrash-devel kf5-kguiaddons-devel kf5-kglobalaccel-devel kf5-kio-devel kf5-ki18n-devel kwin-devel qt5-qtbase-devel libepoxy-devel -y
git clone --branch disable-when-maximized https://github.com/matinlotfali/KDE-Rounded-Corners/
cd KDE-Rounded-Corners
mkdir build
cd build
cmake .. --install-prefix /usr
make
sudo make install
cd .. && cd .. && sudo rm -rf KDE-Rounded-Corners

# Use Librewolf instead of Firefox. We also need to reinstall the Plasma Browser Integration after Firefox is removed.
sudo dnf config-manager --add-repo https://rpm.librewolf.net/librewolf-repo.repo
sudo dnf install librewolf -y && sudo dnf remove firefox -y && sudo dnf install plasma-browser-integration -y
# I don't know why this is required to use Librewolf on Wayland without shitting itself, but here we are.
mkdir -p ~/.config/environment.d && echo 'MOZ_ENABLE_WAYLAND=1' >> ~/.config/environment.d/envvars.conf

# Install Microsoft Edge as a secondary web browser.
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo dnf install microsoft-edge-stable -y

# Install Vivaldi as a tertiary web browser. Finally, a Flatpak version!
flatpak install flathub com.vivaldi.Vivaldi $FLATPAK_TYPE -y

# Install Warpinator for file transfers.
flatpak install flathub org.x.Warpinator $FLATPAK_TYPE -y

# Install the BETTER partition manager and a disk space utility.
sudo dnf install gnome-disk-utility filelight -y

# Remove some KDE Plasma bloatware that comes installed for some reason.
sudo dnf remove libreoffice-\* akregator ksysguard dnfdragora kfind kmag kmail kcolorchooser kmouth korganizer kmousetool kruler kaddressbook kcharselect konversation elisa-player kmahjongg kpat kmines dragonplayer kamoso kolourpaint krdc krfb -y

# Remove KWrite in favor of Kate.
sudo dnf remove kwrite -y && sudo dnf install kate -y

# Install Input-Remapper (For Razer Tartarus Pro)
sudo dnf install input-remapper -y
sudo systemctl enable --now input-remapper && sudo systemctl start input-remapper

# Install Wallpaper Engine KDE Plugin
sudo dnf copr enable kylegospo/wallpaper-engine-kde-plugin -y && sudo dnf install wallpaper-engine-kde-plugin -y

# Set up BetterDiscord.
sudo dnf copr enable observeroftime/betterdiscordctl -y && sudo dnf install betterdiscordctl -y

case $NAME in
    ("Fedora") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    # Install and set up OpenRGB.
    sudo modprobe i2c-dev && sudo modprobe i2c-piix4 && sudo dnf install openrgb -y
    sudo udevadm control --reload-rules && sudo udevadm trigger
    sudo grubby --update-kernel=ALL --args="acpi_enforce_resources=lax"
    sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg

    # Install Discord (Nobara has it's own version, so that goes here).
    flatpak install flathub com.discordapp.Discord $FLATPAK_TYPE -y
    betterdiscordctl --d-install flatpak install

    # Enable support for flatpak Discord to use Discord Rich Presence for non-sandboxed applications.
    mkdir -p ~/.config/user-tmpfiles.d
    echo 'L %t/discord-ipc-0 - - - - app/com.discordapp.Discord/discord-ipc-0' > ~/.config/user-tmpfiles.d/discord-rpc.conf
    systemctl --user enable --now systemd-tmpfiles-setup.service
    ;;
    ("Nobara Linux")
    betterdiscordctl install
    ;;
esac

# Set up Discord Overlay of sorts (https://github.com/trigg/Discover)
sudo dnf copr enable mavit/discover-overlay -y
sudo dnf install discover-overlay gtk-layer-shell gtk-layer-shell-devel -y

# Some AppImage stuff (An AppImage Integrator and Updater)
sudo dnf install https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm -y
wget -O ~/Applications/AppImageUpdate.AppImage https://github.com/AppImageCommunity/AppImageUpdate/releases/download/2.0.0-alpha-1-20230526/AppImageUpdate-x86_64.AppImage

# Install CoreCtrl for CPU power management purposes.
sudo dnf install corectrl -y
cp /usr/share/applications/org.corectrl.corectrl.desktop ~/.config/autostart/org.corectrl.corectrl.desktop
sudo grubby --update-kernel=ALL --args="amdgpu.ppfeaturemask=0xffffffff"
sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg

# Run CoreCtrl without root password.
echo 'polkit.addRule(function(action, subject) {
    if ((action.id == "org.corectrl.helper.init" ||
         action.id == "org.corectrl.helperkiller.init") &&
        subject.local == true &&
        subject.active == true &&
        subject.isInGroup("wheel")) {
            return polkit.Result.YES;
    }
});' | sudo tee /etc/polkit-1/rules.d/90-corectrl.rules

# Add the AMD P-States driver instead of the built-in power management.
# NOTE: Nothing needs to be done on Intel CPUs, their P-State driver is already enabled by default on recent Linux kernel versions.
# Seemingly the grubby command isn't working, so we just need to find a way to add the needed parameters to "/etc/default/grub". Same goes for the VM parameters and parameters for corectrl.
cpu_vendor=$(grep -m 1 vendor_id /proc/cpuinfo | cut -d ":" -f 2 | tr -d '[:space:]')
if [ "$cpu_vendor" = "AuthenticAMD" ]; then
    sudo grubby --update-kernel=ALL --args="blacklist_module=acpi_cpufreq initcall_blacklist=acpi_cpufreq_init amd_pstate.shared_mem=1 amd_pstate.enable=1 amd_pstate=passive"
    sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg
fi

# Install some Flatpaks that I personally use.
flatpak install flathub com.spotify.Client $FLATPAK_TYPE -y

# Install an email client.
case $XDG_CURRENT_DESKTOP in
    ("KDE")
    sudo dnf install kmail -y
    ;;
    ("gnome")
    sudo dnf install geary -y
esac

# Install a Torrent client.
sudo dnf install qbittorrent -y

# Install and Setup OneDrive alongside OneDrive GUI for a GUI interface.
sudo dnf install onedrive -y && sudo systemctl stop onedrive@$USER.service && sudo systemctl disable onedrive@$USER.service && systemctl --user enable onedrive && systemctl --user start onedrive
ONEDRIVEGUI_VER=$(get_latest_github_release "bpozdena/OneDriveGUI" | sed 's/v//')
ONEDRIVEGUI_APPIMAGE="OneDriveGUI-${ONEDRIVEGUI_VER}-x86_64.AppImage"
echo $ONEDRIVEGUI_APPIMAGE
echo $ONEDRIVEGUI_VER
wget -O ~/Applications/$ONEDRIVEGUI_APPIMAGE https://github.com/bpozdena/OneDriveGUI/releases/download/v$ONEDRIVEGUI_VER/$ONEDRIVEGUI_APPIMAGE
echo "Make sure to run AppImageLauncher at least once, to get it to recognize the AppImage for OneDriveGUI. Afterwards, synchronize your account, and add a login application startup for the OneDrive GUI.".

# Install Mullvad VPN.
sudo dnf install https://mullvad.net/media/app/MullvadVPN-2023.3_x86_64.rpm -y

# Install ProtonVPN. NOTE: This does not currently work with Fedora 39's Beta for some reason.
sudo dnf install https://repo.protonvpn.com/fedora-38-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.1-2.noarch.rpm -y
sudo dnf check-update && sudo dnf upgrade -y
sudo dnf install --refresh proton-vpn-gnome-desktop -y

# Set up OnlyOffice.
flatpak install flathub org.onlyoffice.desktopeditors $FLATPAK_TYPE -y

## ///// DPI SCALING RELATED STUFF /////
# ~/.local/share/kscreen has a config file that can tell you the refresh rate and DPI scale of the current display. There probably is a better way of doing this in Wayland, but I'd need to find a way to allow updating of the scale for these applications, since Steam's DPI scaling on KDE is still busted for some reason.

# A config tweak for having a 1.3x scale for Spotify. Seemingly it doesn't allow double digits after the whole number, so we have to round down from 1.35 to 1.3.
# As shown here: https://justincaustin.com/blog/spotify-flatpak-hidpi-scaling/
#sudo sed -i 's/flatpak run --branch=stable --arch=x86_64 --command=spotify --file-forwarding com.spotify.Client /&--force-device-scale-factor=1.3 /' /var/lib/flatpak/app/com.spotify.Client/current/active/export/share/applications/com.spotify.Client.desktop
#sudo update-desktop-database

# A quick and easy way of forcing the DPI scaling of Steam to a specific scale. Uncomment and replace 1.35 with your desired DPI scale
# cp /usr/share/applications/steam.desktop ~/.local/share/applications
# awk '/^\[Desktop Entry\]/{flag=1} flag && /^Exec=/{sub(/^Exec=/, "Exec=STEAM_FORCE_DESKTOPUI_SCALING=1.35 ", $0); flag=0} 1' ~/.local/share/applications/steam.desktop > temp_file && mv temp_file ~/.local/share/applications/steam.desktop

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

# Install FFMPEG with Nobara, as that's already handled with Fedora, and doing it conflicts with our freeworld drivers.
case $NAME in
    ("Nobara Linux")
    sudo dnf install ffmpeg -y
    ;;
esac

# Install YT-DLP
sudo dnf install yt-dlp -y

# Install FFMPEG for Flatpak.
flatpak install flathub org.freedesktop.Platform.ffmpeg-full $FLATPAK_TYPE -y

# Install Better Fonts.
sudo dnf copr enable dawid/better_fonts -y && sudo dnf install fontconfig-font-replacements -y --skip-broken && sudo dnf install fontconfig-enhanced-defaults -y --skip-broken

# Install FontAwesome Fonts.
sudo dnf install fontawesome-fonts fontawesome5-brands-fonts -y

# Install Microsoft Fonts.
sudo dnf install curl cabextract xorg-x11-font-utils fontconfig -y
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
# Some other Microsoft fonts not included with msttcore-fonts. You may need to restart your PC for the fonts to appear.
wget -q -O - https://gist.githubusercontent.com/Blastoise/72e10b8af5ca359772ee64b6dba33c91/raw/2d7ab3caa27faa61beca9fbf7d3aca6ce9a25916/clearType.sh | bash
wget -q -O - https://gist.githubusercontent.com/Blastoise/b74e06f739610c4a867cf94b27637a56/raw/96926e732a38d3da860624114990121d71c08ea1/tahoma.sh | bash
wget -q -O - https://gist.githubusercontent.com/Blastoise/64ba4acc55047a53b680c1b3072dd985/raw/6bdf69384da4783cc6dafcb51d281cb3ddcb7ca0/segoeUI.sh | bash
wget -q -O - https://gist.githubusercontent.com/Blastoise/d959d3196fb3937b36969013d96740e0/raw/429d8882b7c34e5dbd7b9cbc9d0079de5bd9e3aa/otherFonts.sh | bash

# Set up Google Fonts.
wget -O ~/.fonts/google-fonts.zip https://github.com/google/fonts/archive/master.zip
mkdir ~/.fonts/Google && unzip -d ~/.fonts/Google ~/.fonts/google-fonts.zip

# Finally updates our Font Cache.
sudo fc-cache -fv

## Add nerd-fonts for Noto and SourceCodePro font families. This will just install everything together, but I give no fucks at this point, just want things a little easier to set up.
git clone https://github.com/ryanoasis/nerd-fonts.git && cd nerd-fonts && ./install.sh && cd .. && sudo rm -rf nerd-fonts

# ///// TPM AUTOMATIC SYSTEM PARTITION DECRYPTION (NEW METHOD). Commented out for now because I need to iron something out with how the TPM key isn't being used. /////
#sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p3 # First we should probably remove any keys that exist in the TPM. Feel free to remove this if you like.
#sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+1+2+3+4+5+7+8 /dev/nvme0n1p3
# Next, we need to grab the Partition UUID for our LUKS partition.
#partuuid=$(sudo blkid /dev/nvme0n1p3 | grep -o 'PARTUUID="[^"]*' | cut -d'"' -f2 | tr '[:lower:]' '[:upper:]')
## echo "$partuuid" >> ~/test.txt # Simple test to see if this works
#echo 'root  UUID=$partuuid  none  tpm2-device=auto' | sudo tee -a /etc/crypttab.initramfs # As shown here (https://wiki.archlinux.org/title/Dm-crypt/System_configuration#Trusted_Platform_Module_and_FIDO2_keys)
#echo 'add_dracutmodules+=" tpm2-tss "' | sudo tee -a /etc/dracut.conf.d/tpm2-tss.conf # As shown here (https://wiki.archlinux.org/title/User:Krin/Secure_Boot,_full_disk_encryption,_and_TPM2_unlocking_install#Enrollment)
#sudo dracut --regenerate-all --force # Regenerate the initramfs with TPM decryption.
# NOTE: Figure out the problem with the dracut regeneration. It's saying "/etc/dracut.conf.d/cmdline.conf: line 1: rd.luks.options=30cad45d-0223-4ff0-a6d0-fe0d8e0f3098=tpm2-device=auto: command not found", despite the dependencies clearly being installed.

# ///// GRUB BOOTLOADER MODIFICATIONS /////
# Adjust GRUB bootloader settings to only show the menu if I hold shift, and to reduce the countdown timer from 5 to 3 for a quicker boot.
new_timeout=3
# Check if GRUB_TIMEOUT exists in the configuration file, and if it does, replace its value with the new_timeout. If not, add it to the end of the file.
if grep -q '^GRUB_TIMEOUT=' /etc/default/grub; then
    sudo sed -Ei "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$new_timeout/" /etc/default/grub
else
    sudo sed -i "$ a GRUB_TIMEOUT=$new_timeout" /etc/default/grub
fi
# Check if GRUB_TIMEOUT_STYLE exists in the configuration file, and if it does, replace its value with "hidden". If not, add it to the end of the file.
if grep -q '^GRUB_TIMEOUT_STYLE=' /etc/default/grub; then
    sudo sed -Ei 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
else
    sudo sed -i "$ a GRUB_TIMEOUT_STYLE=hidden" /etc/default/grub
fi
sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg
