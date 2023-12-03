{ config, inputs, system, pkgs, shared, user, modulesPath, ... }:

{
  imports =[
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.kernelModules = [ "coretemp" "nct6775" "snd-seq" "snd-rawmidi" "v4l2loopback" ];
  boot.extraModulePackages = [ ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; with shared; [
    # audio
    pavucontrol pa_applet qjackctl

    #printer drivers
    brgenml1cupswrapper
    brgenml1lpr

    # DSLR on nixos?
    gphoto2
    ffmpeg
    linuxPackages.v4l2loopback
  ]
  ++ desktop-apps
  ++ tools
  ++ utils
  ++ gaming
  ;

  fonts = {
    enableGhostscriptFonts = true;

    fontconfig = {
      defaultFonts = {
        monospace = [ "inconsolata" ];
      };
    };
    # I guess some of this stuff could be an override
    packages = with pkgs; [
      # corefonts # unfree
      # symbola # unfree
      ubuntu_font_family
      # vistafonts # unfree
    ]
    ++ shared.fonts;
  };

  hardware = {
    bluetooth.enable = true;
    opengl.driSupport32Bit = true;
  };

  inherit (shared) location;

  programs = {
    light.enable = true;
  };

  # note: audio has been painful; may have cargo-culting
  # consult old main.nix for old settings if it breaks?
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
    pulse.enable = true;
  };

  # List services that you want to enable:
  services = {

    # Enable the OpenSSH daemon.
    openssh.enable = true;

    kmscon = {
      enable = true;
      extraConfig = ''font-name=Inconsolata'';
    };

    # system won't properly resume without dhcpcd enabled https://www.mail-archive.com/nix-commits@lists.science.uu.nl/msg17936.html
    # dhcpd4.enable = true;
    #
    # TODO: DISABLED PER BELOW, BUT ENSURE MY SYSTEM DOESN'T
    #       REGRESS ON THE ABOVE PROBLEM
    #
    # Failed assertions:
    #    - The option definition `services.dhcpd4' in `/nix/store/0mffwqwj69llzk8bfnh160vg9zv6xz3g-source/nixos.nix' no longer has any effect; please remove it.
    #    The dhcpd4 module has been removed because ISC DHCP reached its end of life.
    #    See https://www.isc.org/blogs/isc-dhcp-eol/ for details.
    #    Please switch to a different implementation like kea or dnsmasq.

    # Enable CUPS to print documents.
    printing = {
      enable = true;
      drivers = [pkgs.brgenml1cupswrapper
      pkgs.brgenml1lpr];
    };
    avahi.enable = true;

    # Enable the X11 windowing system.
    xserver = {
      enable = true;
      layout = "us";
      videoDrivers = [ "nvidia" ];
      # Enable the KDE Desktop Environment.
      displayManager.sddm = {
        enable = true;
        autoNumlock = true;
      };
      desktopManager.plasma5.enable = true;
      wacom.enable = true;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers."${user.handle}" = {
    createHome = true;
    extraGroups = [ "wheel" "vboxusers" "audio" "video" "docker" "jackaudio" ];
    group = "users";
    home = "/home/${user.handle}";
    isNormalUser = true;
    uid = 1000;
  };

  #virtualisation.virtualbox.host.enable = true;
  virtualisation.docker.enable = true;
}
