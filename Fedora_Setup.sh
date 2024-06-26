#!/bin/bash
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
    ("Fedora Linux") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    echo "Fedora is being used."
    FLATPAK_TYPE=""
    ;;
    (*)
    echo "Unsupported Distro is being used. Exiting"
    exit
    ;;
esac

current_dir=$(pwd)

## ///// THE ABSOLUTE BASICS /////

# Automatically Configure DNF to be a bit faster, and gives the changes a test drive.
sudo bash -c 'echo -e "max_parallel_downloads=10\ndefaultyes=True\nfastestmirror=True" >> /etc/dnf/dnf.conf'
sudo dnf update -y

case $NAME in
    ("Nobara Linux")
    echo "Nobara is being used."

    # Safely remove something that causes "kde-settings conflicts with f[version]-backgrounds-kde"
    sudo rpm -e --nodeps f$(rpm -E %fedora)-backgrounds-kde
    ;;
    ("Fedora Linux") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    echo "Fedora is being used."

    # Install third-party repositories (Via RPMFusion).
    sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
    sudo dnf group update core -y

    # Enable Flatpaks.
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    # Remove any Fedora remote flatpak, and swap it out for the flathub equivalent. Then delete the Fedora flatpak remote, since we really dont need it.
    installed_flatpaks=$(flatpak list --app --columns=application,origin)
    fedora_flatpaks=$(echo "$installed_flatpaks" | grep fedora | awk '{print $1}')
    for app in $fedora_flatpaks; do
        # Uninstall the Fedora Flatpak
        flatpak uninstall -y $app
        
        # Install the Flatpak from Flathub
        flatpak install -y flathub $app
    done
    flatpak remote-delete fedora
    ;;
esac


## ///// CARGO AND REBOS SETUP ////
# Install Rust alongside some necessary dependencies.
sudo yum groupinstall 'Development Tools' -y
sudo dnf install rustup -y
rustup-init && source "$HOME/.cargo/env"
# NOTE: You should run "source "$HOME/.cargo/env"" with every new terminal you use.

#Install Rebos (For System repeatability, similar to NixOS).
cargo install rebos
# Install our packages through rebos instead, before doing any other configuration.
rebos setup
rebos config init
cp -rf ./Configs/.config/rebos/ ~/.config/rebos/ # TODO: Fix this fucking command.
rebos gen commit initial_commit && rebos gen current to-latest && rebos gen current build

# Enable System Theming with Flatpak (That way, theming is more consistent between native apps and flatpaks).
sudo flatpak override --filesystem=xdg-config/gtk-3.0

# Enable mouse Cursors and Icons in Flatpak (That way, your mouse cursor is shown properly).
sudo flatpak override --filesystem=/usr/share/icons/:ro
sudo flatpak override --filesystem=/usr/share/themes/:ro
sudo flatpak override --filesystem=$HOME/.themes:ro
sudo flatpak override --filesystem=$HOME/.icons:ro
sudo flatpak override --filesystem=$HOME/.local/share/themes:ro
sudo flatpak override --filesystem=$HOME/.local/share/.icons:ro
sudo flatpak override --filesystem=xdg-config/gtk-4.0

# Set up all Flatpaks to use our own MangoHUD config from GOverlay.
sudo flatpak override --filesystem=xdg-config/MangoHud:ro
# Set up Gamemode override for MangoHUD Flatpak.
flatpak override --user --talk-name=com.feralinteractive.GameMode

# Set up Homebrew Package Manager
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

# Set up fastfetch with my preferred configuration.
mkdir ~/.config/fastfetch
cp ./Configs/.config/fastfetch/config.conf  ~/.config/fastfetch/config.conf

# Install oh-my-bash alongside changing the default theme.
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
sed -i 's/OSH_THEME="font"/OSH_THEME="agnoster"/g' ~/.bashrc

# Set up Powershell.
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
sudo dnf update && sudo dnf install powershell -y

# Install oh-my-posh for Powershell.
curl -s https://ohmyposh.dev/install.sh | sudo bash -s
# Downloads our custom powershell profile.
cp ./Configs/.config/powershell/Microsoft.PowerShell_profile.ps1 ~/.config/powershell/Microsoft.Powershell_profile.ps1

# Set up zsh as the default, alongside setting up oh-my-zsh, and powerlevel10k.
chsh -s $(which zsh) && sudo chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"c
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Set up Powerlevel10k as the default zsh theme, alongside enabling some tweaks.
sed -i 's|ZSH_THEME="robbyrussell"|ZSH_THEME="powerlevel10k/powerlevel10k"|g' ~/.zshrc
echo '# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc
echo "typeset -g POWERLEVEL9K_INSTANT_PROMPT=off" >> tee -a ~/.zshrc

