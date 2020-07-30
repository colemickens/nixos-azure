{ pkgs, modulesPath, ... }:

{
  imports = [
    ../basic.nix
  ];
  
  virtualisation.azure = {
    integration = {
      enable = true;
      metadataMode = "generation";
    };
    scripts.enable = true;
  };

}
