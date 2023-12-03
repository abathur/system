{ config, inputs, system, pkgs, shared, user, ... }:

assert system == "x86_64-linux";

{
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/8f2927f0-b04e-4b53-b4b2-a105387ec20e";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B7FD-F6AA";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/5689c1c2-ba96-4388-8c99-4581d0a749a9"; }
    ];

  nix = {
    settings = {
      max-jobs = 16;
      cores = 16;
    };
  };

  powerManagement.cpuFreqGovernor = "ondemand";

  fileSystems."/home/${user.handle}/.doc" = {
    device = "/dev/disk/by-uuid/04b0a79f-a28f-4178-b41d-6906dd5a1953";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  fileSystems."/home/${user.handle}/.media" = {
    device = "/dev/disk/by-uuid/9234c30d-bc3c-4f54-91da-2c37471e8e7c";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "17.09"; # Did you read the comment?
}
