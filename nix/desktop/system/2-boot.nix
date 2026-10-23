{
  unstable,
  pkgs,
  config,
  lib,
  ...
}:

{
  boot = {
    loader.systemd-boot.enable = false;
    loader.timeout = 1;
    loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev"; # Use "nodev" when using EFI
      useOSProber = true;

      gfxmodeEfi = "2560x1440";
      backgroundColor = "#000000";
      splashImage = null;
    };

    # kernelPackages = unstable.cachyosKernels."linuxPackages-cachyos-lts-lto-x86_64-v4";
    kernelPackages = unstable.linuxPackages;

    kernelModules = [
      "i2c-dev"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };

  hardware.enableAllFirmware = true;

  systemd.network.wait-online.enable = false;
  systemd.services.NetworkManager-wait-online.wantedBy = lib.mkForce [ ];

  systemd.services.docker.wantedBy = lib.mkForce [ ];
  systemd.sockets.docker = {
    enable = true;
    wantedBy = [ "sockets.target" ];
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/dbbf506e-d359-4253-b4e9-8ea8ccb4a055";
      priority = 2;
    }
    {
      device = "/swapfile";
      priority = 1;
      options = [ "nofail" ];
    }
  ];

}
