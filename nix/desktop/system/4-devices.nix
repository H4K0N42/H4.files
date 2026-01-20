{ pkgs, ... }:

{
  # hardware.printers.ensurePrinters = [
  #   {
  #     name = "hp-m283fdw";
  #     deviceUri = "socket://192.168.178.78";
  #     model = "HP/hp-color_laserjet_pro_mfp_m277-ps.ppd.gz";
  #   }
  # ];

  hardware.sane = {
    enable = true;
    extraBackends = [
      pkgs.hplipWithPlugin
      pkgs.sane-airscan
    ];
  };

  hardware.maccel = {
    enable = true;
    enableCli = true; # Optional: for parameter discovery
    parameters = {
      sensMultiplier = 0.6;
      inputDpi = 1600.0;
      mode = "no_accel";

      decayRate = 0.3;
      offset = 0.5;
      limit = 1.8;
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="1e7d", ATTRS{idProduct}=="2fee", TAG+="uaccess", TAG+="ROCCAT_Vulcan_TKL"
    SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="1e7d", ATTRS{idProduct}=="2e2c", TAG+="uaccess", TAG+="ROCCAT_Kone_Aimo_16K"
    SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="0d8c", ATTRS{idProduct}=="0135", TAG+="uaccess", TAG+="CMEDIA_Q9_1"
    SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="0c04", TAG+="uaccess", TAG+="RAZER_Firefly_V2"
    SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="0528", TAG+="uaccess", TAG+="RAZER_BlackShark_V2_Pro"
    SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="256c", ATTRS{idProduct}=="006d", TAG+="uaccess", TAG+="GAOMON_Tablet"
    SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", TAG+="Yubico_YubiKey"
    SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="19af", TAG+="uaccess", TAG+="Asus_AURA_LED_Controller"

    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0063", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0090", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0060", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006d", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006c", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="008f", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0080", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0084", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0086", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="009a", TAG+="uaccess"
  '';

  fileSystems."/mnt/nextcloud" = {
    device = "https://cloud.h4k0n.dev/remote.php/webdav";
    fsType = "davfs";
    options = [
      "noauto" # Don't mount at boot
      "x-systemd.automount" # Mount on first access
      "rw"
      "_netdev"
      "uid=1000"
      "gid=100"
      "umask=0022"
      "nofail"
    ];
  };

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/2E447A3E447A093B";
    fsType = "ntfs3";
    options = [
      # "defaults"
      "noauto" # Don't mount at boot
      "x-systemd.automount" # Mount on first access
      "uid=1000"
      "gid=100"
      "dmask=007"
      "fmask=007"
      "nofail"
      "force"
    ];
  };

  fileSystems."/mnt/hdd" = {
    device = "/dev/disk/by-uuid/D29C58169C57F407";
    fsType = "ntfs3";
    options = [
      # "defaults"
      "noauto" # Don't mount at boot
      "x-systemd.automount" # Mount on first access
      "x-systemd.device-timeout=0"
      "uid=1000"
      "gid=100"
      "dmask=007"
      "fmask=007"
      "nofail"
    ];
  };

  fileSystems."/mnt/nfs" = {
    device = "192.168.178.150:/";
    fsType = "nfs";
    options = [
      "rw" # read/write
      "x-systemd.automount"
      "noatime"
      "vers=4"
      "nofail"
      "_netdev"
      "hard"
    ];
  };

}
