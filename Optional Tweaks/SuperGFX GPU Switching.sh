#!/bin/bash
# Set up SuperGFXCTL and the SuperGFXCTL Plasmoid for Laptop GPU switching.
sudo dnf copr enable lukenukem/asus-linux -y
sudo dnf install supergfxctl -y

case $XDG_CURRENT_DESKTOP in
    ("KDE")
    sudo dnf copr enable jhyub/supergfxctl-plasmoid -y
    sudo dnf install supergfxctl-plasmoid -y
    ;;
    ("gnome")
    echo "Please install the GNOME extension here: https://extensions.gnome.org/extension/5344/supergfxctl-gex/"
esac

sudo systemctl enable supergfxd && sudo systemctl start supergfxd
