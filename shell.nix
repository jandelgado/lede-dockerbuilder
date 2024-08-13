let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/42c5e250a8a9162c3e962c78a4c393c5ac369093.tar.gz";
  }) {};

in pkgs.mkShell {

  name = "OpenWRT builder";
  buildInputs = [
      pkgs.cacert
      pkgs.git
      pkgs.perl
      pkgs.gnumake
      pkgs.gcc
      pkgs.unzip
      pkgs.utillinux
      pkgs.python3
      pkgs.rsync
      pkgs.patch
      pkgs.wget
      pkgs.file
      pkgs.subversion
      pkgs.which
      pkgs.pkg-config
      pkgs.openssl
      pkgs.systemd
      pkgs.binutils

      pkgs.ncurses
      pkgs.zlib
      pkgs.zlib.static
      pkgs.glibc.static
  ];
}
