{ config, options, inputs, pkgs, shared, user, ... }:

{
  # TODO: until a nix-darwin bug is fixed, you have to darwin-rebuild switch -Q once with this set to false, and then set it to true and do it (without -Q)... (i.e., this breaks the config for bootstrapping)
  # Dec 27 2022: rm if you've bootstrapped a system without seeing this
  fonts = {
    fontDir.enable = true;
  };

  nix = {
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    package = pkgs.nixVersions.stable;
    registry.nixpkgs.flake = inputs.nixpkgs;

    extraOptions = ''
      builders-use-substitutes = true
      experimental-features = nix-command flakes
    '';

    distributedBuilds = true;

    # TODO: I used to have `options.nix.settings.trusted-users.default ++ ` here; commenting out since it won't eval on darwin but this may be wrong
    settings.trusted-users = [ user.handle ];
  };

  programs = {
    bash.enableCompletion = true;
    bashrc = { # mine
      enable = true;
      user = user.handle;
    };
  };

  time.timeZone = "America/Chicago";
}
