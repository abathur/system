{ config, inputs, ... }:

let
  system = "x86_64-darwin";
  # pkgs = inputs.nixpkgs.legacyPackages.${system};
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.mgitstatus.overlays.default
    ];
  };
  multiUser = false;
  shared = import ./shared.nix {
    inherit pkgs;
    inherit (pkgs) stdenv;
  };
  helpers = import ./helpers.nix;
  user = helpers.mkUser "abathur";
  /*
  I'd like to have a hostname that occasionally changes. I'd prefer
  semirandom, so for a while I based this on time:

  macHash = builtins.substring 0 8 (builtins.hashString "sha256" (builtins.toString builtins.currentTime));

  Nix flakes block this specific nondeterminism w/o impure flags
  (which cause their own problems), so I need a new solution. I can
  stomach just using the flake SHA since it would encourage me to
  keep at least that flake committed up nicely, but this would be
  likely to lead me back around to the problem that made me want a
  semirandom hostname in the first place: clashes on the network
  causing macOS to adopt the dumb "<hostname> (2)" form.

  For now I'll combine system, my user handle, and the flake rev.
  That doesn't technically fix the problem as I observed it with two
  intel macs, but it should skirt the conflict if my next mac is arm
  and also leaves me the option to use a different handle for those
  systems? IDK. TODO!
  */
  macHash = builtins.substring 0 8 (builtins.hashString "sha256" (
    system
    + user.handle
    + (if inputs.self ? rev then inputs.self.rev else throw "Refusing to build from a dirty Git tree!")
  ));
in {
  imports = [
    ./common.nix
  ];

  users.users.${user.handle} = {
    # TODO: refactor this kludge :)
    home = "/Users/${user.handle}";
  };

  nix = {
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    package = pkgs.nixVersions.stable;
    registry.nixpkgs.flake = inputs.nixpkgs;
    useDaemon = multiUser;
    extraOptions = ''
      builders-use-substitutes = true
      experimental-features = nix-command flakes
    '';

    # You should generally set this to the total number of logical cores in your system.
    # $ sysctl -n hw.ncpu

    settings.max-jobs = 4;
    settings.cores = 4;

    distributedBuilds = true;
    buildMachines = [ {
      hostName = "192.168.13.100";
      sshUser = "myskran";
      sshKey = "~/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
      speedFactor = 16;
    } ];
  };

  # TODO: cross-platform this
  # TODO: until a nix-darwin bug is fixed, you have to darwin-rebuild switch -Q once with this set to false, and then set it to true and do it (without -Q)... (i.e., this breaks the config for bootstrapping)
  # Dec 27 2022: rm if you've bootstrapped a system without seeing this
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
    ]
    ++ shared.fonts;
  };

  networking = with shared; {
    hostName = "${macHash}";
    knownNetworkServices = [
      "Wi-Fi"
      "Bluetooth PAN"
      "Bluetooth PAN 2"
      "Thunderbolt Bridge"
      "VPN (L2TP)"
    ];
    dns = dns;

    # Not supported in macos? just not built yet?
    # extraHosts = shared.extraHosts
  };

  # DOING: relocate paths
  nixpkgs.overlays = [
    /*
    TODO: understand why bashrc needs to be HERE
    for hag to get picked up on build (mgitstatus
    can just be included in the overlays to the
    pkgs attr earlier--which makes sense--but there's
    probably some way to list them both in 1 spot)
    */
    inputs.bashrc.overlays.default
  ];

  # below still needs the bootstrap to chsh this.
  environment.shells = with pkgs; [ bashInteractive ];

  environment.systemPackages = with pkgs; with shared; [
    # TODO: technically just part of persistence.sh
    #       eventually package that, too
    # multi-git-status
  ]
  ++ desktop-apps
  ++ tools
  ++ utils
  ++ gaming
  ;

  /*
  "DONE/-ISH" notes here refer to an audit of these settings
  that I did during the initial setup; was committed in my
  dotfile repo as

  commit 55094309c4f8e208d09b4e8838cb1fcbcc3a0ddd
  Date:   Fri Mar 22 11:05:56 2019 -0500
  */
  system.defaults = { # DONE-ISH
    # Whether to enable quarantine for downloaded applications.
    LaunchServices.LSQuarantine = false;
    # TODO: refactor/dedupe kludge below
    screencapture.location = "/Users/${user.handle}/Desktop";
    dock = { # DONE-ISH
      autohide = true;
      orientation = "left";
      show-process-indicators = true;
      tilesize = 30;
      mru-spaces = false;
    };
    finder = { # DONE-ISH
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      _FXShowPosixPathInTitle = true;

      # I see these examples in another file suggesting that you don't actually need a *script* to set non-default options, you just have to make them strings:
      # "com.apple.trackpad.enableSecondaryClick" = true;
      # "com.apple.trackpad.trackpadCornerClickBehavior" = 1;
    };
    trackpad = { #DONE
      TrackpadRightClick = true;
    };
    NSGlobalDomain = { # DONE
      AppleKeyboardUIMode = 3;
      AppleShowAllExtensions = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      NSTableViewDefaultSizeMode = 1;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      "com.apple.springing.delay" = null;
    };
  };

  launchd.user.agents.backup = {
    path = [ config.environment.systemPath ];
    # pass user so that script can output a daily log:
    # script itself logs to "$(printf '/Users/'"$1"'/backup.%(%a-%b-%d-%Y-%T)T.log')"
    command = "~/.config/persistence/backup.sh ${user.handle}";
    serviceConfig = {
      StartCalendarInterval = [
        { Hour = 7; }
        { Hour = 23;}
      ];
    };
  };

  programs.bashrc = {
    enable = true;
    user = user.handle;
  };

  # Nix-darwin is too cautious to do this for us.
  # Note: the bootstrap copies the originals to {}.orig
  system.activationScripts.postActivation.text = ''
    sudo cp /etc/static/shells /etc/shells
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # TODO: disable eventually, but you still have a single-user install atm
  services.nix-daemon.enable = false;
}
