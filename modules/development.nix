{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gcc
    gdb
    gutenprint
  ];

  programs.git = {
    enable = true;
    config.user = {
      name = "TheBlackCoder";
      email = "320399680+theblackcoderbr@users.noreply.github.com";
    };
  };
}