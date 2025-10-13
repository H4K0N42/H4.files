{
  pkgs,
  config,
  lib,
  unstable,
  ...
}:

{
  boot.loader.systemd-boot.enable = false;
  boot.loader.timeout = 1;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev"; # Use "nodev" when using EFI
    useOSProber = true;

    gfxmodeEfi = "2560x1440";
    backgroundColor = "#000000";
    splashImage = null;
  };

  boot.kernelPackages = pkgs.linuxPackages; # LTS
  # boot.kernelPackages = unstable.linuxPackages;
  # boot.kernelPackages = unstable.linuxPackages_latest;

  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';
  boot.blacklistedKernelModules = [ "nouveau" ];

  systemd.network.wait-online.enable = false;
  systemd.services.docker.wantedBy = lib.mkForce [ ];
  systemd.sockets.docker = {
    enable = true;
    wantedBy = [ "sockets.target" ];
  };

}
