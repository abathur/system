{
  description = "SIGH";

  inputs = {
    nixospkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bashrc = {
      url = "github:abathur/bashrc.nix/fix_nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, bashrc, ... }@inputs:
  let
    mkSystem = { generator, whichpkgs, system, username, modules, ... }: generator {
      inherit system;

      specialArgs = let
        pkgs = import whichpkgs {
          inherit system;
          overlays = [
            inputs.bashrc.overlays.default
          ];
          config = { allowUnfree = true; };
        };
        helpers = import ./helpers.nix;
      in {
        inherit inputs system self pkgs;
        shared = import ./shared.nix {
          inherit pkgs;
        };
        user = helpers.mkUser username;
      };

      modules = [
        ./common.nix
      ] ++ modules;
    };

  in {
    darwinConfigurations.abathur2024 = mkSystem {
      generator = inputs.darwin.lib.darwinSystem;
      whichpkgs = inputs.nixpkgs;
      system = "aarch64-darwin";
      username = "abathur";
      modules = [
        bashrc.darwinModules.bashrc
        ./darwin.nix
        ./abathur.nix
        ./november2024.nix
      ];
    };

    darwinConfigurations.abathur2020 = mkSystem {
      generator = inputs.darwin.lib.darwinSystem;
      whichpkgs = inputs.nixpkgs;
      system = "x86_64-darwin";
      username = "abathur";
      modules = [
        bashrc.darwinModules.bashrc
        ./darwin.nix
        ./abathur.nix
        ./april2020.nix
      ];
    };

    nixosConfigurations.myskran = mkSystem {
      generator = inputs.nixpkgs.lib.nixosSystem;
      whichpkgs = inputs.nixospkgs;
      system = "x86_64-linux";
      username = "myskran";
      modules = [
        bashrc.nixosModules.bashrc
        ./nixos.nix
        ./myskran.nix
        ./march2018.nix
      ];
    };
    darwinConfigurations.travise = mkSystem {
      generator = inputs.darwin.lib.darwinSystem;
      whichpkgs = inputs.nixpkgs;
      system = "aarch64-darwin";
      username = "travise";
      modules = [
        bashrc.darwinModules.bashrc
        ./darwin.nix
        # TODO: ./monthyear.nix
      ];
    };
  };
}
