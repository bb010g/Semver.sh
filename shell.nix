{ nixpkgs ? import <nixpkgs> {} }:
let
  inherit (nixpkgs) pkgs;
  inherit (pkgs.perlPackages) HTMLTree;
  utf8all = pkgs.buildPerlPackage rec {
    name = "utf8-all-0.024";
    src = pkgs.fetchurl {
      url = "mirror://cpan/authors/id/H/HA/HAYOBAAN/${name}.tar.gz";
      sha256 = "9233465d41174077ccdbc04f751ab7d68c8d19114e36cd02f2c5fdc2bc3937b7";
    };
    meta = {
      description = "turn on Unicode - all of it";
      license = with pkgs.stdenv.lib.licenses; [ artistic1 gpl1Plus ];
    };
    propagatedBuildInputs = with pkgs.perlPackages; [ Carp Encode ImportInto PerlIOutf8_strict Parent ];
    buildInputs = with pkgs.perlPackages; [ perl PathTools IO TestException TestFatal TestMore TestWarn autodie constant threads threadsshared version ];
  };
in
pkgs.stdenv.mkDerivation {
  name = "semver-env";
  buildInputs = [pkgs.bash pkgs.perl HTMLTree utf8all];
}
