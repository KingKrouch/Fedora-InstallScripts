#!/bin/bash

# This setup uses this guide: https://fedoramagazine.org/automatically-decrypt-your-disk-using-tpm2/

# Check if Secure Boot is enabled, and whether the user has a TPM module.
if sudo dmesg | grep -q 'TPM'; then
    if sudo dmesg | grep -q 'Secure'; then
	echo "Secure Boot is enabled."
    else    
        echo "Secure Boot is not enabled. Just as an FYI, this may or may not cause clevis to work."
    fi
    # Install Clevis.
    sudo dnf install clevis clevis-luks clevis-dracut clevis-udisks2 clevis-systemd -y
    sudo dracut -fv --regenerate-all

    # Ask the user for input
    read -p "If you haven't cleared your TPM Module beforehand, you should do so now. Do you want to proceed? This may make things challenging to boot into an already existing Windows dual-boot. (y/n): " choice

    # Execute different commands based on the user's input
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Erasing TPM... This may result in a confirmation upon the next system boot asking if you want to clear the keys. Please confirm."
        echo 5 | sudo tee /sys/class/tpm/tpm0/ppi/request
    elif [[ "$choice" == "n" || "$choice" == "N" ]]; then
        echo "Proceeding without clearing TPM..."
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi

    echo "Please reboot using 'sudo systemctl reboot'."
else
    echo "There is no TPM module installed. Setup cannot continue."
fi
