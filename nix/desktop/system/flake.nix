{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-bleeding-edge.url = "github:nixos/nixpkgs/master";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    millennium.url = "git+https://github.com/SteamClientHomebrew/Millennium";
    # millennium.url = "git+https://github.com/H4K0N42/Millennium";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-bleeding-edge,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      bleeding-edge = import nixpkgs-bleeding-edge {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.notoast = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs unstable bleeding-edge;
        };
        modules = [ ./configuration.nix ];
      };
    };
}
