#!/usr/bin/env sh

nixos-rebuild switch --fast --flake .#condoserver --target-host root@condoserver.room409.wg.test --build-host root@condoserver.room409.wg.test