# Set up some ZSH plugins.
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
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

# Set up NvChad (For Neovim).
git clone https://github.com/NvChad/starter ~/.config/nvim
echo "Run 'nvim' when you are ready."

## ///// GAMING AND GAMING TWEAKS /////

case $NAME in
    ("Fedora Linux") # This is for Fedora specific stuff that can safely be ignored with Nobara.

    # Temporary workaround for Fedora (So, you can have MangoApp working). When the fuck is MangoApp gonna work through compiling from source?
    #sudo dnf install --allowerasing https://download.copr.fedorainfracloud.org/results/gloriouseggroll/nobara/fedora-38-x86_64/06517212-mangohud/mangohud-0.7.0-6.fc38.x86_64.rpm https://download.copr.fedorainfracloud.org/results/gloriouseggroll/nobara/fedora-38-i386/06517212-mangohud/mangohud-0.7.0-6.fc38.i686.rpm -y

    # Enable the gamemode service.
    systemctl --user enable gamemoded.service && systemctl --user start gamemoded.service
    
    case $XDG_CURRENT_DESKTOP in
    ("gnome")
    sudo dnf install gnome-shell-extension-gamemode -y
    ;;
    esac

    ;;
esac

# Add Gamescope Session and Steam Deck Gyro DSU for Switch/WiiU emulation.
case $NAME in
    ("Fedora Linux")
    # Setup Gamescope Session.
    #git clone https://github.com/ChimeraOS/gamescope-session --recursive
    #git clone https://github.com/ChimeraOS/gamescope-session-steam --recursive
    #cd gamescope-session && sudo cp -r usr/* /usr
    #cd ..
    #cd gamescope-session-steam && sudo cp -r usr/* /usr
    #cd ..
    #sudo rm -rf gamescope-session gamescope-session-steam
    #sudo rm -rf /usr/share/wayland-sessions/gamescope-session.desktop
    ## Set up SteamDeckGyroDSU.
    #bash <(curl -sL https://raw.githubusercontent.com/kmicki/SteamDeckGyroDSU/master/pkg/update.sh)
    ;;
    ("Nobara Linux") # This is for Fedora specific stuff that can safely be ignored with Fedora.
    sudo dnf install sdgyrodsu gamescope-session jupiter-hw-support jupiter-fan-control -y
    ;;
esac

# TODO: Add Nobara's Gamescope Session here. Note: To prevent Steam from starting up without DPI Scaling or anything, run "sudo rm -rf /etc/xdg/autostart/steam.desktop".

# Improve Steam Download Speed (This is a tweak from Bazzite).
mkdir -p $HOME/.local/share/Steam
rm -f $HOME/.local/share/Steam/steam_dev.cfg
bash -c 'printf "@nClientDownloadEnableHTTP2PlatformLinux 0\n@fDownloadRateImprovementToAddAnotherConnection 1.0\n" > $HOME/.local/share/Steam/steam_dev.cfg'

# Set up Decky Loader for Steam.
curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh

# Fix the launching bug with Steam on Wayland when dealing with a dGPU+iGPU setup.
cp /usr/share/applications/steam.desktop ~/.local/share/applications/steam.desktop
sed -i '/PrefersNonDefaultGPU=true/d' ~/.local/share/applications/steam.desktop && sed -i '/X-KDE-RunOnDiscreteGpu=true/d' ~/.local/share/applications/steam.desktop

# Install some game launcher and emulator Flatpaks.
flatpak remote-add --if-not-exists --user launcher.moe https://gol.launcher.moe/gol.launcher.moe.flatpakrepo
flatpak install launcher.moe moe.launcher.an-anime-game-launcher --user -y
flatpak install launcher.moe moe.launcher.the-honkers-railway-launcher --user -y
flatpak install launcher.moe moe.launcher.honkers-launcher --user -y

# Install a Soundboard Application, for micspamming in Team Fortress 2 servers, of course! ;-)
sudo dnf copr enable rivenirvana/soundux -y && sudo dnf install soundux pipewire-devel -y --allowerasing

# Set up Heroic with Wayland support.
flatpak override --user --socket=wayland com.heroicgameslauncher.hgl

# Set up Sunshine and Moonlight Streaming.
#sudo dnf install https://github.com/LizardByte/Sunshine/releases/download/v0.20.0/sunshine-fedora-$(rpm -E %fedora)-amd64.rpm -y
#echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' | \
#sudo tee /etc/udev/rules.d/85-sunshine.rules
#systemctl --user enable sunshine
#sudo setcap cap_sys_admin+p $(readlink -f $(which sunshine))

