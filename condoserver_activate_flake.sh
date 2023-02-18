#!/usr/bin/env sh

nixos-rebuild switch --fast --flake .#condoserver --target-host root@192.168.86.21 --build-host root@192.168.86.21
