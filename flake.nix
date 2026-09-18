{
  description = "Configuração NixOS de Arthur";

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

  outputs = inputs@{ nixpkgs, vinyl-theme, ashyterm, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      overlays = [
        (import ./overlays/default.nix { inherit ashyterm; })
        (import ./overlays/vinyl.nix { inherit vinyl-theme; })
      ];
      notebookHardwareFile = ./hosts/notebook/hardware-configuration.nix;
      notebookHardwareReady = !(lib.hasInfix "Substitua este arquivo" (builtins.readFile notebookHardwareFile));
    in {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            { nixpkgs.overlays = overlays; }
            ./hosts/desktop
          ];
        };
      } // lib.optionalAttrs notebookHardwareReady {
        notebook = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            { nixpkgs.overlays = overlays; }
            ./hosts/notebook
          ];
        };
      };
    };
}
