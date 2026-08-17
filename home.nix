{ inputs, lib, osConfig, pkgs, ... }:

let
  homeDir = "/home/arthur";
  isHyprland = lib.elem "hyprland" osConfig.system.nixos.tags;
  isPlasma = lib.elem "plasma" osConfig.system.nixos.tags;
  profile = if isHyprland then "hyprland" else if isPlasma then "plasma" else "base";
in {
  # Importar um módulo apenas define opções durante a avaliação. O DMS só entra
  # na closure e cria serviços quando a especialização Hyprland está ativa.
  imports = [ inputs.dms.homeModules.dank-material-shell ];

  home = {
    username = "arthur";
    homeDirectory = homeDir;
    stateVersion = "26.11";

    sessionVariables = {
      XDG_CONFIG_HOME = "${homeDir}/.config/${profile}";
      XDG_CACHE_HOME = "${homeDir}/.cache/${profile}";
      XDG_DATA_HOME = "${homeDir}/.local/share/${profile}";
      XDG_STATE_HOME = "${homeDir}/.local/state/${profile}";
    } // lib.optionalAttrs isHyprland {
      QT_QPA_PLATFORMTHEME = "qt6ct";
    };
  };

  xdg = {
    enable = true;
    configHome = "${homeDir}/.config/${profile}";
    cacheHome = "${homeDir}/.cache/${profile}";
    dataHome = "${homeDir}/.local/share/${profile}";
    stateHome = "${homeDir}/.local/state/${profile}";
  };

  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      # user.name e user.email serão definidos posteriormente.
    };

    fish = {
      enable = true;
      interactiveShellInit = ''
        set --global fish_greeting
      '';

      # Centralize futuros aliases aqui.
      shellAliases = { };
    };

    dank-material-shell = lib.mkIf isHyprland {
      enable = true;

      systemd = {
        enable = true;
        restartIfChanged = true;
      };

      enableSystemMonitoring = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
      enableVPN = true;
      enableCalendarEvents = true;
    };
  };

  # Aplicativos pessoais comuns às especializações Plasma e Hyprland.
  home.packages = with pkgs; [
    onlyoffice-desktopeditors
    spotify
    vscode
  ];
}
