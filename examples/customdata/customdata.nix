{ config, pkgs, ... }:

{
  config = {
    services.nginx.enable = true;
  };
}