# Fix DualSense pairing over Bluetooth. The Arch Wiki says that this is the only fix, but I could've sworn I paired before w/o this.
#input_conf="/etc/bluetooth/input.conf"
#userspace_hid="UserspaceHID=true"
#if [ -f "$input_conf" ]; then
    ## If file exists, add or modify the line UserspaceHID=true
    #if ! grep -qF "$userspace_hid" "$input_conf"; then
        #echo "$userspace_hid" | sudo tee -a "$input_conf" > /dev/null
    #fi
#else
    ## If file doesn't exist, create it and add UserspaceHID=true
    #echo "$userspace_hid" | sudo tee "$input_conf" > /dev/null
#fi

# Disable the DualSense trackpad in desktop mode (This apparently works under X11, I don't know about Wayland).
#echo 'Section "InputClass"
    #Identifier "Sony Interactive Entertainment Wireless Controller Touchpad"
    #Driver "libinput"
    #MatchIsTouchpad "on"
    #Option "Ignore" "true"
#EndSection' | sudo tee -a /etc/X11/xorg.conf.d/30--dualsense-touchpad.conf

# Set up HIDDualShock Module on system startup, to prevent touchpad issues.
printf "# load this module at boot time as otherwise the DS4 and DualSense controllers have issues\nhid_playstation\n" | sudo tee /etc/modules-load.d/hid-playstation.conf > /dev/null

# Install XPadNeo drivers for Xbox controllers.
case $NAME in
    ("Fedora Linux")
    #sudo dnf copr enable sentry/xpadneo -y && sudo dnf install xpadneo -y
    ;;
esac

# Do some user permission stuff, so we don't have to dick with reinstalling the Xbox drivers through Nobara's setup GUI after a restart
sudo usermod -a -G pkg-build $USER

## ///// WINE AND WINDOWS SOFTWARE /////

case $NAME in
    ("Fedora Linux") # This is for Fedora specific stuff that can safely be ignored with Nobara.

    # Install Yabridge (For VST Plugins, I'm going to assume you will set up a DAW on your own accords).
    #sudo dnf copr enable patrickl/yabridge -y && sudo dnf install yabridge yabridgectl --refresh -y

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
    #echo "If you plan to use Ableton Live (alongside some VST plugins like Serum), add gdiplus to winetricks for Ableton, disable the d2d1 library through winecfg, and then add vcruntime140_1.dll as an native+built-in override through winecfg".
    
    # Set our Wine Prefix to use ALSA audio, so it won't crash with WineASIO or other ASIO plugins.
    #WINEPREFIX=$HOME/.wine winetricks sound=alsa
    #WINEPREFIX=$HOME/.ableton winetricks sound=alsa
    ;;
    ("Nobara Linux") # Use the built-in version of Winetricks instead.
    # Open Explorer to initialize our Wine prefix.
    #echo "Initializing Wine prefix. Please exit out of Explorer when it opens and follow any setup prompts."
    #wine64 explorer
    # Set up some dependencies.
    #winetricks corefonts
    #winetricks dotnet48
    #winetricks mf
    #echo "If you plan to use Clip Studio, set concrt140 as a WineDLLOverride in winecfg to prevent crashing."
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
flatpak override com.usebottles.bottles --user --filesystem=xdg-data/applications

## //// NETWORKING STUFF /////

# Set up Samba
sudo systemctl enable smb nmb && sudo systemctl start smb nmb
case $XDG_CURRENT_DESKTOP in
    ("KDE") # Install the KDE Plasma extension for Samba Shares, alongside setting up the needed permissions.
    sudo groupadd sambashares && sudo usermod -a -G sambashares $USER
    sudo mkdir /var/lib/samba/usershares && sudo chgrp sambashares /var/lib/samba/usershares && sudo chown $USER:sambashares /var/lib/samba/usershares
    ;;
esac
sudo setsebool -P samba_enable_home_dirs=on
sudo smbpasswd -a $USER
# Unblock some Samba ports.
sudo firewall-cmd --zone=FedoraWorkstation --permanent --add-port=137/tcp
sudo firewall-cmd --zone=FedoraWorkstation --permanent --add-port=138/tcp
sudo firewall-cmd --zone=FedoraWorkstation --permanent --add-port=139/tcp
sudo firewall-cmd --zone=FedoraWorkstation --permanent --add-port=445/tcp
sudo firewall-cmd --reload

# Set up SSH Server on Host
sudo systemctl enable sshd && sudo systemctl start sshd

# NOTE: You can actually transfer your SSH keys to a server hosting something like Libvirt, so you can remote connect to it using virt-manager. Here's how you do that:
#ssh-keygen -t rsa
#ssh-copy-id -i ~/.ssh/id_rsa.pub USERNAME@LOCALIP

