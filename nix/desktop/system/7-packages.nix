{ pkgs, unstable, ... }:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages =
    (with pkgs; [
      speedtest-cli
      rustdesk-flutter
      busybox
      glib
      hyprpolkitagent
      pciutils
      util-linux
      vscode
      nixfmt-rfc-style
      bluez
      bluez-tools
      wireplumber
      hyprland-qtutils
      appimage-run
      mesa
      vulkan-loader
      docker
      docker-compose
      wineWowPackages.waylandFull
      libnotify
      libGL
      gvfs
      gpu-screen-recorder
      hplipWithPlugin
      spice-gtk
      ghostty
      cudatoolkit
      pinentry-qt
      fastfetch
      htop
      python3Full
      adafruit-ampy
      adwaita-icon-theme
      hicolor-icon-theme
      adwaita-qt
      gparted
      ntfs3g
      bitwarden-cli
      caligula
      xdg-desktop-portal-hyprland
      v4l-utils
      usbutils
    ])
    ++ [
    ];
  # Services
  services = {
    xserver = {
      enable = false;
      deviceSection = ''
        Option "Coolbits" "10"
      '';
    };

    displayManager.ly.enable = true;

    # displayManager.enable = true;
    # greetd = {
    #   enable = true;
    #   settings = {
    #     default_session = {
    #       command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --user-menu --asterisks --cmd hyprland";
    #       user = "greeter";
    #     };
    #   };
    # };

    # ./devices: fileSystems
    gvfs.enable = true;
    davfs2.enable = true;

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

    gnome.gnome-keyring.enable = true;

    yubikey-agent.enable = true;
    pcscd.enable = true;

    flatpak.enable = true;

    kmscon = {
      enable = true;
      # fonts = [
      #   {
      #     name = "JetBrainsMono Nerd Font Mono";
      #     package = pkgs.nerd-fonts.jetbrains-mono;
      #   }
      # ];
    };
    printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        hplip
        hplipWithPlugin
        splix
      ];
      startWhenNeeded = true;
    };
    preload = {
      enable = true;
      package = pkgs.preload;
    };
    fwupd.enable = true;
  };

  # Programs
  programs = {

    hyprland = {
      enable = true;
      xwayland.enable = true;
      package = unstable.hyprland;
    };

    steam = {
      enable = true;
      # package = pkgs.steam-millennium;
      protontricks.enable = true;
      extraPackages = with pkgs; [
        # gamescope
        gamemode
      ];
    };

    gamemode = {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          renice = 10;
          desiredgov = "performance";
          defaultgov = "powersave";
          ioprio = 0;
        };

        # Warning: GPU optimisations have the potential to damage hardware
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 1;
          nv_powermizer_mode = 1;
        };

        # custom = {
        #   start = "";
        #   end = "";
        # };
      };
    };
    # gamescope = {
    #   enable = true;
    #   capSysNice = true;
    # };

    bat = {
      enable = true;
      settings = {
        pager = "less";
        paging = "never";
        theme = "ansi";
        style = "plain";
      };
      extraPackages = with pkgs.bat-extras; [
        core
      ];
    };

    yazi.enable = true;
    weylus = {
      enable = false;
      users = [ "hagen" ];
    };

    obs-studio = {
      enable = true;
      enableVirtualCamera = true;
      package = (
        pkgs.obs-studio.override {
          cudaSupport = true;
        }
      );
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-vkcapture
        obs-pipewire-audio-capture
        obs-backgroundremoval
        droidcam-obs
      ];
    };

    yubikey-touch-detector.enable = true;

    java.enable = true;
    hyprlock.enable = true;
    noisetorch.enable = true;
    streamcontroller.enable = true;
    gpu-screen-recorder.enable = true;
    adb.enable = true;
    virt-manager.enable = true;
    gnupg.agent.enable = true;
    gnupg.agent.pinentryPackage = pkgs.pinentry-qt;
    thefuck.enable = true;
  };

  # Virtualisation

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf.enable = true;
      };
    };
  };
}
