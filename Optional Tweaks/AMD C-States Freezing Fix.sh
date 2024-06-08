#!/bin/bash
# Update the AMD C-States used, in an attempt to fix the random freezing bug.
cpu_vendor=$(grep -m 1 vendor_id /proc/cpuinfo | cut -d ":" -f 2 | tr -d '[:space:]')
if [ "$cpu_vendor" = "GenuineIntel" ]; then
    echo "CPU vendor is Intel. Ignoring..."
elif [ "$cpu_vendor" = "AuthenticAMD" ]; then
    echo "CPU vendor is AMD. Setting up C-States boot parameters..."
    sudo grubby --update-kernel=ALL --args="processor.max_cstate=1"
else
    echo "Unknown CPU vendor. Skipping..."
fi
sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg
