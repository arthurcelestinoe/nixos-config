{ config, lib, pkgs, ... }:

let
  # O hardware-configuration.nix definirá onde a ESP foi montada. Procuramos
  # uma partição FAT sob /boot para que GRUB e o arquivo fallback usem o mesmo
  # ponto de montagem, seja /boot ou /boot/efi.
  efiMountPoints = lib.filter
    (mountPoint:
      lib.hasPrefix "/boot" mountPoint
      && lib.elem config.fileSystems.${mountPoint}.fsType [ "vfat" "fat32" ])
    (builtins.attrNames config.fileSystems);
  efiMountPoint = if efiMountPoints == [ ] then null else builtins.head efiMountPoints;

in
{
  imports = [ ./hardware-configuration.nix ];

  assertions = [
    {
      assertion = efiMountPoint != null;
      message = ''
        Nenhuma partição EFI FAT montada sob /boot foi encontrada em
        hardware-configuration.nix. Monte a ESP em /boot ou /boot/efi e gere
        novamente o arquivo.
      '';
    }
  ];

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

    kernelParams = [
      "lockdown=integrity"
      "udev.log_level=3"
      "rd.udev.log_level=3"
    ];

    consoleLogLevel = 3;
    initrd.verbose = false;

    loader = {
      efi = {
        canTouchEfiVariables = false;
        efiSysMountPoint = efiMountPoint;
      };

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
        useOSProber = false;
        configurationLimit = 10;
        default = 0;

      };
    };

  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;

    graphics.enable = true;

    bluetooth = {
      enable = true;
      # Não força o rádio a ligar: o estado salvo pelo rfkill é respeitado.
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
    hostName = "nixos";
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

  services = {
    xserver.xkb = {
      layout = "br";
      variant = "abnt2";
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    power-profiles-daemon.enable = true;
    smartd.enable = true;
    flatpak.enable = true;

    displayManager.ly = {
      enable = true;
      settings.numlock = true;
    };

    desktopManager.plasma6.enable = true;

    printing = {
      enable = true;
      drivers = [ pkgs.epson-202101w ];
    };
  };

  security = {
    lsm = [ "lockdown" "integrity" ];
    rtkit.enable = true;
    sudo.wheelNeedsPassword = true;
    audit.enable = true;
    auditd.enable = true;
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

    git = {
      enable = true;
      config.user = {
        name = "TheBlackCoder";
        email = "320399680+theblackcoderbr@users.noreply.github.com";
      };
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
    antigravity
    onlyoffice-desktopeditors
    spotify
    vscode
    ashy-terminal
    vinyl-theme

    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kate
    kdePackages.gwenview
    kdePackages.spectacle
    kdePackages.okular
    kdePackages.elisa
    kdePackages.dragon
    epsonscan2
  ];

  # Mantém a árvore já usada pelo Plasma. A migração para os caminhos XDG
  # padrão pode ser feita separadamente, sem fazer a sessão parecer zerada.
  environment.sessionVariables = {
    XDG_CONFIG_HOME = "/home/arthur/.config/plasma";
    XDG_CACHE_HOME = "/home/arthur/.cache/plasma";
    XDG_DATA_HOME = "/home/arthur/.local/share/plasma";
    XDG_STATE_HOME = "/home/arthur/.local/state/plasma";
  };

  # O FDM e seu host de integração com navegadores usam caminhos absolutos
  # sob /opt no pacote oficial. O link é recriado declarativamente a cada boot.
  systemd.tmpfiles.rules = [
    "L+ /opt/freedownloadmanager - - - - ${pkgs.freedownloadmanager}/opt/freedownloadmanager"
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    hack-font
    adwaita-fonts
    unifont
  ];

  # Marcador de compatibilidade de uma instalação nova no ciclo 26.11.
  # Não alterar nas atualizações normais do nixos-unstable.
  system.stateVersion = "26.11";
}
