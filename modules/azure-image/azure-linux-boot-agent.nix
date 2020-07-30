{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.virtualisation.azure.agent;
  provisionedHook = pkgs.writeScript "provisioned-hook" ''
    #!${pkgs.runtimeShell}
    /run/current-system/systemd/bin/systemctl start provisioned.target
  '';
  #agentPackage = cfg.agentPackage;
  agentPackage = (pkgs.callPackage ../../packages/azure-linux-boot-agent {});
in
{
  options.virtualisation.azure.agent = {
    enable = mkEnableOption {
      default = false;
      description = "Whether to enable the AZLBA.";
    };
    logLevel = mkOption {
      default = "info";
      description = "The RUST_LOG level to use for AZLBA.";
    };
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
    #agentPackage = mkOption {
    #  default = pkgs.callPackage ../../packages/azure-linux-boot-agent {};
    #  description = "The package to use for AZLBA.";
    #};
  };

  config = mkIf cfg.enable {
    assertions = [ {
      assertion = pkgs.stdenv.isi686 || pkgs.stdenv.isx86_64;
      message = "Azure not currently supported on ${pkgs.stdenv.hostPlatform.system}";
    } {
      assertion = config.networking.networkmanager.enable == false;
      message = "Windows Azure Linux Agent is not compatible with NetworkManager";
    } ];

    boot.initrd.kernelModules = [ "ata_piix" ]; # TODO(cole) ??
    networking.firewall.allowedUDPPorts = [ 68 ]; # TODO(cole) ??

    # TODO: sanity check the udev rules
    services.udev.packages = [ agentPackage ];

    networking.dhcpcd.persistent = true;

    systemd.targets.provisioned = {
      description = "Services Requiring Azure VM provisioning to have finished";
    };

    systemd.services.azure-linux-boot-agent = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "sshd.service" ];
      wants = [ "network-online.target" ];

      path = with pkgs; [ bash hostname shadow p7zip ];
      environment = { RUST_LOG = "${cfg.logLevel}"; };
      description = "Azure Linux Boot Agent Service";
      serviceConfig = {
        DeviceAllow = "/dev/sr0 r";
        ExecStart = "${agentPackage}/bin/azure-linux-boot-agent";
        Type = "oneshot";
      };
    };
  };
}
