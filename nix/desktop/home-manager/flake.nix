{
  description = "Home Manager configuration of hagen";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-bleeding-edge.url = "github:nixos/nixpkgs/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dots.url = "git+file:///home/hagen/H4.files";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixpkgs-unstable,
      nixpkgs-bleeding-edge,
      dots,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
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
      homeConfigurations."hagen" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
        extraSpecialArgs = {
          inherit unstable bleeding-edge dots;
        };
      };
    };
}
