{ config, lib, ... }:

let
  efiMountPoints = lib.filter
    (mountPoint:
      lib.hasPrefix "/boot" mountPoint
      && lib.elem config.fileSystems.${mountPoint}.fsType [ "vfat" "fat32" ])
    (builtins.attrNames config.fileSystems);
  efiMountPoint = if efiMountPoints == [ ] then null else builtins.head efiMountPoints;
in

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/development.nix
    ../../modules/plasma.nix
    ../../modules/printing.nix
    ../../modules/security.nix
  ];

  networking.hostName = "Arthur-PC";

  hardware.graphics.enable32Bit = true;
  programs.steam.enable = true;

  assertions = [
    {
      assertion = efiMountPoint != null;
      message = "Nenhuma particao EFI FAT montada sob /boot foi encontrada em hardware-configuration.nix.";
    }
  ];

  boot.loader = {
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

  system.stateVersion = "26.11";
}