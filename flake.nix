{
  description = "SIGH";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bashrc = {
      url = "github:abathur/bashrc.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mgitstatus = {
      url = "github:abathur/multi-git-status/lookup_worktree_flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "bashrc/flake-utils";
      inputs.flake-compat.follows = "bashrc/flake-compat";
    };
  };

  outputs = { self, nixpkgs, bashrc, ... }@inputs:
  let
    mkSystem = { generator, system, username, modules, ... }: generator {
      inherit system;

      specialArgs = let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.mgitstatus.overlays.default
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
