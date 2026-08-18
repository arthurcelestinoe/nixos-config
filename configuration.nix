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

  # Cada ambiente gráfico recebe árvores XDG próprias. Isso também impede que
  # environment.d, kdeglobals, qt6ct e configurações do DMS sejam lidos pela
  # outra sessão.
  mkXdgSession = profile: {
    XDG_CONFIG_HOME = "/home/arthur/.config/${profile}";
    XDG_CACHE_HOME = "/home/arthur/.cache/${profile}";
    XDG_DATA_HOME = "/home/arthur/.local/share/${profile}";
    XDG_STATE_HOME = "/home/arthur/.local/state/${profile}";
  };
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

  # A Action atualiza flake.lock no GitHub antes do meio-dia. A máquina apenas
  # prepara a nova geração; nada é ativado até o próximo boot.
  system.autoUpgrade = {
    enable = true;
    flake = "github:arthurcelestinoe/nixos-config#nixos";
    dates = "19:00";
    randomizedDelaySec = "15min";
    operation = "boot";
    allowReboot = false;
    flags = [ "--refresh" ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "lsm=landlock,lockdown,yama,integrity,bpf"
      "lockdown=confidentiality"
      "audit=1"
      "quiet"
      "splash"
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
        useOSProber = true;
        configurationLimit = 10;
        default = 2;
      };
    };

    plymouth = {
      enable = true;
      theme = "breeze";
      themePackages = [ pkgs.kdePackages.breeze-plymouth ];
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

    printing = {
      enable = true;
      - drivers = [ pkgs.epson-escpr2 ];
      + drivers = [ pkgs.epson-202101w ];
    };
  };

  security = {
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

    fish.enable = true;
    kdeconnect.enable = true;
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

    kdePackages.dolphin
    kdePackages.ark
    kdePackages.konsole
    kdePackages.kate
    kdePackages.gwenview
    kdePackages.spectacle
    kdePackages.okular
    kdePackages.elisa
    kdePackages.dragon
    epsonscan2
  ];

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

  # A configuração pai contém apenas a base comum. Cada ambiente gráfico é
  # construído como uma closure própria e aparece como especialização no GRUB.
  # Assim, portais, agentes e serviços de sessão não vazam entre os ambientes.
  specialisation = {
    plasma.configuration = {
      system.nixos.tags = [ "plasma" ];
      boot.loader.grub.configurationName = "Plasma";
      environment.sessionVariables = mkXdgSession "plasma";

      services.flatpak.enable = true;

      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        settings.General.Numlock = "on";
      };
      services.desktopManager.plasma6.enable = true;

      environment.systemPackages = [ pkgs.vinyl-theme ];
    };

    hyprland.configuration = {
      system.nixos.tags = [ "hyprland" "dms" ];
      boot.loader.grub.configurationName = "Hyprland + DMS";

      services.flatpak.enable = true;

      environment = {
        sessionVariables = (mkXdgSession "hyprland") // {
          QT_QPA_PLATFORMTHEME = "qt6ct";
        };
        systemPackages = [ pkgs.kdePackages.qt6ct ];
      };

      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };

      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      # O portal do Hyprland continua responsável pela integração com o
      # compositor. Somente FileChooser é direcionado ao seletor do COSMIC.
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];
        config.hyprland = {
          default = [ "hyprland" "cosmic" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "cosmic" ];
        };
      };
    };
  };

  # Marcador de compatibilidade de uma instalação nova no ciclo 26.11.
  # Não alterar nas atualizações normais do nixos-unstable.
  system.stateVersion = "26.11";
}
