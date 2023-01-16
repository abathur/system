{ stdenv, pkgs }:

{
    dns = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
        "8.8.4.4"
    ];

    fonts = with pkgs; [
        fira-code
        gentium
    ];

    desktop-apps = with pkgs; [
        # Not 100% certain that the mere fact that these *can* be installed cross-platform means I want to do it this way.
        # firefox FF doesn't seem to want to build on macos atm
        mpv
    ] ++ lib.optionals stdenv.isLinux [
    # FWIW, some of these linux-only apps could have overlays that'll install an appropriate macos app package. Not quite sure how I want to do this yet.
        google-chrome
        # libreoffice
        qdirstat # Disk Inventory X is the darwin equivalent
        spotify
        sublime3
        zeal
        (pkgs.lib.setPrio 9 cni)
        # image viewer;
        # nomacs
        # obs-studio
    ];

    # TODO: either better distinguish tools/utils or collapse them
    utils = with pkgs; [
        # tempting to just figure out how to include stdenv, since I want a chunk
        gnumake gzip gnused bzip2 gawk ed xz patch gnugrep coreutils findutils diffutils patchutils
        htop
        iftop
        jnettop
        time #gtime/gnu-time in homebrew; not sure if we spec globally or just for darwin?
        # nixops
    ]
    ++ lib.optionals stdenv.isLinux [
        # not sure how thoroughly needed these sensors are; disabling
        # but keeping the list for reference
        # atop
        # ftop
        # iotop
        # powertop
        # radeontop
        # tiptop
        # lm_sensors #hw sensors?
        # psensor # gpu monitoring?
        # jmtpfs # mounting android devices
        # nvme-cli # managing nvme devices
        # lsof # seems to be at /usr/sbin/lsof by default on macos; assume it's not on nixos
        # mprime # can be in macos, but build currently breaks...
    ];

    gaming = with pkgs; [
        tintin
    ] ++ lib.optionals stdenv.isLinux [
        openra # open C&C engine (maybe red-alert only?)
        steam
    ];

    tools = with pkgs; [
        bc
        bat
        curl
        exa
        rsync
        wget
        lynx
        sqlite-interactive
        textql
        dateutils
        jq
        # TODO: some deps, like smenu/zenity/mgitstatus, are really here for my persistence.sh/test script. I'm not sure it can be a package/module, since it's also part of my bootstrap--but it can at least be a nix-shell shebang, so I may not need these on path any longer.
        # smenu
        # gnome.zenity # TODO: re-enable once I'm using a nixpkgs where my platform fix is present
        # multi-git-status

        comma
        gnupg
        gitFull
        openssh
        yadm
        nixpkgs-review
        nix-prefetch
        rustfmt
        shellcheck
        shfmt
        # Mostly for ST3 plugins; projects should define
        # their own
        # TODO: you've whittled this list down a lot over time
        #       maybe just add black by itself?
        #       drop this whole block if it's still here after may 2023
        (python3.withPackages (ps: with ps; [
            black
            aiohttp # I had a note that this was for a bugfix but idk which plugin
        ]))
        # black
    ] ++ lib.optionals stdenv.isDarwin [
    ];
}
