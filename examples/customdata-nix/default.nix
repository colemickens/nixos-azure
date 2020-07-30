{ pkgs, modulesPath, ... }:

{
  imports = [
    ../basic.nix
  ];
  
  virtualisation.azure = {
    integration = {
      enable = true;
      metadataMode = "nix";
    };
    scripts.enable = true;
  };

}
