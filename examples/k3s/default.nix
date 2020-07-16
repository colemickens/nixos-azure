{ pkgs, lib, modulesPath, ... }:

{
  imports = [
    ../basic/default.nix
  ];

  virtualisation.azure.image.diskSize = lib.mkForce 2500;

  services.k3s = {
    enable = true;
    role = "server";
  };
  environment.systemPackages = [ pkgs.kubectl ];
}
