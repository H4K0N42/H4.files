{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # millennium = {
    #   url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    maccel.url = "github:Gnarus-G/maccel";

    #    veyon.url = "path:/home/hagen/Documents/veyon-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nix-cachyos-kernel,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          nix-cachyos-kernel.overlays.default
          # nix-cachyos-kernel.overlays.pinned
        ];
      };
    in
    {
      nixosConfigurations.notoast = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs unstable;
        };
        modules = [
          ./configuration.nix
        ];
      };
    };
}
