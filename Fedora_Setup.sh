#!/usr/bin/env bash

## ///// THE ABSOLUTE BASICS /////

# Automatically Configure DNF to be a bit faster, and gives the changes a test drive.
sudo bash -c 'echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf && echo 'defaultyes=True' >> /etc/dnf/dnf.conf'
sudo dnf update -y

# Disable NetworkManager Wait Service (due to long boot times).
sudo systemctl disable NetworkManager-wait-online.service

# Install third-party repositories (Via RPMFusion).
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf group update core -y

# Enable Flatpaks.
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo

# Set up Flatseal for Flatpak permissions
flatpak install flathub com.github.tchx84.Flatseal -y

# Enable GloriousEggroll's Fedora patches used in Nobara (for games like Halo Infinite)
sudo dnf copr enable gloriouseggroll/mesa-aco -y && dnf copr enable sentry/kernel-fsync -y && sudo dnf update --refresh -y

## ///// TERMINAL STUFF /////

# Install neofetch.
sudo dnf install neofetch -y

# Set up neofetch with my preferred configuration.
wget -O ~/.config/neofetch/config.conf https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/.config/neofetch/config.conf
wget -O ~/.config/neofetch/rog.ascii https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/.config/neofetch/rog.ascii

# Install exa and lsd, which should replace lsd and dir.
sudo dnf install exa lsd -y

# Install zsh, alongside setting up oh-my-zsh.
sudo dnf install zsh -y && chsh -s $(which zsh) && sudo chsh -s $(which zsh)
sudo dnf install git -y && sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"c

# Append exa and lsd aliases, and neofetch alias to both the bashrc and zshrc.
echo "if [ -x /usr/bin/lsd ]; then
  alias ls='lsd'
  alias dir='lsd -l'
  alias lah='lsd -lah'
  alias lt='lsd --tree'
fi" >> tee -a ~/.bashrc ~/.zshrc
echo "alias neofetch='neofetch --ascii ~/.config/neofetch/rog.ascii'
neofetch" >> tee -a ~/.bashrc ~/.zshrc

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

# Finally, Set up Konsole with my custom profiles
wget -O ~/.local/share/konsole/Breeze.colorscheme https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/.local/share/konsole/Breeze.colorscheme
wget -O ~/.local/share/konsole/Konsole.profile https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/.local/share/konsole/Konsole.profile
wget -O ~/.config/konsolerc https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/.config/konsolerc

## ///// GAMING AND GAMING TWEAKS /////

# Install Steam and Steam-Devices.
sudo dnf install steam steam-devices -y

# Install some game launcher and emulator Flatpaks.
flatpak install flathub-beta com.heroicgameslauncher.hgl -y
flatpak install flathub net.rpcs3.RPCS3 -y
flatpak install flathub org.yuzu_emu.yuzu -y
flatpak install flathub org.ryujinx.Ryujinx -y
flatpak install flathub org.DolphinEmu.dolphin-emu -y
flatpak install flathub net.pcsx2.PCSX2 -y
flatpak install flathub org.polymc.PolyMC -y
flatpak remote-add --if-not-exists launcher.moe https://gol.launcher.moe/gol.launcher.moe.flatpakrepo
flatpak install launcher.moe com.gitlab.KRypt0n_.an-anime-game-launcher -y
flatpak install flathub com.steamgriddb.steam-rom-manager -y

# Install some Proton related stuff (for game compatibility)
flatpak install flathub com.github.Matoking.protontricks -y
flatpak install flathub net.davidotek.pupgui2 -y

# Install a Soundboard Application, for micspamming in Team Fortress 2 servers, of course! ;-)
sudo dnf copr enable rivenirvana/soundux -y && sudo dnf install soundux -y

# Install MangoHud with GOverlay, alongside Gamescope and vkBasalt.
sudo dnf install goverlay -y && sudo dnf install vkBasalt -y && sudo dnf install gamescope -y

# Install gamemode alongside enabling the gamemode service.
sudo dnf install gamemode -y && systemctl --user enable gamemoded && systemctl --user start gamemoded

## ///// WINE AND WINDOWS SOFTWARE /////

# Install Wine
sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/36/winehq.repo -y && sudo dnf install wine -y && sudo dnf install winetricks -y

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
winetricks dotnet48

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

# Remove DOSBox Staging, which WINE installs for some dumb reason.
sudo dnf remove dosbox-staging -y

## //// NETWORKING STUFF /////

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

# Install Epic Asset Manager (For Unreal Engine)
flatpak install flathub io.github.achetagames.epic_asset_manager -y

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

# Install several dependencies for CheatEngine-Proton-Helper
sudo dnf install python3-vdf yad xdotool -y

