{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.alsa-lib
    pkgs.python312
    pkgs.python312Packages.python-rtmidi
    pkgs.pulseaudio
  ];
}
