{
  networking = {
    hostName = "notoast";
    # wireless.enable = true;

    networkmanager.enable = true;
    nameservers = [
      "192.168.178.150"
      "192.168.178.1"
    ];
    interfaces.enp5s0.wakeOnLan.enable = true;

    firewall.enable = false;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.blueman.enable = true;
}
