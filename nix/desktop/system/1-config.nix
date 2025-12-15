{
  lib,
  pkgs,
  ...
}:
{
  users.users.hagen = {
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
    ];
  };

  security.polkit.enable = true;
  security.rtkit.enable = true; # Pipewire
  xdg.portal.enable = true;

  qt = {
    enable = true;
    style = "adwaita-dark";
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  # nixpkgs.overlays = [
  #   inputs.millennium.overlays.default
  # ];

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

  systemd.timers."flatpak-update" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  systemd.services."flatpak-update" = {
    script = ''
      ${pkgs.flatpak}/bin/flatpak update -y
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
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
