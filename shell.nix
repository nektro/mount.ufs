with import <nixpkgs> {};

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    gcc
    fuse3
  ];

  hardeningDisable = [ "all" ];
}
