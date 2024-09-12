{
  pkgs ? import <nixpkgs> {},
  system ? builtins.currentSystem,
}: let
  inherit (pkgs) lib;
  sources = builtins.fromJSON (builtins.readFile ./grlx.json);
  mkBinaryInstall = {
    url,
    version,
    hash,
  }:
    pkgs.stdenvNoCC.mkDerivation {
      name = "grlx-${version}";
      inherit version;
      src = pkgs.fetchurl {
        inherit url;
        sha256 = hash;
      };
      dontUnpack = true;
      installPhase = ''
        ls -la $src
        mkdir -p $out/bin/
        cp -v $src $out/bin/grlx
        chmod 755 $out/bin/grlx
      '';
    };
  tagged =
    lib.attrsets.mapAttrs
    (k: v: mkBinaryInstall {inherit (v.${system}) version url hash;})
    sources;
  latest = lib.lists.last (
    builtins.sort
    (x: y: (builtins.compareVersions x y) < 0)
    (builtins.attrNames tagged)
  );
in
  tagged // {"default" = tagged.${latest};}
