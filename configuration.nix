# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{...}:
# I needed this to pass in emacs-overlay, but now I forget how to remove it!
{
  config,
  pkgs,
  ...
}: {

  # go go gadget CPU instructions!
  nixpkgs.hostPlatform = {
    gcc.arch = "znver3";
    gcc.tune = "znver3";
    system = "x86_64-linux";
  };

  nix = {
    # https://github.com/NixOS/nix/issues/11728#issuecomment-2613076734 for download-buffer-size
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      download-buffer-size = 500000000
    '';
    nrBuildUsers = 64;
    settings = {
      system-features = [
        "benchmark"
        "big-parallel"
        "gccarch-alderlake"
        "gccarch-skylake"
        "gccarch-skylake-avx512"
        "gccarch-x86-64-v3"
        "gccarch-znver3"
        "gccarch-znver4"
        "kvm"
        "nixos-test"
      ];
      # auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0; # how many should I allow?
      min-free = 10 * 1024 * 1024;
      max-free = 200 * 1024 * 1024;

      trusted-users = [
        "root"
        "shae"
        "remotebuild"
      ];
      substituters = [
        "http://nix-community.cachix.org"
        "https://cache.iog.io"
        "https://cache.nixos.org"
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
  };

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];
  boot = {
    # kernelPackages = pkgs.linuxPackages_6_17;
    # this WORKS! Why does it fail for znver3 ?!
    kernelPackages = with pkgs; let
      tune = "skylake-avx512";
    in (linuxKernel.packagesFor (
      linux_6_17.override {
        stdenv =
          stdenvAdapters.addAttrsToDerivation {
            env.KCPPFLAGS = "-march=${tune} -O2";
            env.KCFLAGS = "-march=${tune} -O2";
          }
          stdenv;
      }
    ));

    initrd = {
      network.ssh = {
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYlatXccSMal4uwSogKUEfJgrJ3YsH2uSbLFfgz6Vam"
        ];
        enable = true;
      };
    };

    supportedFilesystems = ["zfs"];
    zfs = {
      devNodes = "/dev/disk/by-id";
      extraPools = ["pothole"];
      forceImportRoot = false;
      requestEncryptionCredentials = false; # well this was awkward
    };

    loader = {
      # Bootloader.
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  powerManagement.cpuFreqGovernor = "performance";
  networking = {
    hostName = "huracan"; # Define your hostname.
    hostId = "70516a6a";
    firewall.allowedTCPPorts = [
      22 # ssh
      873 # rsyncd
    ];
    # Enable networking
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = "America/New_York";
  i18n = {
    # Select internationalisation properties.
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  services = {
    # HARDWARE
    fwupd.enable = true;
    fstrim.enable = true;
    bpftune.enable = true;
    smartd = {
      enable = true;
      autodetect = true;
      # the line above means I don't need the line below
      # devices = [
      #   {device = "/dev/sda";}
      #   {device = "/dev/sdb";}
      #   {device = "/dev/sdc";}
      #   {device = "/dev/sdd";}
      #   {device = "/dev/sde";}
      #   {device = "/dev/sdf";}
      # ];
      # this is the default
      # defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04)";
    };

    # thermald.enable = true; # does this work on huracan?

    zfs = {
      autoScrub =  {
        pools = [ "pothole" ];
        interval = [ "monthly" ];
      };
    };

    # GRAPHICS - no, this is a server
    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    xserver.enable = false;

    # Enable the KDE Plasma Desktop Environment.
    # displayManager.sddm.enable = true;
    # desktopManager.plasma6.enable = true;

    # Configure ymap in X11
    xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    printing.enable = true;

    # SOUND - no, this is a server
    # Enable sound with pipewire.
    pulseaudio.enable = false;
    # pipewire = {
    #   enable = true;
    #   alsa.enable = true;
    #   alsa.support32Bit = true;
    #   pulse.enable = true;
    #   # If you want to use JACK applications, uncomment this
    #   #jack.enable = true;

    #   # use the example session manager (no others are packaged yet so this is enabled by default,
    #   # no need to redefine it in your config for now)
    #   #media-session.enable = true;
    # };

    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    # NETWORK

    # Enable the OpenSSH daemon.
    openssh.enable = true;

    avahi = {
      enable = true;
      publish.enable = true;
      publish.userServices = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    rsyncd = {
      enable = true;
    };

  };

  programs = {
    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    bat.enable = true;
    mtr.enable = true;
    nix-ld.enable = true;
    nix-index = {
      # how do I use this again?
      enable = true;
      enableZshIntegration = true;
    };
    htop.enable = true;
    # starship.enable = true;
    # sniffnet.enable = true;
    tcpdump.enable = true;
    zsh.enable = true;
  };
  security.rtkit.enable = true;
  users.groups.remotebuild = {};
  users.users = {
    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    shae = {
      isNormalUser = true;
      description = "shae";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      # packages = with pkgs; [
      # ];
    };
    remotebuild = {
      isSystemUser = true;
      group = "remotebuild";
      useDefaultShell = true;
      openssh.authorizedKeys.keyFiles = [./remotebuild.pub];
    };
  };

  # Install firefox.
  # programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    acpi
    btop
    direnv
    dust
    comma
    fzf
    git
    htop
    ipmitool
    jujutsu
    nix-direnv
    openssl
    pciutils
    screen
    smartmontools
    # starship
    vim
    wget
    zoxide
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
  ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
