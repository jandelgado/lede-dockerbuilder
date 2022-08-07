with (import <nixpkgs> {});
mkShell {
  name = "OpenWRT builder";
  buildInputs = [
      git
      perl
      gnumake
      gcc
      unzip
      utillinux
      python2
      python3
      rsync
      patch
      wget
      file
      subversion
      which
      pkgconfig
      openssl
      systemd
      binutils

      ncurses
      zlib
      zlib.static
      glibc.static
  ];
}
