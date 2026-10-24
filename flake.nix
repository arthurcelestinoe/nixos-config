{
  description = "Configuração NixOS de Arthur";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    harmony-music.url = "github:theblackcoderbr/Harmony-Music/feat/nix-flake";

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
      lib = nixpkgs.lib;
      overlays = [
        (import ./overlays/default.nix)
        (import ./overlays/vinyl.nix { inherit vinyl-theme; })
      ];
      harmonyMusicModule = {
        environment.systemPackages = [
          inputs.harmony-music.packages.${system}.default
        ];
      };
      notebookHardwareFile = ./hosts/notebook/hardware-configuration.nix;
      notebookHardwareReady = !(lib.hasInfix "Substitua este arquivo" (builtins.readFile notebookHardwareFile));
    in {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            { nixpkgs.overlays = overlays; }
            harmonyMusicModule
            ./hosts/desktop
          ];
        };
      } // lib.optionalAttrs notebookHardwareReady {
        notebook = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            { nixpkgs.overlays = overlays; }
            harmonyMusicModule
            ./hosts/notebook
          ];
        };
      };
    };
}
