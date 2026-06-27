{ pkgs, ... }:
{
  networking = {
    hostName = "notoast";

    networkmanager.enable = true;
    networkmanager.plugins = with pkgs; [
      networkmanager-openvpn
    ];

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