# Disable NetworkManager Wait Service (due to long boot times) if using a desktop. Assuming this based on if a battery is available.
if [ -f /sys/class/power_supply/BAT1/uevent ]
    then echo "Battery is available. Skipping disabling the NetworkManager Wait Service."
else sudo systemctl disable NetworkManager-wait-online.service
fi

# If you want to use an eGPU over USB 4 on AMD laptops, you can add "pcie_aspm=off" to your GRUB boot parameters.

## ///// DEVELOPMENT/PROGRAMMING TOOLS AND GAME ENGINE STUFF /////

# Install RenderDoc and Vulkan Tools.
sudo dnf copr enable kb1000/renderdoc -y
sudo dnf install renderdoc -y && sudo dnf install vulkan-tools -y

# Set up Unity Hub and Jetbrains
sudo sh -c 'echo -e "[unityhub]\nname=Unity Hub\nbaseurl=https://hub.unesac
sudo setsebool -P samba_enable_home_dirs=onity3d.com/linux/repos/rpm/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://hub.unity3d.com/linux/repos/rpm/stable/repodata/repomd.xml.key\nrepo_gpgcheck=1" > /etc/yum.repos.d/unityhub.repo' && sudo dnf update && sudo dnf install unityhub -y && sudo dnf install GConf2 -y
mkdir $HOME/Applications && cd $HOME/Applications && wget -O jetbrains-toolbox.tar.gz https://download.jetbrains.com/toolbox/jetbrains-toolbox-1.24.11947.tar.gz && tar xvzf jetbrains-toolbox.tar.gz && cd .. && echo "Make sure to remove the 'jetbrains-toolbox' executable from the extracted folder before running! Preferably copy it to '/opt' before running."
cd $current_dir

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
wget https://github.com/godotengine/FBX2glTF/releases/latest/download/FBX2glTF-linux-x86_64.zip
unzip FBX2glTF-linux-x86_64.zip -d ~/Applications/Godot
mv ~/Applications/Godot/FBX2glTF-linux-x86_64/FBX2glTF-linux-x86_64 ~/Applications/Godot/FBX2glTF
sudo rm -rf ~/Applications/Godot/FBX2glTF-linux-x86_64/
cd $current_dir

# Install Docker alongside setting up Docker Desktop.
sudo dnf install dnf-plugins-core -y
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y --allowerasing
sudo groupadd docker && sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
sudo systemctl enable docker && sudo systemctl start docker
sudo dnf install https://desktop.docker.com/linux/main/amd64/149282/docker-desktop-4.30.0-x86_64.rpm -y
echo "Please visit this page for more information on how to sign into Docker Desktop: https://docs.docker.com/desktop/get-started/#credentials-management-for-linux-users"

# Set up some necessary stuff for Distrobox to run GUI applications (X11 apps getting forwarded to XWayland).
## Check if the file ~/.distroboxrc exists, if not create it
[ -f ~/.distroboxrc ] || touch ~/.distroboxrc
## Check if the line is already present in the file, if not append it
grep -qxF 'xhost +si:localuser:$USER >/dev/null' ~/.distroboxrc || echo 'xhost +si:localuser:$USER >/dev/null' >> ~/.distroboxrc

# Install MinGW64, CMake, Ninja Build
sudo dnf install mingw64-\* cmake ninja-build -y --exclude=mingw64-libgsf --skip-broken
sudo dnf remove mingw64-libgsf -y # This is just in case we want to install the gnome desktop via 'dnf group install -y "GNOME Desktop Environment"'.

# Set up Ghidra.
sudo flatpak override org.ghidra_sre.Ghidra --filesystem=/mnt

# Install Visual Studio Code.
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' && sudo dnf check-update && sudo dnf install code -y
## Set up Visual Studio Code to work with Wayland.
cp $current_dir/Configs/.config/code-flags.conf ~/.config/code-flags.conf

# Install .NET Runtime/SDK and Mono (for Rider and C# applications)
sudo dnf install dotnet-sdk-6.0 dotnet-sdk-7.0 dotnet-sdk-8.0 mono-devel -y

# Install Java
sudo dnf install java -y

# Install Ruby alongside some Gems.
sudo dnf install ruby ruby-devel rubygem-\* --skip-broken -y

# Install Python 2.
sudo dnf install python2 -y

## ///// VIRTUALIZATION /////

# Install tools for .VHD/.VHDX mounting.
sudo dnf install libguestfs-tools -y

