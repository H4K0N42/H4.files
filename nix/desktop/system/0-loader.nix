{ ... }:
{
  imports = [
    ./1-config.nix
    ./2-boot.nix
    ./3-nvidia.nix
    ./4-devices.nix
    ./5-network.nix
    ./6-locale.nix
    ./7-packages.nix
    ./8-ai.nix
  ];
}
