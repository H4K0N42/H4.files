# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./1-config.nix
    ./2-boot.nix
    ./3-nvidia.nix
    ./4-devices.nix
    ./5-network.nix
    ./6-locale.nix
    ./7-packages.nix
    ./8-ai.nix
    inputs.maccel.nixosModules.default
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