# Set up Virtualization Tools.
if grep -Eq 'vmx|svm' /proc/cpuinfo; then
    echo "Virtualization is enabled. Setting up virtualization packages."
    # Downloads the latest VirtIO Drivers for Windows.
    wget -O ~/Downloads/virtio-win.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

    # Set up Cockpit for Virtual Machines (As Virt-Manager is now discontinued).
    sudo systemctl enable --now cockpit.socket
    sudo firewall-cmd --add-service=cockpit && sudo firewall-cmd --add-service=cockpit --permanent
    # Connect to cockpit with https://localhost:9090

    # Set up GRUB Bootloader to use IOMMU based on the CPU type used
    cpu_vendor=$(grep -m 1 vendor_id /proc/cpuinfo | cut -d ":" -f 2 | tr -d '[:space:]')
    if [ "$cpu_vendor" = "GenuineIntel" ]; then
        echo "CPU vendor is Intel. Setting up Intel IOMMU boot parameters..."
        sudo grubby --update-kernel=ALL --args="intel_iommu=on iommu=pt"
        # If you want iGPU passthrough for some reason, you can add "i915.modeset=0" to the end of the intel parameters.
    elif [ "$cpu_vendor" = "AuthenticAMD" ]; then
        echo "CPU vendor is AMD. Setting up AMD IOMMU boot parameters..."
        sudo grubby --update-kernel=ALL --args="amd_iommu=on iommu=pt"
    else
        echo "Unknown CPU vendor. Skipping..."
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
 	# sudo mkdir /usr/share/vgabios
	# sudo wget -O /usr/share/vgabios/GPU.rom https://www.techpowerup.com/vgabios/230897/Asus.RX6700XT.12288.210301.rom
	# sudo chmod -R 775 /usr/share/vgabios/GPU.rom && sudo chown $(whoami):$(whoami) /usr/share/vgabios/GPU.rom

    # Finally restart the Libvirt service.
    sudo systemctl restart libvirtd.service
else
    echo "Virtualization is not enabled. Skipping."
fi

## ///// ANDROID APP COMPATIBILITY AND ANDROID DEV STUFF /////

# Add the plugdev group, alongside adding the current user to it.
sudo groupadd plugdev
sudo udevadm control --reload
sudo usermod -aG plugdev $USER

# Link the necessary file to get adb working, and then refreshes the rules.
sudo ln -s /usr/share/doc/android-tools/51-android.rules /etc/udev/rules.d
sudo udevadm control --reload-rules

# Set up Waydroid
sudo systemctl enable --now waydroid-container
sudo waydroid init -s GAPPS -r lineage -c https://ota.waydro.id/system -v https://ota.waydro.id/vendor

# Set up Waydroid-Settings app.
sudo dnf install gtk3 webkit2gtk4.0 vte291 -y
wget -O - https://raw.githubusercontent.com/axel358/Waydroid-Settings/main/install.sh | bash

# Set up Waydroid Scripts (For installing stuff like Widevine, Libhoudini, etc)
cd ~/
git clone https://github.com/casualsnek/waydroid_script
cd waydroid_script
sudo python3 -m pip install -r requirements.txt
sudo python3 ./main.py install magisk

## Set up Libhoudini or Libndk for Waydroid, alongside a patch to get games like Blue Archive running.
if [ "$cpu_vendor" = "GenuineIntel" ]; then
    echo "CPU vendor is Intel. Setting up Libhoudini..."
    sudo python3 ./main.py install libhoudini
    ## Set up some necessary patches required to run games like Blue Archive on Waydroid.
    sudo chmod +x "$current_dir/Optional Tweaks/BA_WaydroidPatch_Libhoudini.sh"
    sudo "$current_dir/Optional Tweaks/BA_WaydroidPatch_Libhoudini.sh"
elif [ "$cpu_vendor" = "AuthenticAMD" ]; then
    echo "CPU vendor is AMD. Setting up Libndk..."
    sudo python3 ./main.py install libndk
    ## Set up some necessary patches required to run games like Blue Archive on Waydroid.
    sudo chmod +x "$current_dir/Optional Tweaks/BA_WaydroidPatch_Libhoudini.sh"
    sudo "$current_dir/Optional Tweaks/BA_WaydroidPatch_Libndk.sh"
else
    echo "Unknown CPU vendor. Skipping..."
fi

sudo python3 ./main.py install widevine
# Some tweaks for stuff like USB controller support or stuff that requires a WiFi connection.
waydroid prop set persist.waydroid.udev true
waydroid prop set persist.waydroid.uevent true
waydroid prop set persist.waydroid.fake_wifi true
sudo firewall-cmd --zone=trusted --add-interface=waydroid0
# Try this if the other command doesn't work: sudo firewall-cmd --zone=FedoraWorkstation --add-interface=waydroid0
echo "Make sure to run 'sudo waydroid shell' followed by the command listed here: https://docs.waydro.id/faq/google-play-certification"
cd $current_dir

# Set up rclone (For stuff like OneDrive)
sudo dnf install rclone -y
# Now run rclone config.
mkdir ~/OneDrive
rclone --vfs-cache-mode writes mount "OneDrive":  ~/OneDrive

