{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
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
    # hyprland = {
    #   url = "github:hyprwm/Hyprland/v0.52.1";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # veyon.url = "github:veyon/veyon";
    # veyon.url = "git+https://github.com/H4K0N42/veyon.git?submodules=1";
    # veyon.url = "path:/home/hagen/Documents/GitHub/veyon";
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
          # inputs.veyon.nixosModules.default
          ./configuration.nix
        ];
      };
    };
}
