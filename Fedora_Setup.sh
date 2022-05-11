#!/usr/bin/env bash

## ///// THE ABSOLUTE BASICS /////

# Automatically Configure DNF to be a bit faster, and gives the changes a test drive.
sudo bash -c 'echo 'fastestmirror=True' >> /etc/dnf/dnf.conf && echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf && echo 'defaultyes=True' >> /etc/dnf/dnf.conf'
sudo dnf update -y

# Disable NetworkManager Wait Service (due to long boot times).
sudo systemctl disable NetworkManager-wait-online.service

# Install third-party repositories (Via RPMFusion).
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf group update core -y

# Enable Flatpaks.
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install NVIDIA Drivers (Will require making sure the system is up to date).
sudo dnf upgrade --refresh -y
sudo dnf install dnf-plugins-core -y
sudo dnf install akmod-nvidia kmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-xconfig -y


## ///// TERMINAL STUFF /////

# alias "dir" to "ls -lsh" for my sanity.
echo "alias dir='ls -lsh'" >> ~/.zshrc
echo "alias dir='ls -lsh'" >> ~/.bashrc

# Install neofetch.
sudo dnf install neofetch -y

# Set up neofetch with my preferred configuration.
wget -O ~/.config/neofetch/config.conf https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/.config/neofetch/config.conf
wget -O ~/.config/neofetch/rog.ascii https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/.config/neofetch/rog.ascii

# Install exa and lsd, which should replace lsd and dir.
sudo dnf install exa lsd -y

# Install zsh, alongside setting up oh-my-zsh.
sudo dnf install zsh -y && chsh -s $(which zsh) && sudo chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"c

# Append exa and lsd aliases, and neofetch alias to both the bashrc and zshrc.
echo "if [ -x /usr/bin/lsd ]; then
  alias ls=lsd
  alias dir=ls -l
  alias lah=ls -lah
  alias lt=ls --tree
fi" >> tee -a ~/.bashrc ~/.zshrc
echo 'neofetch --ascii ~/.config/neofetch/rog.ascii' >> tee -a ~/.bashrc ~/.zshrc

# Set up agnoster as the default zsh theme.
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' ~/.zshrc

## Add nerd-fonts for Noto and SourceCodePro font families.
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Noto.zip
mkdir ~/Noto && cd ~/Noto
unzip Noto.zip
mkdir ~/.local/share/fonts/ && cp ~/Noto/Noto*.ttf ~/.local/share/fonts/
cd .. && rm -rf ~/Noto && rm ~/Noto.zip
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/SourceCodePro.zip
mkdir ~/SourceCodePro && cd ~/SourceCodePro
unzip SourceCodePro.zip
mkdir ~/.local/share/fonts/ && cp ~/Noto/Sauce*.ttf ~/.local/share/fonts/
cd .. && rm -rf ~/SourceCodePro && rm ~/SourceCodePro.zip
fc-cache -fv
wget https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/bin/scripts/lib/i_linux.sh -P ~/.local/share/fonts/
source ~/.local/share/fonts/i_linux.sh


## ///// GAMING AND GAMING TWEAKS /////

# Install Steam and Steam-Devices.
sudo dnf install steam steam-devices -y

# Install some game launcher and emulator Flatpaks.
flatpak install flathub com.heroicgameslauncher.hgl -y
flatpak install flathub net.rpcs3.RPCS3 -y
flatpak install flathub org.yuzu_emu.yuzu -y
flatpak install flathub org.ryujinx.Ryujinx -y
flatpak install flathub org.DolphinEmu.dolphin-emu -y
flatpak install flathub net.pcsx2.PCSX2 -y
flatpak install flathub com.mojang.Minecraft -y

# Install a Soundboard Application, for micspamming in Team Fortress 2 servers, of course! ;-)
sudo dnf copr enable rivenirvana/soundux -y && sudo dnf install soundux -y

# Install MangoHud with GOverlay
sudo dnf install goverlay -y

# Install gamemode alongside enabling the gamemode service.
sudo dnf install gamemode -y && systemctl --user enable gamemoded && systemctl --user start gamemoded


## ///// WINE AND WINDOWS SOFTWARE /////

# Install Wine
sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/36/winehq.repo -y && sudo dnf install wine -y

# Set up some prerequisites for Wine.
sudo dnf install cabextract samba-winbind*.x86_64 samba-winbind*.i686 -y && sudo dnf install cabextract -y
wget  https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x winetricks
sh winetricks corefonts # look into avoid using winetricks for vcrun6 and dotnet462 because of the painfully long install process from the GUI installer. Fuck that.
rm winetricks
wget https://aka.ms/vs/17/release/vc_redist.x86.exe
wget https://aka.ms/vs/17/release/vc_redist.x64.exe
wget https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe
wine NDP462-KB3151800-x86-x64-AllOS-ENU.exe
wine vc_redist.x86.exe /quiet /norestart
wine vc_redist.x64.exe /quiet /norestart
rm vc_redist.x86.exe vc_redist.x64.exe NDP462-KB3151800-x86-x64-AllOS-ENU.exe

