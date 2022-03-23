#!/usr/bin/env bash

# Automatically Configure DNF to be a bit faster, and gives the changes a test drive.
sudo bash -c 'echo 'fastestmirror=True' >> /etc/dnf/dnf.conf && echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf && echo 'defaultyes=True' >> /etc/dnf/dnf.conf'
sudo dnf update -y

# Disable NetworkManager Wait Service (due to long boot times).
sudo systemctl disable NetworkManager-wait-online.service

# Install third-party repositories (Via RPMFusion).
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf group update core -y

# Install NVIDIA Drivers (Will require making sure the system is up to date).
sudo dnf upgrade --refresh -y
sudo dnf install dnf-plugins-core -y
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-xconfig -y

# Install Media Codecs and Plugins.
sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y && sudo dnf install lame\* --exclude=lame-devel -y && sudo dnf group upgrade --with-optional Multimedia -y
sudo dnf install vlc -y

# alias "dir" to "ls -lsh" for my sanity.
echo "alias dir='ls -lsh'" >> ~/.zshrc
echo "alias dir='ls -lsh'" >> ~/.bashrc

# Install neofetch.
sudo dnf install neofetch -y

# Set up neofetch with my preferred configuration.
wget -O ~/.config/neofetch/config.conf https://github.com/KingKrouch/Fedora-KDE-InstallScripts/raw/main/.config/neofetch/config.conf

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
echo 'neofetch' >> tee -a ~/.bashrc ~/.zshrc

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

# Install some KDE extensions.
sudo dnf install latte-dock -y
sudo dnf copr enable capucho/bismuth -y  && sudo dnf install bismuth -y

# Remove some KDE Plasma bloatware that comes installed for some reason.
sudo dnf remove akregator dnfdragora kgpg kfind kmag kmail kcolorchooser kmouth korganizer kmousetool kruler kwalletmanager kwrite kaddressbook kcharselect konversation elisa-player kmahjongg kpat kmines dragonplayer gwenview kamoso kolourpaint krdc krfb -y

# Install notifications daemon and archive manager.
sudo dnf install notification-daemon ark -y

# Install Breeze-GTK theme, which isn't included in the KDE installation process.
sudo dnf install breeze-gtk -y

# Install GNOME Disks, because that's the only thing that can be salvaged from GNOME's increasigly user unfriendly arsenal.
sudo dnf install gnome-disk-utility -y
# Install Filelight as an alternative to WinDirStat
sudo dnf install filelight -y

# Audio Related Software. A soundboard application and a VST Plugin manager specifically.
sudo dnf copr enable patrickl/yabridge -y && sudo dnf install yabridge -y
sudo dnf copr enable rivenirvana/soundux -y && sudo dnf install soundux -y

# Install Visual Studio Code.
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' && sudo dnf check-update && sudo dnf install code -y

# Install RenderDoc and Vulkan Tools.
sudo dnf install renderdoc -y && sudo dnf install vulkan-tools -y

# Enable Flatpaks.
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install some Flatpaks that I personally use.
flatpak install flathub com.discordapp.Discord -y
flatpak install flathub org.libreoffice.LibreOffice -y
flatpak install flathub org.gimp.GIMP -y
flatpak install flathub org.blender.Blender -y
flatpak install flathub ch.protonmail.protonmail-bridge -y && flatpak install flathub org.mozilla.Thunderbird -y
flatpak install flathub org.qbittorrent.qBittorrent -y

# Install some game launcher and emulator Flatpaks.
flatpak install flathub com.heroicgameslauncher.hgl -y
flatpak install flathub net.rpcs3.RPCS3 -y
flatpak install flathub org.yuzu_emu.yuzu -y
flatpak install flathub org.ryujinx.Ryujinx -y
flatpak install flathub org.DolphinEmu.dolphin-emu -y
flatpak install flathub net.pcsx2.PCSX2 -y
flatpak install flathub com.mojang.Minecraft -y

# Install Ghidra.
flatpak install flathub org.ghidra_sre.Ghidra -y && sudo flatpak override org.ghidra_sre.Ghidra --filesystem=/mnt

# Install OBS Studio.
flatpak install flathub com.obsproject.Studio -y

# Install nvFBC patch (So OBS won't kill itself trying to record at high framerates).
git clone https://github.com/keylase/nvidia-patch.git && cd nvidia-patch && sudo ./patch-fbc.sh && cd .. && rm -rf nvidia-patch

# Install nvFBC OBS Plugin.
flatpak install flathub com.obsproject.Studio.Plugin.NVFBC -y

# Install a basic video editor for now. No, I'm not going to use DaVinci Resolve after trying it. Don't ask me about it.
sudo dnf install kdenlive -y

# Install and Setup OneDrive.
sudo dnf install onedrive -y && sudo systemctl stop onedrive@$USER.service && sudo systemctl disable onedrive@$USER.service && systemctl --user enable onedrive && systemctl --user start onedrive
echo "Make sure to run onedrive --synchronize when you can."

# Install Steam and Steam-Devices.
sudo dnf install steam steam-devices -y

# Install ProtonVPN and required dependencies.
sudo dnf install https://protonvpn.com/download/protonvpn-beta-release-1.0.1-1.noarch.rpm -y && sudo dnf update -y && sudo dnf install protonvpn python3-pip -y
pip3 install --user dnspython>=1.16.0

