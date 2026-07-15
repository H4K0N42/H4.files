{
  pkgs,
  unstable,
  inputs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages =
    (with pkgs; [
      speedtest-cli
      rustdesk-flutter
      busybox
      gtk3
      glib
      gsettings-desktop-schemas
      pciutils
      util-linux
      vscode
      nixfmt
      bluez
      bluez-tools
      wireplumber
      appimage-run
      mesa
      vulkan-loader
      docker
      docker-compose
      wineWow64Packages.waylandFull
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
      python3
      adafruit-ampy
      adwaita-icon-theme
      hicolor-icon-theme
      adwaita-qt
      gparted
      ntfs3g
      bitwarden-cli
      caligula
      v4l-utils
      usbutils
      nix-tree
      quickshell
      nvd
      nil
      smartmontools
      # hyprland-qtutils
      # hyprls
      # hyprpaper
      # hyprsunset
      # hyprpicker
      # hyprland-qt-support
      # hyprpolkitagent
      hyprshot
      # xdg-desktop-portal-hyprland
      gamescope
      android-tools
      xwayland-satellite
      kdePackages.polkit-kde-agent-1
      libXrandr
      libX11
    ])
    ++ [
      unstable.zed-editor-fhs
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

    greetd = {
      enable = false;
      settings = rec {
        initial_session = {
          command = "niri-session";
          user = "hagen";
        };
        default_session = initial_session; # note: this probably isn't what you want (you might want to use tuigreet or something)
      };
    };

    # displayManager.sddm = {
    #   enable = true;
    #   wayland.enable = true;
    #   autoLogin.relogin = false;
    # };
    # displayManager.autoLogin = {
    #   enable = true;
    #   user = "hagen";
    # };

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
    fwupd.enable = true;

    hardware.openrgb = {
      enable = true;
      package = unstable.openrgb-with-all-plugins;
      motherboard = "intel";
    };
  };

  # Programs
  programs = {

    nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "daily";
        extraArgs = "--keep 5 --keep-since 7d --optimise";
      };
    };

    niri.enable = true;
    xwayland.enable = true;

    hyprland = {
      enable = false;
      xwayland.enable = true;
      # package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    };

    steam = {
      enable = true;
      # package = pkgs.millennium-steam;
      protontricks.enable = true;
      gamescopeSession.enable = true;
      extraPackages = with pkgs; [
        gamemode
        gamescope
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

    # bat = {
    #   enable = true;
    #   settings = {
    #     pager = "less";
    #     paging = "never";
    #     theme = "ansi";
    #     style = "plain";
    #   };
    #   extraPackages = with pkgs.bat-extras; [
    #     core
    #   ];
    # };

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
    nix-index.enable = true;
    java.enable = true;
    noisetorch.enable = true;
    streamcontroller.enable = true;
    gpu-screen-recorder.enable = true;
    virt-manager.enable = true;
    gnupg.agent.enable = true;
    gnupg.agent.pinentryPackage = pkgs.pinentry-qt;
    pay-respects.enable = true;
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
      };
    };
  };
}
