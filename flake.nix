{
  description = "Configuração NixOS do desktop de Arthur";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    ashyterm = {
      url = "github:big-comm/ashyterm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # O Vinyl ainda não faz parte do Nixpkgs. O código-fonte é fixado no
    # flake.lock e compilado pelo overlay abaixo.
    vinyl-theme = {
      url = "github:ekaaty/vinyl-theme";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, vinyl-theme, ... }:
    let
      system = "x86_64-linux";

      vinylOverlay = final: _prev: {
        vinyl-theme = final.stdenv.mkDerivation {
          pname = "vinyl-theme";
          version = "unstable";
          src = vinyl-theme;

          nativeBuildInputs = [
            final.cmake
            final.pkg-config
            final.kdePackages.extra-cmake-modules
            final.kdePackages.wrapQtAppsHook
            final.kdePackages.qttools
            final.python3Packages.cairosvg
            final.python3Packages.lxml
            final.unzip
            final.xcursorgen
          ];
          postPatch = ''
            patchShebangs cursors
          
            substituteInPlace icons/src/places/scalable/links.txt \
              --replace-fail \
                "start-here-kde.svg ./start-here-kde-plasma.svg" \
                "../../apps/scalable/start-here-kde.svg ./start-here-kde-plasma.svg"
          '';

          buildInputs = [
            final.libepoxy
            final.kdePackages.kcolorscheme
            final.kdePackages.kconfig
            final.kdePackages.frameworkintegration
            final.kdePackages.kguiaddons
            final.kdePackages.ki18n
            final.kdePackages.kiconthemes
            final.kdePackages.kcmutils
            final.kdePackages.kcoreaddons
            final.kdePackages.kdecoration
            final.kdePackages.kirigami
            final.kdePackages.kwayland
            final.kdePackages.kwin
            final.kdePackages.libplasma
            final.kdePackages.qt5compat
            final.kdePackages.qtbase
            final.kdePackages.qtdeclarative
            final.kdePackages.kwindowsystem
          ];

          cmakeFlags = [ "-DBUILD_TESTING=OFF" ];

          meta = {
            description = "Tema Vinyl para KDE Plasma 6";
            homepage = "https://github.com/ekaaty/vinyl-theme";
            license = final.lib.licenses.gpl3Plus;
            platforms = final.lib.platforms.linux;
          };
        };
      };

      localPackagesOverlay = final: _prev: {
        freedownloadmanager = final.callPackage ./packages/freedownloadmanager.nix { };
        ashy-terminal =
          inputs.ashyterm.packages.${final.stdenv.hostPlatform.system}.ashyterm-all.overrideAttrs
            (oldAttrs: {
              postInstall = (oldAttrs.postInstall or "") + ''
                substituteInPlace $out/bin/ashyterm \
                  --replace-fail \
                    'execute_ashy="python3 __init__.py"' \
                    'execute_ashy="python3 -m ashyterm"'
              '';
            });
      };
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          { nixpkgs.overlays = [ vinylOverlay localPackagesOverlay ]; }
          ./configuration.nix
        ];
      };
    };
}
