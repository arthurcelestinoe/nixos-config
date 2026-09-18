{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    blacklistedKernelModules = lib.mkForce [ ];
    kernelModules = [ "usblp" ];
    kernelParams = [ "lockdown=integrity" "udev.log_level=3" "rd.udev.log_level=3" ];
    consoleLogLevel = 3;
    initrd.verbose = false;
  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    graphics.enable = true;
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
    sane = {
      enable = true;
      extraBackends = [ pkgs.epsonscan2 ];
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "pt_BR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  programs = {
    appimage = {
      enable = true;
      binfmt = true;
    };
    fish = {
      enable = true;
      interactiveShellInit = ''
        set --global fish_greeting
      '';
    };
    kdeconnect.enable = true;
    ssh.startAgent = true;
  };

  users = {
    mutableUsers = true;
    users = {
      root.hashedPassword = "!";
      arthur = {
        isNormalUser = true;
        description = "Arthur";
        shell = pkgs.fish;
        extraGroups = [ "wheel" "networkmanager" "lp" "scanner" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    firefox
    freedownloadmanager
    nano
    fastfetch
    ayugram-desktop
    antigravity-ide
    onlyoffice-desktopeditors
    spotify
    vscode
    ashy-terminal
    vinyl-theme
    vim
    btop
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kate
    kdePackages.gwenview
    kdePackages.spectacle
    kdePackages.okular
    kdePackages.elisa
    kdePackages.dragon
    kdePackages.kcalc
    epsonscan2
  ];

  systemd.tmpfiles.rules = [
    "L+ /opt/freedownloadmanager - - - - ${pkgs.freedownloadmanager}/opt/freedownloadmanager"
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    hack-font
    adwaita-fonts
    unifont
  ];
}