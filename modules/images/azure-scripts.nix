{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.virtualisation.azure.scripts;
  
  opts = cfg.azopts // {
    az = "${pkgs.azure-cli}/bin/az";
    azcopy = "${pkgs.azure-storage-azcopy}/bin/azure-storage-azcopy";
    image_vhd = "${config.system.build.azureImage}/disk.vhd";
    toplevel = "${config.system.build.toplevel}";
  };

  # scripts = lib.mapAttrs (name: type: pkgs.substituteAll ({
  #   src = ./scripts + "/${name}";
  #   dir = "bin";
  #   isExecutable = true;
  # } // opts)) (builtins.readDir ./scripts);
  
  # output = pkgs.buildEnv {
  #   name = "azure-scripts";
  #   paths = lib.attrValues scripts;
  # };
  output = pkgs.substituteAll ({
    src = ./azutil.sh;
    dir = "bin";
    isExecutable = true;
  } // opts);
in
{  
  options = {
    virtualisation.azure.scripts = {
      enable = mkEnableOption "Image Upload/Boot Scripts";
      # TODO this is a foot gun, user can under-spec options
      # split them out as separate options
      azopts = mkOption {
        default = {
          image_name = "nixos";
          deploy_name = "nixos-vm";

          image_group = "\${AZPREFIX:-\"nixos\"}-${config.system.nixos.label}";
          deploy_group = "\${AZPREFIX:-\"nixos\"}-${config.system.nixos.label}";
          image_location = "westus2";
          deploy_location = "westus2";
          deploy_vm_sku = "Standard_D8s_v3";
          deploy_disk_size_gb = "1024";
          deploy_username = "azureuser";
          deploy_sshkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9YAN+P0umXeSP/Cgd5ZvoD5gpmkdcrOjmHdonvBbptbMUbI/Zm0WahBDK0jO5vfJ/C6A1ci4quMGCRh98LRoFKFRoWdwlGFcFYcLkuG/AbE8ObNLHUxAwqrdNfIV6z0+zYi3XwVjxrEqyJ/auZRZ4JDDBha2y6Wpru8v9yg41ogeKDPgHwKOf/CKX77gCVnvkXiG5ltcEZAamEitSS8Mv8Rg/JfsUUwULb6yYGh+H6RECKriUAl9M+V11SOfv8MAdkXlYRrcqqwuDAheKxNGHEoGLBk+Fm+orRChckW1QcP89x6ioxpjN9VbJV0JARF+GgHObvvV+dGHZZL1N3jr8WtpHeJWxHPdBgTupDIA5HeL0OCoxgSyyfJncMl8odCyUqE+lqXVz+oURGeRxnIbgJ07dNnX6rFWRgQKrmdV4lt1i1F5Uux9IooYs/42sKKMUQZuBLTN4UzipPQM/DyDO01F0pdcaPEcIO+tp2U6gVytjHhZqEeqAMaUbq7a6ucAuYzczGZvkApc85nIo9jjW+4cfKZqV8BQfJM1YnflhAAplIq6b4Tzayvw1DLXd2c5rae+GlVCsVgpmOFyT6bftSon/HfxwBE4wKFYF7fo7/j6UbAeXwLafDhX+S5zSNR6so1epYlwcMLshXqyJePJNhtsRhpGLd9M3UqyGDAFoOQ== (none)";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    system.build.azureScripts = output;
  };
}