# Install Compatibility Related Stuff for Autodesk Maya and Mudbox.
sudo dnf copr enable dioni21/compat-openssl10 -y && sudo dnf install pcre-utf16 -y && sudo dnf install compat-openssl10 -y
sudo dnf install libpng15 csh audiofile libXp rocm-opencl5.4.3 -y
mkdir $HOME/maya
mkdir $HOME/maya/2024
echo -e "MAYA_OPENCL_IGNORE_DRIVER_VERSION=1\nMAYA_CM_DISABLE_ERROR_POPUPS=1\nMAYA_COLOR_MGT_NO_LOGGING=1\nTMPDIR=/tmp\nMAYA_NO_HOME=1" >> $HOME/maya/2023/Maya.env
echo "Please download and install Autodesk Maya on your own accord. The dependencies and compatibility tweaks for Fedora should be taken care of now."
echo -e "LD_LIBRARY_PATH="/usr/autodesk/mudbox2024/lib"" >> $HOME/.profile

## ///// AI STUFF /////

# Install Python 3.10 and pip.
#sudo dnf install python3.10 -y
#curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# Install the needed ROCM runtimes on AMD (As shown here: https://medium.com/@anvesh.jhuboo/rocm-pytorch-on-fedora-51224563e5be).
# TODO: Add the rest of the setup instructions, PyTorch was just giving me issues.

# Set up a Fedora specific section for ROCM setup. (As shown here: https://medium.com/@anvesh.jhuboo/rocm-pytorch-on-fedora-51224563e5be).
#sudo usermod -a -G video $LOGNAME

# Add a fix for PyTorch crashing on Navi 2 (AMD Radeon RX 6000) GPUs.
#echo -e "\n# Fix Segmentation Fault Error for PyTorch\nexport HSA_OVERRIDE_GFX_VERSION=10.3.0" >> ~/.profile

# Set up PyTorch
#python3.10 -m pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm5.6
#echo "Make sure to change the 'python_cmd=' section of the stable-diffusion-webui's 'webui.sh' file to 'python3.10' instead of 'python3'."

## ///// GENERAL DESKTOP USAGE /////

# Set Wayland as the default SDDM Greeter, so we can actually see the login splash screen.
#echo "DisplayServer=wayland" | sudo tee -a /etc/sddm.conf > /dev/null

# Install the tiled window management KWin plugin, Bismuth.
#sudo dnf install bismuth qt -y

# Add KDE Rounded Corners plugin, and then add updated desktop effects config.
sudo dnf install https://sourceforge.net/projects/kde-rounded-corners/files/nightly/fedora/kwin4_effect_shapecorners_fedora$(rpm -E %fedora).rpm -y

# Use Librewolf instead of Firefox. We also need to reinstall the Plasma Browser Integration after Firefox is removed.
sudo dnf config-manager --add-repo https://rpm.librewolf.net/librewolf-repo.repo
sudo dnf install librewolf -y && sudo dnf remove firefox -y && sudo dnf install plasma-browser-integration -y
# I don't know why this is required to use Librewolf on Wayland without shitting itself, but here we are.
mkdir -p ~/.config/environment.d && echo 'MOZ_ENABLE_WAYLAND=1' >> ~/.config/environment.d/envvars.conf

# Install Microsoft Edge as a secondary web browser.
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo dnf install microsoft-edge-stable -y

# Add webapp manager (So you can have things like Office 365 as dedicated web apps).
sudo dnf copr enable refi64/webapp-manager -y
sudo dnf install webapp-manager -y

# Remove some KDE Plasma bloatware that comes installed for some reason.
sudo dnf remove libreoffice-\* akregator ksysguard dnfdragora kfind kmag kmail kcolorchooser kmouth korganizer kmousetool kruler kaddressbook kcharselect konversation elisa-player kmahjongg kpat kmines dragonplayer kamoso kolourpaint krdc krfb digikam showfoto ktorrent k3b cdrdao -y

sudo dnf group remove "LibreOffice" -y

# Remove KWrite in favor of Kate.
sudo dnf swap kwrite kate -y

# Install Input-Remapper (For Razer Tartarus Pro)
sudo dnf install input-remapper -y
sudo systemctl enable --now input-remapper && sudo systemctl start input-remapper

# Install Wallpaper Engine KDE Plugin
# TODO: Remove the COPR, as it doesn't work on Plasma 6, and the qt6 one that's available online is missing libraries.
case $NAME in
    ("Fedora Linux")
    sudo dnf copr enable kylegospo/wallpaper-engine-kde-plugin -y && sudo dnf install wallpaper-engine-kde-plugin -y
    ;;
    ("Nobara Linux")
    sudo dnf install wallpaper-engine-kde-plugin -y
    ;;
