#!/usr/bin/env bash
sudo $(which nix) run --extra-experimental-features 'nix-command flakes' 'github:numtide/system-manager' -- switch --flake  /home/nbraswell6/nix_config/system-manager
