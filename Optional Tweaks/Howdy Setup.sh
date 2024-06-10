#!/bin/bash

sudo dnf copr enable principis/howdy -y && sudo dnf --refresh install howdy -y

sudo mkdir /usr/lib64/security/howdy/snapshots

echo "module howdy 1.0;

require {
  type lib_t;
  type xdm_t;
  type v4l_device_t;
  type sysctl_vm_t;
  class chr_file map;
  class file { create getattr open read write };
  class dir add_name;
}

#============= xdm_t ==============
allow xdm_t lib_t:dir add_name;
allow xdm_t lib_t:file { create write };
allow xdm_t sysctl_vm_t:file { getattr open read };
allow xdm_t v4l_device_t:chr_file map;" > howdy.te

checkmodule -M -m -o howdy.mod howdy.te
semodule_package -o howdy.pp -m howdy.mod
sudo semodule -i howdy.pp

echo "This still requires configuring your sudo, sddm/gdm scripts to use".