esac

# Set up Obsidian (For Note-Taking).
flatpak override --user --socket=wayland md.obsidian.Obsidian

case $NAME in
    ("Fedora Linux") # This is for Fedora specific stuff that can safely be ignored with Nobara.
    # Install and set up OpenRGB.
    sudo usermod -a -G video $USER
    sudo modprobe i2c-dev && sudo modprobe i2c-piix4
    sudo udevadm control --reload-rules && sudo udevadm trigger
    sudo grubby --update-kernel=ALL --args="acpi_enforce_resources=lax"
    sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg

    # Enable support for flatpak Discord to use Discord Rich Presence for non-sandboxed applications.
    mkdir -p ~/.config/user-tmpfiles.d
    echo 'L %t/discord-ipc-0 - - - - app/com.discordapp.Discord/discord-ipc-0' > ~/.config/user-tmpfiles.d/discord-rpc.conf
    systemctl --user enable --now systemd-tmpfiles-setup.service
    sudo flatpak override --filesystem=/proc com.discordapp.Discord
    
    # Set up Wayland support.
    flatpak override --user --socket=wayland com.discordapp.Discord
    ;;
    ("Nobara Linux")
    ;;
esac

# Set up Discord Overlay of sorts (https://github.com/trigg/Discover)
sudo dnf copr enable mavit/discover-overlay -y
sudo dnf install discover-overlay gtk-layer-shell gtk-layer-shell-devel -y

# Set up Teamspeak5 with Wayland support (So it isn't blurry as shit anymore).
flatpak override --user --socket=wayland com.teamspeak.TeamSpeak
cp /var/lib/flatpak/exports/share/applications/com.teamspeak.TeamSpeak.desktop ~/.local/share/applications/com.teamspeak.TeamSpeak.desktop
sed -i 's|Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=teamspeak5 --file-forwarding com.teamspeak.TeamSpeak @@u %u @@|Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=teamspeak5 --file-forwarding com.teamspeak.TeamSpeak @@u --ozone-platform=wayland %u @@|' ~/.local/share/applications/com.teamspeak.TeamSpeak.desktop

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
## Get the Linux kernel version
kernel_version=$(uname -r)

## Extract major and minor version numbers
major_version=$(echo "$kernel_version" | cut -d. -f1)
minor_version=$(echo "$kernel_version" | cut -d. -f2)

## Check if the kernel version is below 6.5
if [[ "$major_version" -lt 6 || ( "$major_version" -eq 6 && "$minor_version" -lt 5 ) ]]; then
    echo "Kernel version is below 6.5. Updating P-States Settings for AMD."
    cpu_vendor=$(grep -m 1 vendor_id /proc/cpuinfo | cut -d ":" -f 2 | tr -d '[:space:]')
    if [ "$cpu_vendor" = "AuthenticAMD" ]; then
        sudo grubby --update-kernel=ALL --args="blacklist_module=acpi_cpufreq initcall_blacklist=acpi_cpufreq_init amd_pstate.shared_mem=1 amd_pstate.enable=1 amd_pstate=passive"
        sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg
    fi
else
    echo "Kernel version is 6.5 or higher. No further work is necessary."
fi

# TODO: Replace with Thunderbird.
# Install an email client.
case $XDG_CURRENT_DESKTOP in
    ("KDE")
    sudo dnf install kmail -y
    ;;
    ("gnome")
    sudo dnf install geary -y
esac

# Install Mullvad VPN.
## Add the Mullvad repository server to dnf
sudo dnf config-manager --add-repo https://repository.mullvad.net/rpm/stable/mullvad.repo
## Install the package
sudo dnf install mullvad-vpn -y

# Install ProtonVPN. NOTE: This does not currently work with Fedora 39's Beta for some reason.
sudo dnf install https://repo.protonvpn.com/fedora-38-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.1-2.noarch.rpm -y
sudo dnf check-update && sudo dnf upgrade -y
sudo dnf install --refresh proton-vpn-gnome-desktop -y

# Tailscale (Self Hosted VPN Stuff)
sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo -y
sudo dnf install tailscale -y
sudo systemctl enable --now tailscaled
sudo tailscale set --operator=$USER

# Set up Wake On Lan.
sudo ethtool -s enp5s0 wol g # NOTE: This may need to be adjusted based on the current devices in "ip addr".

# Update ClamAV database alongside enabling the service that refreshes the database.
sudo freshclam
sudo systemctl enable clamav-freshclam && sudo systemctl start clamav-freshclam

