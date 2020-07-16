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
    # TODO: it should be possible to do this without `inputs` ??
    # ${pkgs.path} should work? but instead= > access to path '/nix/store/3lgnydl8xxb65ikrh7ywpijdhsmpkb2i-w6dk02ic80jvwmy61gag4sprr4q85dc2-source/lib/make-disk-image.nix' is forbidden in restricted mode
    system.build.azureImage = import ../lib/make-disk-image.nix {
      name = "azure-image";
      postVM = ''
        ${pkgs.vmTools.qemu}/bin/qemu-img convert -f raw -o subformat=fixed,force_size -O vpc $diskImage $out/disk.vhd
        rm $diskImage
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
