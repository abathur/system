{
  description = "SIGH";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
    mkSystem = { generator, system, modules, ... }: generator {
      inherit system;
      specialArgs = {
        inherit inputs system self nixpkgs;
      };
      modules = [
        # shared? common? something else?
      ] ++ modules;
    };

  in {
    darwinConfigurations.abathur = mkSystem {
      generator = inputs.darwin.lib.darwinSystem;
      system = "x86_64-darwin";
      modules = [
        bashrc.darwinModules.bashrc
        ./darwin.nix
      ];
    };
    nixosConfigurations.myskran = mkSystem {
      generator = inputs.nixpkgs.lib.nixosSystem;
      system = "x86_64-linux";
      modules = [
        bashrc.nixosModules.bashrc
        ./nixos.nix
      ];
    };
    darwinConfigurations.travise = mkSystem {
      generator = inputs.darwin.lib.darwinSystem;
      system = "aarch64-darwin";
      modules = [
        bashrc.darwinModules.bashrc
        ./darwin.nix
      ];
    };
  };
}
