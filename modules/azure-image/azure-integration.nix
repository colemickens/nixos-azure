{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.virtualisation.azure.integration;
in
{
  options = {
    virtualisation.azure.integration = {
      enable = mkEnableOption "AZLBA";
      metadataMode = mkOption {
        type = pkgs.types.enum [ "apply" "stash" "noop" ];
        defaultValue = "apply";
      };
      createUsers = mkOption {
        type = pkgs.types.bool;
        defaultValue = true;
      };
      seedEntropy = mkOption {
        type = pkgs.types.bool;
        defaultValue = true;
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.azure.agent = {
      enable = true;
      logLevel = "trace";
    };

    nix.package = pkgs.nixUnstable;

    # TODO: link to where this is documented
    boot.kernelParams = [
      "console=ttyS0" "earlyprintk=ttyS0" "rootdelay=300"
      "panic=1" "boot.panic_on_fail"
    ];
    
    boot.initrd.kernelModules = [ "hv_vmbus" "hv_netvsc" "hv_utils" "hv_storvsc" ];
    boot.growPartition = true; # requires udisks2, do not disable it
    boot.loader.systemd-boot.enable = true;

    services.openssh.passwordAuthentication = false;
    security.sudo.wheelNeedsPassword = false;

    fileSystems = {
      "/boot".device = "/dev/disk/by-label/ESP";
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
        autoResize = true;
      };
    };

    # Allow root logins only using the SSH key that the user specified
    # at instance creation time, ping client connections to avoid timeouts
    services.openssh.enable = true;
    services.openssh.permitRootLogin = "prohibit-password";
    services.openssh.extraConfig = ''
      ClientAliveInterval 180
    '';

    # Force getting the hostname from Azure
    networking.hostName = mkDefault "";
    networking.usePredictableInterfaceNames = false;
  };
}