## ///// DPI SCALING RELATED STUFF /////
# ~/.local/share/kscreen has a config file that can tell you the refresh rate and DPI scale of the current display. There probably is a better way of doing this in Wayland, but I'd need to find a way to allow updating of the scale for these applications, since Steam's DPI scaling on KDE is still busted for some reason.

# Set up Wayland support in Spotify.
flatpak override --user --socket=wayland com.spotify.Client

# A config tweak for having a 1.3x scale for Spotify. Seemingly it doesn't allow double digits after the whole number, so we have to round down from 1.35 to 1.3.
# As shown here: https://justincaustin.com/blog/spotify-flatpak-hidpi-scaling/
#sudo sed -i 's/flatpak run --branch=stable --arch=x86_64 --command=spotify --file-forwarding com.spotify.Client /&--force-device-scale-factor=1.3 /' /var/lib/flatpak/app/com.spotify.Client/current/active/export/share/applications/com.spotify.Client.desktop
#sudo update-desktop-database

# A quick and easy way of forcing the DPI scaling of Steam to a specific scale. Uncomment and replace 1.35 with your desired DPI scale
# cp /usr/share/applications/steam.desktop ~/.local/share/applications
# awk '/^\[Desktop Entry\]/{flag=1} flag && /^Exec=/{sub(/^Exec=/, "Exec=STEAM_FORCE_DESKTOPUI_SCALING=1.35 ", $0); flag=0} 1' ~/.local/share/applications/steam.desktop > temp_file && mv temp_file ~/.local/share/applications/steam.desktop

# Update MIME Database (for file associations, such as .csproj and .sln files with Rider)
update-mime-database ~/.local/share/mime

## ///// MEDIA CODECS AND SUCH /////

case $NAME in
    ("Fedora Linux") # This is for Fedora specific stuff that can safely be ignored with Nobara.
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
    sudo dnf install vlc kodi -y
    ;;
esac

# Install FFMPEG with Nobara, as that's already handled with Fedora, and doing it conflicts with our freeworld drivers.
case $NAME in
    ("Nobara Linux")
    sudo dnf install ffmpeg -y
    ;;
esac

# Set up Jetbrains Mono NF.
sudo dnf copr enable elxreno/jetbrains-mono-fonts -y && sudo dnf install jetbrains-mono-fonts -y

# Install Better Fonts.
sudo dnf copr enable dawid/better_fonts -y && sudo dnf install fontconfig-font-replacements -y --skip-broken && sudo dnf install fontconfig-enhanced-defaults -y --skip-broken

# Install FontAwesome Fonts.
sudo dnf install fontawesome-fonts fontawesome5-brands-fonts -y

# Add a better font manager.
sudo dnf copr enable jerrycasiano/FontManager -y && sudo dnf install font-manager -y

# Install CJK fonts for KDE only (This is bundled with GNOME already).
case $XDG_CURRENT_DESKTOP in
    ("KDE")
    sudo dnf install google-noto-sans-cjk-fonts -y
esac

# Install Microsoft Fonts.
sudo dnf install curl cabextract xorg-x11-font-utils fontconfig -y
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
# Some other Microsoft fonts not included with msttcore-fonts. You may need to restart your PC for the fonts to appear.
wget -q -O - https://gist.githubusercontent.com/Blastoise/72e10b8af5ca359772ee64b6dba33c91/raw/2d7ab3caa27faa61beca9fbf7d3aca6ce9a25916/clearType.sh | bash
wget -q -O - https://gist.githubusercontent.com/Blastoise/b74e06f739610c4a867cf94b27637a56/raw/96926e732a38d3da860624114990121d71c08ea1/tahoma.sh | bash
wget -q -O - https://gist.githubusercontent.com/Blastoise/64ba4acc55047a53b680c1b3072dd985/raw/6bdf69384da4783cc6dafcb51d281cb3ddcb7ca0/segoeUI.sh | bash
wget -q -O - https://gist.githubusercontent.com/Blastoise/d959d3196fb3937b36969013d96740e0/raw/429d8882b7c34e5dbd7b9cbc9d0079de5bd9e3aa/otherFonts.sh | bash

# Finally updates our Font Cache.
sudo fc-cache -fv

## Add nerd-fonts for Noto, JetbrainsMono, and SourceCodePro font families. This will just install everything together, but I give no fucks at this point, just want things a little easier to set up.
# TODO: Figure out a way to selectively install fonts, I only really need the Noto Nerdfonts, JetbrainsMono Nerdfonts, and the SourceCodePro Nerdfonts.
# Reason being that too many fonts causes WINE and Proton to boot up extremely slowly.
git clone https://github.com/ryanoasis/nerd-fonts.git && cd nerd-fonts && ./install.sh && cd .. && https://github.com/ryanoasis/nerd-fontssudo rm -rf nerd-fonts

