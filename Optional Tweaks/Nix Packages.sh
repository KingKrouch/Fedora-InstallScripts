#!/bin/bash

# Set up Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
sudo -i nix upgrade-nix

# Install NixGL
sudo nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && sudo nix-channel --update
sudo nix-env -iA nixgl.auto.nixGLDefault
# NOTE: In order to run a Nix package with OpenGL or Vulkan, you simply do something like this:
# nixGL glxgears
# nixVulkan vkcube
# ALSO NOTE: For some reason, nixVulkan does not work, and I don't know a good way to get it working with AMD at the moment.
