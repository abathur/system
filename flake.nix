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
      url = "github:abathur/bashrc.nix/wip";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mgitstatus = {
      url = "github:abathur/multi-git-status/lookup_worktree_flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "bashrc/flake-utils";
      inputs.flake-compat.follows = "bashrc/flake-compat";
    };
  };

  outputs = { self, bashrc, ... }@inputs: {
    darwinConfigurations.abathur = inputs.darwin.lib.darwinSystem rec {
      system = "x86_64-darwin";
      inherit inputs;

      modules = [
        bashrc.darwinModules.bashrc
        ./darwin.nix
      ];
    };
    # TODO: defer for now; maybe revisit when you don't have to pin nixpkgs for lilgit?
    # nixosConfigurations.myskran = inputs.nixpkgs.nixosSystem rec {
    #   system = "x86_64-linux";
    #   inherit inputs;

    #   modules = [
    #     bashrc.nixosModules.bashrc
    #     ./nixos.nix
    #   ];
    # };
  };
}
