# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./1-config.nix
    ./2-boot.nix
    ./3-nvidia.nix
    ./4-devices.nix
    ./5-network.nix
    ./6-locale.nix
    ./7-packages.nix
    ./8-ai.nix
    inputs.maccel.nixosModules.default
  ];

  # services.veyon = {
  #   enable = true;
  #   publicKey = {
  #     name = "LGY-NixOS";
  #     value = ''
  #       -----BEGIN PUBLIC KEY-----
  #       MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAyDNqvh1Yuw2T6Z2u0MYc
  #       xcaCQuQYTyslIjKN5w6VeCKnmMzhG+pCEB4ka/JdRp2rf5pl+6ZK1hvK+inL2ngn
  #       FtZA48pu3fXa0D92VBZsZgsbDBqfJ6l9tK1tBvCrEw3wcA3Lx7MYCkR5rbShC5M2
  #       ZjntGKmkmhTFq9xRAWc0oTLIqrjwPN67jpSLCvnAf+N8YUanzDzud13M+nn0JkAi
  #       XfMybnHkqp09R1n6w0IBB1hXunJgMu2fdZ6e0fzQVP0KfrB2JOyB89lAXUw40VAV
  #       27MF/bFcCOE2skZu1dazB8TvjlmAPjLhKhJZr1ERJ2H2Fhrj4x5V2zXC0bqkEyXa
  #       kaH0YnSEn8idtGdeKbSkALG67tYDdfS1g8vrs/4d5xi4nPWp1c+tQtX842lDiQ+8
  #       GsROOA1jUgFkCPmljxIuG7wyetv6iOhRzpUWKndkuIJYBJzDKca1X8oPpkmgduWz
  #       OBGYrutUVdfIImPLrWUFpra+2I48Dhd1u2wPLmjTmPnEeDfePWjpxrEQNleN6EQi
  #       CBnmUvkw6kv2urfAVxMz6ySnn8uui7/NniXXWL0OSdhBt3kQ3gHdi4mnYH7jb65i
  #       +va0xmgMwDdACzS9kQdMGLiXp3kLQ9QZrfjg3Ka45UC/ioDRcoQWOin6/GCkjkBk
  #       0petrU/JDBLpZNd+xb+oXu0CAwEAAQ==
  #       -----END PUBLIC KEY-----
  #     '';
  #   };
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
