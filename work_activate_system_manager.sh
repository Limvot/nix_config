#!/usr/bin/env bash
nix run --extra-experimental-features 'nix-command flakes' 'github:numtide/system-manager' -- switch --flake  /home/nbraswell6/nix_config/system-manager
