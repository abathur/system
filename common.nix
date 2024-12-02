{ config, options, inputs, pkgs, shared, user, ... }:

{
  nix = {
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
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
    bash.completion.enable = true;
    bashrc = { # mine
      enable = true;
      user = user.handle;
    };
  };

  time.timeZone = "America/Chicago";
}
