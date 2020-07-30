{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.virtualisation.azure.image;
in
{  
  options = {
    virtualisation.azure.image = {
      diskSize = mkOption {
        type = with types; int;
        default = 2048;
        description = ''
          Size of disk image. Unit is MB.
        '';
      };
    };
  };
  
  config = {
    virtualisation.azure.integration.enable = true; # baseline support is needed
    
    system.build.azureImage = import ../../lib/make-disk-image.nix {
      name = "azure-image";
      postVM = ''
        filename="${config.system.nixos.label}.vhd.zstd"

        ${pkgs.vmTools.qemu}/bin/qemu-img convert -f raw -o subformat=fixed,force_size -O vpc $diskImage disk.vhd
        cat ./disk.vhd | ${pkgs.zstd}/bin/zstd > $out/$filename
        rm $diskImage
        ln -s $out/$filename $out/disk.vhd.zstd
        
        echo "${config.system.nixos.label}" > $out/label
        echo "${config.system.build.toplevel}" > $out/toplevel

        echo "nixos" > $out/name
        echo "nixos" > $out/publisher
        echo "nixos-azure-standard-0" > $out/offer
        echo "20.03" > $out/sku
        echo "${config.system.nixos.version}" > $out/version
      '';
      #configFile = ./azure-config-user.nix;
      format = "raw";
      partitionTableType = "efi";
      # TODO:
      # compressImage = true; # zstd compress for on-disk, we can zcat on the way up to azure
      inherit (cfg) diskSize;
      inherit config lib pkgs;
    };
  };
}
