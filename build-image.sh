#!/usr/bin/env bash

set -e

img="basic"

nix --experimental-features 'nix-command flakes' \
  build \
  --override-input nixpkgs /home/cole/code/nixpkgs/cmpkgs \
  --builders 'ssh://root@nixos' -j 0 \
   ".#examples.${img}.toplevel"

nix --experimental-features 'nix-command flakes' \
  build \
  --override-input nixpkgs /home/cole/code/nixpkgs/cmpkgs \
   ".#examples.${img}.azureScripts"
