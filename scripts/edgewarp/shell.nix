{
  pkgs ? import <nixpkgs> { },
}:

let
  python = pkgs.python3.withPackages (ps: [ ps.pywayland ]);
  wp = "${pkgs.wayland-protocols}/share/wayland-protocols";
  wlr = "${pkgs.wlr-protocols}/share/wlr-protocols/unstable";

  # pywayland ships no wlr protocols; generate one self-contained package
  # (core + deps) so the relative imports between the modules resolve.
  wlproto = pkgs.runCommand "edgewarp-wlproto" { nativeBuildInputs = [ python ]; } ''
    mkdir -p $out/wlproto
    touch $out/wlproto/__init__.py
    python3 - <<'PY'
    from pywayland.scanner import Protocol
    files = [
        "${pkgs.wayland-scanner}/share/wayland/wayland.xml",
        "${wp}/stable/xdg-shell/xdg-shell.xml",
        "${wp}/stable/tablet/tablet-v2.xml",
        "${wp}/staging/cursor-shape/cursor-shape-v1.xml",
        "${wp}/unstable/relative-pointer/relative-pointer-unstable-v1.xml",
        "${wlr}/wlr-layer-shell-unstable-v1.xml",
        "${wlr}/wlr-virtual-pointer-unstable-v1.xml",
    ]
    protocols = [Protocol.parse_file(f) for f in files]
    imports = {i.name: p.name for p in protocols for i in p.interface}
    for p in protocols:
        p.output("${placeholder "out"}/wlproto", imports)
    PY
  '';
in
pkgs.mkShell {
  name = "edgewarp-env";

  buildInputs = [ python ];

  shellHook = ''
    export PYTHONPATH=${wlproto}''${PYTHONPATH:+:$PYTHONPATH}
  '';
}
