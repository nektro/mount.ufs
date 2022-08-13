with import <nixpkgs> {};

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    gcc
    pkgconfig
    fuse3
  ];

  hardeningDisable = [ "all" ];
}
