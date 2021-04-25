{
  description = "nixos-azure";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    blobxferpkgs = { url = "github:nixos/nixpkgs/d3ff247475f50829a87bf248261ad5462cf07936"; };
    cmpkgs = { url = "github:colemickens/nixpkgs/cmpkgs"; };
  };

  outputs = inputs:
    let
      nameValuePair = name: value: { inherit name value; };
      genAttrs = names: f: builtins.listToAttrs (map (n: nameValuePair n (f n)) names);
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = genAttrs [ "x86_64-linux" "i686-linux" "aarch64-linux" ];

      pkgsFor = pkgs: system: overlays:
        import pkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = overlays;
        };
      pkgs_ = genAttrs (builtins.attrNames inputs) (inp: genAttrs supportedSystems (sys: pkgsFor inputs."${inp}" sys [inputs.self.overlay]));

      mkSystem = system: pkgs_: thing:
        #(pkgsFor pkgs_ system).lib.nixosSystem {
        pkgs_.lib.nixosSystem {
          inherit system;
          modules = [(./. + "/${thing}")];
          specialArgs.inputs = inputs;
        };
    in
    rec {
      devShell = forAllSystems (system:
        let
          nixpkgs_ = (pkgsFor inputs.nixpkgs system [inputs.self.overlay]);
        in
          nixpkgs_.mkShell {
            nativeBuildInputs = with nixpkgs_; [
              nixFlakes zstd
              bash cacert cachix
              curl git jq mercurial
              openssh ripgrep
            ];
          }
      );

      overlay = final: prev:
        let p = rec {
          # blobxfer = pkgs_.blobxferpkgs."${prev.system}".python3Packages.callPackage ./packages/blobxfer {
          #   bitstring_ = pkgs_.blobxferpkgs."${prev.system}".python3Packages.callPackage ./packages/bitstring {};
          # };
          blobxfer = pkgs_.nixpkgs.${prev.system}.python3Packages.callPackage ./packages/blobxfer {
            bitstring_ = pkgs_.blobxferpkgs."${prev.system}".python3Packages.callPackage ./packages/bitstring {};
          };
          azure-linux-boot-agent = prev.callPackage ./packages/azure-linux-boot-agent {};
          azutil = prev.callPackage ./packages/azutil {};
        }; in p // { azurePkgs = p; };

      # TODO:
      examples = (
        let
          system = "x86_64-linux";
          nixpkgs_ = pkgs_.nixpkgs.system;
          x = name: (mkSystem system inputs.nixpkgs name).config.system.build;
        in {
          basic = x "examples/basic";
        }
      );

      nixosModules = import ./modules;

      packages = forAllSystems (system:
        pkgs_.nixpkgs.${system}.azurePkgs
      );

      container = forAllSystems (system:
        pkgs_.nixpkgs.${system}.callPackage ./docker/azure-aio {}
      );

      defaultPackage = forAllSystems (system:
        pkgs_.nixpkgs.${system}.symlinkJoin {
          name = "flake-azure";
          paths = inputs.nixpkgs.lib.attrValues pkgs_.nixpkgs.${system}.azurePkgs;
        }
      );
    };
}
