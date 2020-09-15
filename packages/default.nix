self: pkgs: 
let
azurePkgs = rec {
  azure-storage-azcopy = azcopy;
  azcopy = pkgs.callPackage ./azcopy {};
  azure-linux-boot-agent = pkgs.callPackage ./azure-linux-boot-agent {};
  azutil = pkgs.callPackage ./azutil {};
  blobxfer = pkgs.python3Packages.callPackage ./blobxfer {
    bitstring_ = pkgs.python3Packages.callPackage ./bitstring {};
  };
};
in
  azurePkgs // { inherit azurePkgs; }