# Install Compatibility Related Stuff for Autodesk Maya.
sudo dnf copr enable dioni21/compat-openssl10 -y && sudo dnf install compat-openssl10 -y
sudo dnf install libpng15 csh audiofile libXp -y
mkdir $HOME/maya
mkdir $HOME/maya/2022
echo -e "MAYA_OPENCL_IGNORE_DRIVER_VERSION=1\nMAYA_CM_DISABLE_ERROR_POPUPS=1\nMAYA_COLOR_MGT_NO_LOGGING=1\nTMPDIR=/tmp\nMAYA_NO_HOME=1" >> $HOME/maya/2022/Maya.env
echo "Please download and install Autodesk Maya on your own accord. The dependencies and compatibility tweaks for Fedora should be taken care of now."

# Install Better Fonts
sudo dnf copr enable dawid/better_fonts -y && sudo dnf install fontconfig-font-replacements -y --skip-broken && sudo dnf install fontconfig-enhanced-defaults -y --skip-broken

# Install Docker
sudo dnf install docker -y

# Install MangoHud with GOverlay
sudo dnf install goverlay -y

# Install gamemode alongside enabling the gamemode service.
sudo dnf install gamemode -y && systemctl --user enable gamemoded && systemctl --user start gamemoded

# Install SteamTinkerLaunch and uninstall some stuff that comes bundled with it that I personally don't need.
sudo dnf copr enable capucho/steamtinkerlaunch -y && sudo dnf install steamtinkerlaunch -y && sudo dnf remove gameconqueror scummvm -y

# Install Wine-Staging
sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/35/winehq.repo -y && sudo dnf install winehq-staging -y

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
cd .. && rm mf-install

# Install Clip Studio Paint (Via Wine)
wget -O CSP_Setup.exe https://www.clipstudio.net/gd?id=csp-install-win
wine CSP_Setup.exe
rm CSP_Setup.exe
echo "Make sure to set concrt140 as a WineDLLOverride to prevent CSP from crashing."

# Install Ableton Live 11 (Via Wine)
mkdir ~/Ableton && cd ~/Ableton
wget https://cdn-downloads.ableton.com/channels/11.1.1/ableton_live_trial_11.1.1_64.zip
unzip ableton_live_trial_11.1.1_64.zip
wine "Ableton Live 11 Trial Installer.exe"
cd .. && rm -rf ~/Ableton

# Install VirtManager alongside OVMF UEFI and some requirements for WinApps (Will need to uncomment unix_sock_group and unix_sock_rw_perms from /etc/libvirt/libvirtd.conf)
sudo dnf install libvirt virt-install edk2-ovmf virt-manager freerdp -y
sudo systemctl enable libvirtd.service && sudo systemctl start libvirtd.service
sudo usermod -a -G libvirt $(whoami) && sudo usermod -a -G kvm $(whoami)

# Install VMWare Player as a secondary option.
sudo dnf install @development-tools -y
sudo dnf install kernel-headers kernel-devel dkms elfutils-libelf-devel qt5-qtx11extras -y
wget https://download3.vmware.com/software/WKST-PLAYER-1623-New/VMware-Player-Full-16.2.3-19376536.x86_64.bundle
sudo chmod +x VMware-Player-Full-16.2.3-19376536.x86_64.bundle
sudo ./VMware-Player-Full-16.2.3-19376536.x86_64.bundle
# Installs kernel modules for VMWare Player, since we have to do that on our own.
git clone https://github.com/mkubecek/vmware-host-modules.git && cd vmware-host-modules && git checkout player-16.2.3 && make && sudo make install

# Set up Samba
sudo dnf install samba -y
sudo systemctl enable smb nmb && sudo systemctl start smb nmb

# Set up SSH Server on Host
sudo systemctl enable sshd && sudo systemctl start sshd

# Set up FireFox PWA support.
sudo rpm --import https://packagecloud.io/filips/FirefoxPWA/gpgkey
echo -e "[firefoxpwa]\nname=FirefoxPWA\nmetadata_expire=300\nbaseurl=https://packagecloud.io/filips/FirefoxPWA/rpm_any/rpm_any/\$basearch\ngpgkey=https://packagecloud.io/filips/FirefoxPWA/gpgkey\nrepo_gpgcheck=1\ngpgcheck=0\nenabled=1" | sudo tee /etc/yum.repos.d/firefoxpwa.repo
sudo dnf -q makecache -y --disablerepo="*" --enablerepo="firefoxpwa"
sudo dnf install firefoxpwa -y

# Fix Mac keyboard layout for Keychron K4.
echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
sudo dracut --regenerate-all –force

# Install Timeshift (For Backups)
sudo dnf install -y make vala libvala libgee-devel vte291-devel json-glib-devel
sudo dnf mark remove make vala libvala libgee-devel vte291-devel json-glib-devel
git clone https://github.com/teejee2008/timeshift.git
cd timeshift
make all
sudo make install

# Install alien (for package conversions)
sudo dnf install alien -y

# Install OpenRGB and set up Razer periphreals with OpenRazer and RazerGenie.
sudo modprobe i2c-dev && sudo modprobe i2c-piix4 && sudo dnf install https://openrgb.org/releases/release_0.7/openrgb_0.7_x86_64_6128731.rpm -y
wget -O 60-openrgb.rules https://github.com/CalcProgrammer1/OpenRGB/raw/master/60-openrgb.rules && sudo mv 60-openrgb.rules /etc/udev/rules.d/
sudo dnf install kernel-devel -y
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/hardware:razer/Fedora_35/hardware:razer.repo && sudo dnf install openrazer-meta -y && sudo dnf install razergenie -y && sudo gpasswd -a $USER plugdev

# Install cpupower-gui for CPU power management purposes.
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:erigas:cpupower-gui/Fedora_35/home:erigas:cpupower-gui.repo && sudo dnf install cpupower-gui -y
