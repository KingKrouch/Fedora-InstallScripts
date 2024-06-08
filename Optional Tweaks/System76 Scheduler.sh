#!/bin/bash
# Add System76 scheduler
sudo dnf copr enable kylegospo/system76-scheduler -y
sudo dnf install system76-scheduler -y
sudo systemctl enable --now com.system76.Scheduler.service

# Add System76 scheduler script.
git clone https://github.com/maxiberta/kwin-system76-scheduler-integration.git
cd kwin-system76-scheduler-integration
kpackagetool6 --type KWin/Script -i .

wget https://github.com/maxiberta/kwin-system76-scheduler-integration/blob/main/system76-scheduler-dbus-proxy.sh -O ~/.local/bin/system76-scheduler-dbus-proxy.sh
sudo chmod +x ~/.local/bin/system76-scheduler-dbus-proxy.sh

sudo mv ~/.local/bin/system76-scheduler-dbus-proxy.sh /usr/local/bin/system76-scheduler-dbus-proxy.sh

mkdir ~/.config/systemd/
mkdir ~/.config/systemd/user/

# Echo the service into the specified file.
echo "[Unit]
Description=Forward com.system76.Scheduler session DBus messages to the system bus

[Service]
ExecStart=/usr/local/bin/system76-scheduler-dbus-proxy.sh

[Install]
WantedBy=default.target" > ~/.config/systemd/user/com.system76.Scheduler.dbusproxy.service

# Finally, enable the service.
systemctl --user enable --now com.system76.Scheduler.dbusproxy.service