# Set up DXVK, VKD3D, and Media Foundation codecs to Wine.
wget https://github.com/doitsujin/dxvk/releases/download/v1.10/dxvk-1.10.tar.gz
tar -xzvf dxvk-1.10.tar.gz
cd dxvk-1.10
WINEPREFIX="/home/$USER/.wine" ./setup_dxvk.sh install
cd .. && rm -rf dxvk-1.10 && rm dxvk-1.10.tar.gz
wget https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v2.6/vkd3d-proton-2.6.tar.zst
tar --use-compress-program=unzstd -xvf vkd3d-proton-2.6.tar.zst && cd vkd3d-proton-2.6
WINEPREFIX="/home/$USER/.wine" ./setup_vkd3d_proton.sh install
cd .. && rm -rf vkd3d-proton-2.6 && rm vkd3d-proton-2.6.tar.zst
git clone https://github.com/z0z0z/mf-install && cd mf-install
WINEPREFIX="/home/$USER/.wine" ./mf-install.sh
cd .. && rm -rf mf-install


## //// VIRTUAL MACHINE AND NETWORKING STUFF /////

# Install VirtManager alongside OVMF UEFI and some requirements for WinApps (Will need to uncomment unix_sock_group and unix_sock_rw_perms from /etc/libvirt/libvirtd.conf)
sudo dnf install libvirt virt-install edk2-ovmf virt-manager freerdp -y
sudo systemctl enable libvirtd.service && sudo systemctl start libvirtd.service
sudo usermod -a -G libvirt $(whoami) && sudo usermod -a -G kvm $(whoami)

# Set up Samba
sudo dnf install samba -y
sudo systemctl enable smb nmb && sudo systemctl start smb nmb

# Set up SSH Server on Host
sudo systemctl enable sshd && sudo systemctl start sshd

## ///// DEVELOPMENT/PROGRAMMING TOOLS AND GAME ENGINE STUFF /////

# Set up Kernel-Devel
sudo dnf install kernel-devel -y

# Set up Unity Hub and Jetbrains
sudo sh -c 'echo -e "[unityhub]\nname=Unity Hub\nbaseurl=https://hub.unity3d.com/linux/repos/rpm/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://hub.unity3d.com/linux/repos/rpm/stable/repodata/repomd.xml.key\nrepo_gpgcheck=1" > /etc/yum.repos.d/unityhub.repo' && sudo yum check-update && sudo yum install unityhub -y
mkdir $HOME/Applications && cd $HOME/Applications && wget -O jetbrains-toolbox.tar.gz https://download.jetbrains.com/toolbox/jetbrains-toolbox-1.24.11947.tar.gz && tar xvzf jetbrains-toolbox.tar.gz && cd .. && echo "Make sure to remove the 'jetbrains-toolbox' executable from the extracted folder before running!"

# Install Docker
sudo dnf install docker -y

# Install MinGW64, CMake, Ninja Build
sudo dnf install mingw64-\* cmake ninja-build -y

# Install Ghidra.
flatpak install flathub org.ghidra_sre.Ghidra -y && sudo flatpak override org.ghidra_sre.Ghidra --filesystem=/mnt

# Install Visual Studio Code.
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' && sudo dnf check-update && sudo dnf install code -y

# Install RenderDoc and Vulkan Tools.
sudo dnf install renderdoc -y && sudo dnf install vulkan-tools -y


## ///// DIGITAL CONTENT CREATION TOOLS /////

# Install Clip Studio Paint (Via Wine)
wget -O CSP_Setup.exe https://www.clipstudio.net/gd?id=csp-install-win
wine CSP_Setup.exe
rm CSP_Setup.exe
echo "Make sure to set concrt140 as a WineDLLOverride to prevent CSP from crashing."

# Install Ableton Live 11 (Via Wine) and Yabridge (for VST plugins)
sudo dnf copr enable patrickl/yabridge -y && sudo dnf install yabridge -y
mkdir ~/Ableton && cd ~/Ableton
wget https://cdn-downloads.ableton.com/channels/11.1.1/ableton_live_trial_11.1.1_64.zip
unzip ableton_live_trial_11.1.1_64.zip
wine "Ableton Live 11 Trial Installer.exe"
cd .. && rm -rf ~/Ableton

