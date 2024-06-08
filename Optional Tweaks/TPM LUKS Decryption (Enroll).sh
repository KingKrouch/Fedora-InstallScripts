#!/bin/bash

# This setup uses this guide: https://fedoramagazine.org/automatically-decrypt-your-disk-using-tpm2/

# Check if Secure Boot is enabled, and whether the user has a TPM module.
if dmesg | grep -q 'TPM'; then
    if dmesg | grep -q 'Secure'; then
	echo "Secure Boot is enabled."
    else    
        echo "Secure Boot is not enabled. Just as an FYI, this may or may not cause clevis to work."
    fi
    # Grab the first LUKS encrypted partition found on the system
    luks_part=$(lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | grep 'crypto_LUKS' | awk '{print "/dev/" substr($1,3)}')
    
    # Finally, we bind the Luks Partition password to the TPM.
    sudo clevis luks bind -d $luks_part tpm2 '{"pcr_ids":"1,4,5,7"}'
else
    echo "There is no TPM module installed. Setup cannot continue."
fi



