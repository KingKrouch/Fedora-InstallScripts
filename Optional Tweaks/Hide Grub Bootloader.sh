#!/bin/bash
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
