#!/usr/bin/env sh

NIXPKGS_ALLOW_INSECURE=1 nixos-rebuild switch --fast --flake .#vps --target-host root@room409.xyz --impure
