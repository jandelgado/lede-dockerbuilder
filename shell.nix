with (import <nixpkgs> {});
mkShell {
  name = "OpenWRT builder";
  buildInputs = [
      pkgs.cacert
      git
      perl
      gnumake
      gcc
      unzip
      utillinux
      python3
      rsync
      patch
      wget
      file
      subversion
      which
      pkg-config
      openssl
      systemd
      binutils

      ncurses
      zlib
      zlib.static
      glibc.static
  ];
}
