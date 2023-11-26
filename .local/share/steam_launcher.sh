#!/bin/bash

# This should make DPI Scaling in Steam less of a pain in the ass on KDE Wayland.
# We are using -vgui with Steam because for some reason, Steam crashes on KDE Wayland without it for some obtuse reason.
case $XDG_SESSION_TYPE in
        ("wayland") # Checks if the session is Wayland
            echo "Wayland is in use."
            case $XDG_CURRENT_DESKTOP in
            ("KDE") # Checks if the desktop environment is KDE.
            echo "KDE Plasma is in use."
            # Specify the path to your kwinrc file
            kwinrc_path="$HOME/.config/kwinrc"
            # Use grep and sed to extract the Scale property
            scale=$(grep -Pzo "\[Xwayland\][^\[]*\n\s*Scale\s*=\s*\K[0-9.]+" "$kwinrc_path" | tr -d '\0')
            # Check if the Scale property was found
            if [ -n "$scale" ]; then
                # Convert the scale factor to a percentage, and then export the environment variable.
                percentage=$(awk "BEGIN { printf \"%.0f\n\", $scale * 100 }")
                echo "Scale property currently set to $percentage%."
                export STEAM_FORCE_DESKTOPUI_SCALING=$scale
            else
                echo "Scale property not found in $kwinrc. Launching Steam without DPI scaling."
            fi
            ;;
            esac
            ;;
        ("x11") # Checks if the session is X11.
        echo "X11 is in use. Ignore DPI Scaling Fix."
        ;;
esac

if [ -x /usr/bin/mangohud ]; then
        bash mangohud /usr/bin/steam -vgui %U
    else
        bash /usr/bin/steam -vgui %U
fi
