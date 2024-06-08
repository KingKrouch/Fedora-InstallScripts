#!/bin/bash
# Here's what I'm essentially doing: https://fedoramagazine.org/hibernation-in-fedora-36-workstation/
# Another source: https://www.ctrl.blog/entry/fedora-hibernate.html

# Create the Swap BTRFS subvolume.
btrfs subvolume create /swap

# Use this to grab the physical RAM size in GB.
ram_size=$(sudo dmidecode -t 19 | awk -F': |GB' '/Range Size/{print $2}')

# Use zramctl to grab the current ZRAM Size.
zram_size=$(zramctl /dev/zram0 -o DISKSIZE | tail -n1 | grep -o '[0-9]*' | sed 's/G$//; s/^$//')

# Grab our recommended Swapsize.
swap_size=$(( ($ram_size * 2) + $zram_size ))
echo "Swap size recommendation: $swap_size GB"

# Create an empty Swapfile.
sudo touch /swap/swapfile

# Disable Copy On Write on the file.
sudo chattr +C /swap/swapfile

# Allocate the recommended swap size for the swapfile.
sudo fallocate --length "${swap_size}G" /swap/swapfile

# Adjust user permissions
sudo chmod 600 /swap/swapfile 

# Finally make the swap partition available.
sudo mkswap /swap/swapfile

# Adjust our dracut config to allow for resuming.
echo 'add_dracutmodules+=" resume "' | sudo tee -a /etc/dracut.conf.d/resume.conf

# Install GCC, as we will need it.
sudo dnf install gcc -y

# Make a directory for our btrfs map script to reside in, and then grabs the script we need.
mkdir btrfs_tools && cd btrfs_tools
wget https://github.com/osandov/osandov-linux/raw/main/scripts/btrfs_map_physical.c

# Compiles the script, so we can run it.
gcc -O2 -o btrfs_map_physical btrfs_map_physical.c
sudo ./btrfs_map_physical /swap/swapfile

# Need to note the first physical offset with the file offset of 0, should be first row. In my case for the time being, it's 99896786944.

# Grab our UUID for the swap file.
swap_uuid=$(findmnt -no UUID -T /swap/swapfile)

# Get Pagesize
page_size=$(getconf PAGESIZE)

# Get kernel resume offset.
kernel_resume_offset=$(( 99896786944 / $page_size ))

# Finally updates our grub configs.
sudo grubby --args="resume=UUID=${swap_uuid} resume_offset=${kernel_resume_offset}" --update-kernel=ALL

# Finally adds some services we need.
sudo tee /etc/systemd/system/hibernate-preparation.service << EOF
[Unit]
Description=Enable swap file and disable zram before hibernate
Before=systemd-hibernate.service

[Service]
User=root
Type=oneshot
ExecStart=/bin/bash -c "/usr/sbin/swapon /swap/swapfile && /usr/sbin/swapoff /dev/zram0"

[Install]
WantedBy=systemd-hibernate.service
EOF
# Second Service for Resuming.
sudo tee /etc/systemd/system/hibernate-resume.service << EOF
[Unit]
Description=Disable swap after resuming from hibernation
After=hibernate.target

[Service]
User=root
Type=oneshot
ExecStart=/usr/sbin/swapoff /swap/swapfile

[Install]
WantedBy=hibernate.target
EOF

# Enables the service.
sudo systemctl enable hibernate-resume.service

# Do some necessary fixes for memory checks on login.
sudo mkdir -p /etc/systemd/system/systemd-logind.service.d/

sudo tee -a /etc/systemd/system/systemd-logind.service.d/override.conf << EOF

[Service]
Environment=SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK=1

EOF

sudo mkdir -p /etc/systemd/system/systemd-hibernate.service.d/

sudo tee -a /etc/systemd/system/systemd-hibernate.service.d/override.conf << EOF

[Service]
Environment=SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK=1

EOF

# Finally makes our grub cfg.
sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg

# Regenerate our Dracut config.
sudo dracut --regenerate-all --force

# Add the necessary configs to enable Hibernation.
echo -e "[Sleep]\nAllowHibernation=yes\nHibernateMode=shutdown" | sudo tee -a /etc/systemd/sleep.conf > /dev/null

# Disable ZRam (As we want to use the swap instead).
sudo swapoff /dev/zram0; sudo zramctl --reset /dev/zram0
sudo dnf remove zram-generator-defaults -y
sudo swapon /swap/swapfile
echo '/swap/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
