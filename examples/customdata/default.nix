{ pkgs, lib, modulesPath, ... }:

{
  imports = [
    ../basic/default.nix
  ];

  virtualisation.azure.image.diskSize = lib.mkForce 2500;

  # this image will respect any custom data provided to it
  virtualisation.azure.image.integration.activateCustomData = true;
}
