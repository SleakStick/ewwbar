{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = [
    (pkgs.python3.withPackages (ps: with ps; [
      dbus-python
      jq
      pygobject3
    ]))
  ];
}
