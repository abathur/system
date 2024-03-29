# default: lib, config, options, pkgs, specialArgs, modulesPath
{ config, inputs, system, pkgs, shared, user, ... }:

let
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
  users.users.${user.handle} = {
    home = "/Users/${user.handle}";
  };

  nix = {
    # TODO: refactor to dedup this w/ system/config defs, yeah?
    buildMachines = [ {
      hostName = "192.168.13.100";
      sshUser = "myskran";
      sshKey = "~/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
      speedFactor = 16;
    } ];
  };

  # TODO: until a nix-darwin bug is fixed, you have to darwin-rebuild switch -Q once with this set to false, and then set it to true and do it (without -Q)... (i.e., this breaks the config for bootstrapping)
  # Dec 27 2022: rm if you've bootstrapped a system without seeing this
  fonts = {
    # TODO: follow nix-darwin/issues/752 for when this can
    # rename to fonts.packages (and maybe move to common.nix)
    fonts = shared.fonts;
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
  };

  # below still needs the bootstrap to chsh this.
  environment.shells = with pkgs; [ bashInteractive ];

  environment.systemPackages = with pkgs; with shared; [
  ]
  ++ desktop-apps
  ++ tools
  ++ utils
  ++ gaming
  ;

  system.defaults = {
    # Whether to enable quarantine for downloaded applications.
    LaunchServices.LSQuarantine = false;
    # TODO: refactor/dedupe kludge below w/ other user/homedir refs
    screencapture.location = "/Users/${user.handle}/Desktop";
    dock = {
      autohide = true;
      orientation = "left";
      show-process-indicators = true;
      tilesize = 30;
      mru-spaces = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      _FXShowPosixPathInTitle = true;

      # TODO: I see examples in another file suggesting that you don't actually need a *script* to set non-default options, you just have to make them strings:
      # "com.apple.trackpad.enableSecondaryClick" = true;
      # "com.apple.trackpad.trackpadCornerClickBehavior" = 1;
    };
    trackpad = {
      TrackpadRightClick = true;
    };
    NSGlobalDomain = {
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

  # TODO/DOING: you can live w/ this here for now, but if you
  # create a sparse work config you'd want to leave it out.
  # Basically, don't let this block getting NixOS flaked and
  # updated to 23.11. But this is an obvious next-step.
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
}
