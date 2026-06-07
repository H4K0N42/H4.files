{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  users = {
    users.hagen = {
      isNormalUser = true;
      description = "Hagen";
      extraGroups = [
        "networkmanager"
        "wheel"
        "davfs2"
        "input"
        "docker"
        "video"
        "gamemode"
        "libvirtd"
        "libvirt"
        "qemu-libvirtd"
        "kvm"
        "lp"
        "dialout"
        "maccel"
        "nextcloud"
      ];
    };
    groups.nextcloud = {
      gid = 33;
    };
  };

  security.polkit.enable = true;
  security.rtkit.enable = true; # Pipewire
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    config = {
      common = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Access" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
  };

  qt = {
    enable = true;
    style = "adwaita-dark";
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  # nixpkgs.overlays = [ inputs.millennium.overlays.default ];

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "hagen"
      ];
      substituters = [
        # "https://cache.garnix.io" RIP garnix
        "https://attic.xuyh0120.win/lantian"
      ];
      trusted-public-keys = [
        # "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ];
    };

    gc = {
      automatic = true;
      dates = "daily";
      persistent = true;
      options = "--delete-older-than 7d";
    };

    optimise = {
      automatic = true;
      dates = [ "daily" ];
      persistent = true;
    };
  };

  services.clamav = {
    daemon.enable = false;
    updater.enable = false;
    fangfrisch.enable = false;
  };

  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin/bw - - - - ${lib.getExe' pkgs.bitwarden-cli "bw"}"
  ];
}
