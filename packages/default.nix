self: pkgs: 
let
azurePkgs = rec {
  azure-storage-azcopy = pkgs.callPackage ./azcopy {};
  azure-linux-boot-agent = pkgs.callPackage ./azure-linux-boot-agent {};
};
in
  azurePkgs // { inherit azurePkgs; }
