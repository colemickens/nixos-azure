let
    pkgs = "";
    config = {};
in {
import "${inputs.nixpkgs}/nixos/lib/make-disk-image.nix" {
    name = "azure-image";
    postVM = ''
    ${pkgs.vmTools.qemu}/bin/qemu-img convert -f raw -o subformat=fixed,force_size -O vpc $diskImage $out/disk.vhd
    rm $diskImage
    '';
    #configFile = ./azure-config-user.nix;
    format = "raw";
    partitionTableType = "efi";
    inherit (cfg) diskSize;
    inherit config lib pkgs;
};