{ pkgs ? import <nixpkgs> { } }:

with pkgs;

mkShellNoCC {
  buildInputs = [
    autoconf
    automake
    gnumake
  ];
}
