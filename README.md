# nixos-azure
*nix-powered Azure tools and NixOS images*

**curious?** Come chat in #nixos-azure:matrix.org or #nixos-azure on Freenode.

## Status

* In-Progress
* Working
* Unfunded

## Demo

```bash
export AZURE_GROUP="defaultaz1"

# build the VHD
nix build "../..#hosts.azdev" --out-link /tmp/azdev

# upload the VHD
img_id="$(set -euo pipefail; nix shell "github:colemickens/nixos-azure" --command azutil upload /tmp/azdev)"

# boot a VM
nix shell "github:colemickens/nixos-azure" --command azutil boot "${img_id}"
```

## public images

Azure has no direct equivalent to Amazon's public AMIs.

At best, we could host a publicly-readable blob in every region, but there's still
nothing that prevents someone from pulling the image cross-region and incurring large
storage costs.

FINALLY, almost all of the options have some hole that leave them vulnerable to
an attacker who constantly downloads the image, or replicates it cross-region.


## open questions
1. consume userdata and try to apply as NixOS config?
   - seems maybe non-trivial
   - seems like people are going to be equipped to rollout a config anyway after deploy
2. nixops?
   - PRO:
     - some community is there already
   - CON:
     - I don't want to write python
     - I especially don't want to write python+nix that could maybe be generated
     - seems like considerably more work than I've done so far, even accounting for the agent (this might be
       less true of someone familiar with python/nixops)

## compared to nixpkgs/old versions
1. Fixes sudo/wheel/nopasswd
2. (maybe) compress the image zstdcat it on the way out
     this is because we want to pre-size the disk because it's slow to live-resize
     the disk later
3. Slim the image down (so far ~2.5GB -> 600MB)
4. An automated validation test! (nothing running it yet, though)
5. Gen2 VMs + UEFI Boot only

## considerations
1. Don't over-minimize your disk image.
   Azure IO is slow, expanding the disk is SLOOOOOW on first boot.
   We need to compare runtime of image copy vs resize from VM.
2. We minimize the disk image with zstd and inflate on the way back out anyway.

## todo
1. check if udev rules are working
2. script out the e2e tests, trigger them on builds.sr.ht
3. more tests

## goals
1. Get Azure out of nixpkgs
2. Iterate on `azure-linux-boot-agent` as an alternative to `walinuxagent`
3. Automate some basic sanity tests

## warnings
1. This repo is **EXPERIMENTAL**, and this is a project I'm doing to scratch and itch and try to fulfill a community
   need. However, this work is unfunded and thus comes with no real roadmap.
2. It uses [my non-official agent](https://github.com/colemickens/azure-linux-boot-agent),
and its behavior (and thus the behavior of these images/modules) is subject
to change.

## outputs
* docker:
  * docker image: `.#dockerImages.azure-aio.targz`
  * docker image (hub upload script): `.#dockerImages.azure-aio.upload-script`
  * docker image (hub): `docker://colemickens/azure-aio`
* azure:
  * azure image: use `github:colemickens/nixos-azure#nixosModules`
  * Azure image: `result/disk.vhd.zstd`
  * upload/run scripts `github:colemickens/nixos-azure#azutil [upload|boot]`

## license
Contact me if the license is an issue for you.
