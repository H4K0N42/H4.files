{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "hyprcursor-to-xcursor-env";

  buildInputs = with pkgs; [
    python3
  ];
}
