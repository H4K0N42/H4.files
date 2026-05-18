{
  config,
  pkgs,
  unstable,
  ...
}:
let
  dots = builtins.toPath ../../..;
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "hagen";
  home.homeDirectory = "/home/hagen";

  programs.bash = {
    enable = true;
    initExtra = ''
      alias y="z"
      # echo
      # fastfetch -s Title:Separator:OS:Host:Kernel:Uptime:Packages:Shell:CPU:GPU:Memory:Swap:Disk:LocalIp:Locale:Break:Colors
    '';
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };
  programs.ghostty.enable = true;
  programs.waybar.enable = true;
  programs.vicinae = {
    enable = true;
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = false;

  home.packages =
    (with pkgs; [
      # mcaselector
      prismlauncher
      blockbench
      texliveFull
      yubioath-flutter
      cryptomator
      arduino-ide
      github-desktop
      zenity
      cool-retro-term
      kdePackages.filelight
      ncdu
      kdePackages.ark
      nautilus
      nautilus-open-any-terminal
      sushi
      code-nautilus
      celluloid
      htop
      playerctl
      geary
      kiwix
      rustup
      mission-center
      appimage-run
      wl-clipboard
      slurp
      audacity
      alsa-utils
      alsa-lib
      ffmpeg-full
      flatpak-builder
      gcc
      fzf
      gitFull
      git-lfs
      wget
      unzip
      curl
      nixd
      gimp3-with-plugins
      gimp3Plugins.gmic
      imagemagick
      spicetify-cli
      clipse
      file-roller
      jq
      vlc
      trash-cli
      xdg-desktop-portal
      killall
      pulseaudio
      scrcpy
      android-tools
      grimblast
      localsend
      blender
      chromium
      element-desktop
      upscayl
      obsidian
      nextcloud-client
      gnome-calculator
      simple-scan
      filezilla
      burpsuite
      linux-wallpaperengine
      helvum
      kdePackages.kleopatra
      kdePackages.kdenlive
      nomacs
      protonup-qt
      dialog
      freerdp
      iproute2
      libnotify
      netcat-openbsd
      onlyoffice-desktopeditors
      gearlever
      dunst
      reaper
      sqlitebrowser
      losslesscut-bin
      gitleaks
      pre-commit
      chatterino7
      pkgs.kdePackages.kate
      meld
      remmina
      nwg-look
      mullvad-vpn
      mullvad-browser
      noriskclient-launcher
      neovim
      lazygit
      dig
      teamspeak6-client
      motrix
      osu-lazer-bin
      lmstudio
      zrythm
      bottles
      lmms
      ardour
      wireshark
      handbrake
      zoom-us
      ###############
      (pkgs.writeShellScriptBin "beeper" "exec ${beeper}/bin/beeper --enable-features=UseOzonePlatform --ozone-platform=x11")
    ])
    ++ [
      unstable.opencode
      unstable.heroic
      unstable.tidal-hifi
      unstable.badlion-client
      unstable.davinci-resolve
      unstable.yt-dlp
      unstable.aseprite
      (unstable.discord.override {
        withVencord = true;
      })
      # unstable.winboat
    ];

  # xdg.desktopEntries.badlion-launcher = {
  #   name = "Badlion Launcher";
  #   genericName = "Badlion Client";
  #   comment = "Launch Badlion via custom script";
  #   exec = "bash ${config.home.homeDirectory}/scripts/launch-badlion.sh";
  #   terminal = false;
  #   type = "Application";
  #   categories = [
  #     "Game"
  #     "Utility"
  #   ];
  #   icon = "application-x-executable"; # Or a proper icon if you have one
  # };

  xdg.desktopEntries.norisk = {
    name = "NoRisk Client";
    exec = "bash /home/hagen/scripts/norisk.sh";
    terminal = false;
    type = "Application";
    categories = [
      "Game"
      "Utility"
    ];
    icon = "application-x-executable"; # Or a proper icon if you have one
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".icons".source = "${dots}/icons";
    ".themes".source = "${dots}/themes";
    "scripts".source = "${dots}/scripts";
    ".config/ghostty/config".source = "${dots}/config/ghostty";
    ".config/hypr" = {
      source = "${dots}/config/hypr";
      onChange = "/run/current-system/sw/bin/hyprctl reload";
    };
    ".config/waybar".source = "${dots}/config/waybar";
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/hagen/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "ghostty";
    __NV_DISABLE_EXPLICIT_SYNC = "1";
  };
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.
}