# Install Compatibility Related Stuff for Autodesk Maya and Mudbox.
sudo dnf copr enable dioni21/compat-openssl10 -y && sudo dnf install pcre-utf16 -y && sudo dnf install compat-openssl10 -y
sudo dnf install libpng15 csh audiofile libXp -y
mkdir $HOME/maya
mkdir $HOME/maya/2023
echo -e "MAYA_OPENCL_IGNORE_DRIVER_VERSION=1\nMAYA_CM_DISABLE_ERROR_POPUPS=1\nMAYA_COLOR_MGT_NO_LOGGING=1\nTMPDIR=/tmp\nMAYA_NO_HOME=1" >> $HOME/maya/2023/Maya.env
echo "Please download and install Autodesk Maya on your own accord. The dependencies and compatibility tweaks for Fedora should be taken care of now."
echo -e "LD_LIBRARY_PATH="/usr/autodesk/mudbox2023/lib"" >> $HOME/.profile


## ///// GENERAL DESKTOP USAGE /////

# Set up Pop Shell for Tiled Window Management, Dash to Dock, and Gnome Tweaks
sudo dnf install pop-shell -y && sudo dnf install gnome-tweaks -y && sudo dnf install gnome-shell-extension-dash-to-dock -y

# Install Input-Remapper (For Razer Tartarus Pro)
sudo dnf install python3-evdev python3-devel gtksourceview4 python3-pydantic python-pydbus xmodmap -y
sudo pip install evdev -U && sudo pip uninstall key-mapper  && sudo pip install --no-binary :all: git+https://github.com/sezanzeb/input-remapper.git
sudo systemctl enable input-remapper && sudo systemctl restart input-remapper

# Fix Mac keyboard layout for Keychron K4.
echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
sudo dracut --regenerate-all –force

# Set up FireFox PWA support.
sudo rpm --import https://packagecloud.io/filips/FirefoxPWA/gpgkey
echo -e "[firefoxpwa]\nname=FirefoxPWA\nmetadata_expire=300\nbaseurl=https://packagecloud.io/filips/FirefoxPWA/rpm_any/rpm_any/\$basearch\ngpgkey=https://packagecloud.io/filips/FirefoxPWA/gpgkey\nrepo_gpgcheck=1\ngpgcheck=0\nenabled=1" | sudo tee /etc/yum.repos.d/firefoxpwa.repo
sudo dnf -q makecache -y --disablerepo="*" --enablerepo="firefoxpwa"
sudo dnf install firefoxpwa -y

# Install OpenRGB and set up Razer periphreals with OpenRazer and RazerGenie. (Requires being installed later, due to Kernel-Devel being in the Development Section.)
sudo modprobe i2c-dev && sudo modprobe i2c-piix4 && sudo dnf install https://openrgb.org/releases/release_0.7/openrgb_0.7_x86_64_6128731.rpm -y
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/hardware:razer/Fedora_35/hardware:razer.repo && sudo dnf install openrazer-meta -y && sudo dnf install razergenie -y && sudo gpasswd -a $USER plugdev

# Install CoreCtrl for CPU power management purposes.
sudo dnf install corectrl -y

# Install OBS Studio.
flatpak install flathub com.obsproject.Studio -y

# Install nvFBC patch (So OBS won't kill itself trying to record at high framerates).
git clone https://github.com/keylase/nvidia-patch.git && cd nvidia-patch && sudo ./patch.sh -f && sudo ./patch-fbc.sh && sudo ./patch.sh -f && sudo ./patch-fbc.sh -f && cd .. && rm -rf nvidia-patch

# Install nvFBC OBS Plugin.
flatpak install flathub com.obsproject.Studio.Plugin.NVFBC -y

# Install some Flatpaks that I personally use.
flatpak install flathub com.discordapp.Discord -y
flatpak install flathub org.libreoffice.LibreOffice -y
flatpak install flathub org.gimp.GIMP -y
flatpak install flathub org.blender.Blender -y
flatpak install flathub org.mozilla.Thunderbird -y
flatpak install flathub org.qbittorrent.qBittorrent -y

# Install a basic video editor for now. No, I'm not going to use DaVinci Resolve after trying it. Don't ask me about it.
sudo dnf install kdenlive -y

# Install and Setup OneDrive.
sudo dnf install onedrive -y && sudo systemctl stop onedrive@$USER.service && sudo systemctl disable onedrive@$USER.service && systemctl --user enable onedrive && systemctl --user start onedrive
echo "Make sure to run onedrive --synchronize when you can."

# Install archive manager.
sudo dnf install ark -y

# Install Filelight as an alternative to WinDirStat
sudo dnf install filelight -y

# Install Mullvad VPN.
sudo dnf install https://mullvad.net/media/app/MullvadVPN-2022.1_x86_64.rpm -y


## ///// MEDIA CODECS AND SUCH /////

# Install Media Codecs and Plugins.
sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y && sudo dnf install lame\* --exclude=lame-devel -y && sudo dnf group upgrade --with-optional Multimedia -y
sudo dnf install vlc -y

# Install Better Fonts
sudo dnf copr enable dawid/better_fonts -y && sudo dnf install fontconfig-font-replacements -y --skip-broken && sudo dnf install fontconfig-enhanced-defaults -y --skip-broken
