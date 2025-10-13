{
  networking.hostName = "notoast";
  # networking.wireless.enable = true;

  networking.networkmanager.enable = true;
  networking.nameservers = [
    "192.168.178.100"
    "192.168.178.1"
  ];
  networking.interfaces.enp5s0.wakeOnLan.enable = true;

  networking.firewall.enable = false;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.blueman.enable = true;
}
