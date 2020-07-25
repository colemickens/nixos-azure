# flake-azure
*nix-powered Azure tools and NixOS images*









AZLBA doesnt persist hostname




## overview
[![builds.sr.ht status](https://builds.sr.ht/~colemickens/flake-azure.svg)](https://builds.sr.ht/~colemickens/flake-azure?)

NixOS 20.03 Image: [[ build badges here]]
NixOS Unstable Image: [[ build badges here]]
Docker Image: [[ build badge here ]]

## current status

1. report ready = works (aka, your vm won't reboot)
2. user provisioning + key provisioning works
3. hyperv entropy seeding is *actually* implement and works
4. userdata does _not_ work

## open questions
1. How to design the azure-config.nix to include this flake's module maybe?
2.  -- how do downstream users use? Do I need hydra  and a channel for the flake modules?

## compared to nixpkgs/old versions
1. Fixes sudo/wheel/nopasswd
2. (maybe) compress the image zstdcat it on the way out
     this is because we want to pre-size the disk because it's slow to live-resize
     the disk later

## considerations
1. Don't over-minimize your disk image.
   Azure IO is slow, expanding the disk is SLOOOOOW on first boot.
   We need to compare runtime of image copy vs resize from VM.

## todo
1. export the modules for people to consume via the flake
2. demo repo showing how someone would instantly start using this in a new flakes-powered project
3. script out the e2e tests, trigger them on builds.sr.ht
4. Does nix os ecosystem have hardening suggestions?

## goals
1. Get Azure out of nixpkgs
2. Iterate on `azure-linux-boot-agent` as an alternative to `walinuxagent`
3. Automate some basic sanity tests
4. Slim the image down (so far ~2.5GB -> 600MB)
5. Get udev rules working

## side-goals
1. rewrite nixos-rebuild and systemd-boot-builder.py in Rust to remove 200MB from the 600MB image

## stakes
1. This will primarily support NixOS.
2. Gen2 VMs + UEFI Boot only
3. Password auth is disabled

## warnings
1. This repo is **EXPERIMENTAL**.
2. It uses [my non-official agent](https://github.com/colemickens/azure-linux-boot-agent),
and its behavior (and thus the behavior of these images/modules) is subject
to change.

## outputs
* docker:
  * docker image: `.#dockerImages.azure-aio.targz`
  * docker image (hub upload script): `.#dockerImages.azure-aio.upload-script`
  * docker image (hub): `docker://colemickens/azure-aio`
* azure:
  * Azure image: `<insert url here>`
  * Azure image: `<insert url here>`

## build log
1. 2020-07-15: Start `flake-azure`.
   * Init repo layout.
   * Copy my `azure-new` from nixpkgs.
   * Plan features.
   * Start `azure-linux-boot-agent`.
   * Four hours later: AZLBA can do basic provisioning (no ssh key support yet)
2. 2020-07-16: Polish a bit of UX
   * You can upload/boot VMs with per-image build artifacts
   * Boot agent is smarter
   * boot agent sucks butt

## license
Contact me if the license is an issue for you.
