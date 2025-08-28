#!/usr/bin/env bash
nix run home-manager/master -- switch --flake  ~/nix_config/home-manager
#home-manager switch --flake  ~/nix_config/home-manager
