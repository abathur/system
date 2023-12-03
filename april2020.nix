{ config, inputs, system, pkgs, shared, user, ... }:

assert system == "x86_64-darwin";

let
  multiUser = false;
in
{
  nix = {
    useDaemon = multiUser;

    # You should generally set this to the total number of logical cores in your system.
    # $ sysctl -n hw.ncpu

    settings.max-jobs = 4;
    settings.cores = 4;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # TODO: disable eventually, but you still have a single-user install atm
  services.nix-daemon.enable = false;
}