# Install a hex editor
sudo dnf install okteta -y

# Install GitHub Desktop
flatpak install flathub io.github.shiftey.Desktop -y

# Install .NET Runtime/SDK (for Rider and C# applications)
sudo dnf install dotnet -y

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

# Remove system version of Firefox and replace with the more recently updated Flatpak variant.
sudo dnf remove firefox -y
flatpak install flathub org.mozilla.firefox -y

# Remove some KDE Plasma bloatware that comes installed for some reason.
sudo dnf remove akregator dnfdragora kfind kmag kmail kcolorchooser kmouth korganizer kmousetool kruler kwalletmanager kaddressbook kcharselect konversation elisa-player kmahjongg kpat kmines dragonplayer kamoso kolourpaint krdc krfb -y

# Install notifications daemon.
sudo dnf install notification-daemon -y

# Install Breeze-GTK theme, which isn't included in the KDE installation process.
sudo dnf install breeze-gtk -y

# Install some KDE extensions, alongside some tweaks.
sudo dnf install qt -y
## Set up Latte Dock through the Git repository, as that's kept more up to date than in the Fedora software repositories.
sudo dnf install cmake extra-cmake-modules qt5-qtdeclarative-devel plasma-wayland-protocols-devel qt5-qtx11extras-devel qt5-qtwayland-devel kf5-kiconthemes-devel kf5-plasma-devel kf5-kwindowsystem-devel kf5-kdeclarative-devel kf5-kxmlgui-devel kf5-kactivities-devel gcc-c++ gcc xcb-util-devel kf5-kwayland-devel git gettext kf5-karchive-devel kf5-knotifications-devel libSM-devel kf5-kcrash-devel kf5-knewstuff-devel kf5-kdbusaddons-devel kf5-kxmlgui-devel kf5-kglobalaccel-devel kf5-kio-devel kf5-kguiaddons-devel kf5-kirigami2-devel kf5-kirigami-devel kf5-ki18n kf5-ki18n-devel -y
git clone https://github.com/KDE/latte-dock && cd latte-dock && sudo ./install.sh && cd .. && sudo rm -rf latte-dock
## Set up Latte-Dock to use the Super/Win Key.
kwriteconfig5 --file ~/.config/kwinrc --group ModifierOnlyShortcuts --key Meta "org.kde.lattedock,/Latte,org.kde.LatteDock,activateLauncherMenu" && qdbus org.kde.KWin /KWin reconfigure
## Install the tiled window management KWin plugin, Bismuth.
sudo dnf copr enable capucho/bismuth -y  && sudo dnf install bismuth -y

# Installs the widgets needed for latte-dock and the desktop environment.
wget https://github.com/KingKrouch/Fedora-InstallScripts/raw/main/Plasmoids.zip
unzip ./Plasmoids.zip -d ~/.local/share/plasma/plasmoids/ && rm -rf ./Plasmoids.zip

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

# Install GStreamer Plugin for OBS Studio, alongside some plugins.
flatpak install com.obsproject.Studio.Plugin.Gstreamer org.freedesktop.Platform.GStreamer.gstreamer-vaapi -y
flatpak install org.freedesktop.Platform.VulkanLayer.OBSVkCapture com.obsproject.Studio.Plugin.OBSVkCapture -y

# Install some Flatpaks that I personally use.
flatpak install flathub io.github.spacingbat3.webcord -y # Using Webcord instead of Discord because it barely fucking works in Wayland.
flatpak install flathub org.libreoffice.LibreOffice -y
flatpak install flathub org.gimp.GIMP -y
flatpak install flathub org.blender.Blender -y
flatpak install flathub org.mozilla.Thunderbird -y
flatpak install flathub org.qbittorrent.qBittorrent -y

# Enable support for flatpak Discord to use Discord Rich Presence for non-sandboxed applications.
mkdir -p ~/.config/user-tmpfiles.d
echo 'L %t/discord-ipc-0 - - - - app/com.discordapp.Discord/discord-ipc-0' > ~/.config/user-tmpfiles.d/discord-rpc.conf
systemctl --user enable --now systemd-tmpfiles-setup.service

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

# Install Java
sudo dnf install java -y

## ///// MEDIA CODECS AND SUCH /////

# Install Media Codecs and Plugins.
sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y && sudo dnf install lame\* --exclude=lame-devel -y && sudo dnf group upgrade --with-optional Multimedia -y
sudo dnf install vlc -y

# Install Better Fonts
sudo dnf copr enable dawid/better_fonts -y && sudo dnf install fontconfig-font-replacements -y --skip-broken && sudo dnf install fontconfig-enhanced-defaults -y --skip-broken
