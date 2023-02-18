#!/usr/bin/env sh

nixos-rebuild switch --fast --flake .#vps --target-host root@room409.xyz
