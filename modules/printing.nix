{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = [ pkgs.epson-202101w ];
  };
}