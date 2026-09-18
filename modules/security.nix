{ ... }:

{
  security = {
    lsm = [ "lockdown" "integrity" ];
    rtkit.enable = true;
    sudo.wheelNeedsPassword = true;
    audit.enable = true;
    auditd.enable = true;
  };
}