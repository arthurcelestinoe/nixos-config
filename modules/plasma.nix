{ ... }:

{
  services.xserver.xkb = {
    layout = "br";
    variant = "abnt2";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  services = {
    power-profiles-daemon.enable = true;
    smartd.enable = true;
    flatpak.enable = true;
    displayManager.ly = {
      enable = true;
      settings.numlock = true;
    };
    desktopManager.plasma6.enable = true;
  };
}