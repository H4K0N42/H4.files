{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "hyprcursor-to-xcursor-env";

  buildInputs = with pkgs; [
    python3
    python3Packages.pillow # for image processing
    python3Packages.toml # for reading manifest.toml
    xorg.xcursorgen # to generate xcursor files
    imagemagick # optional: for inspecting images, debugging
  ];

  shellHook = ''
    echo "Environment ready for Hyprcursor → XCursor conversion."
    echo "Python version: $(python3 --version)"
    echo "Use 'python script.py' to run your converter."
  '';
}
