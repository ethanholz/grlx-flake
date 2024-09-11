{
  description = "A simple repackaging of grlx with Nix";

  inputs = {nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";};

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [];
      systems = [
        "i686-linux"
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem = {
        pkgs,
        system,
        ...
      }: let
        getGrlxPackage = {
          version,
        }: let
          jsonString = builtins.readFile ./grlx.json;
          jsonData = builtins.fromJSON jsonString;
          matched = jsonData.${version};
          result = {
              url = matched.${system}.url;
              hash = matched.${system}.hash;
            };
        in
          pkgs.stdenvNoCC.mkDerivation {
            name = "grlx-${version}";
            inherit version;
            src = pkgs.fetchurl {
              url = result.url;
              sha256 = result.hash;
            };
            dontUnpack = true;
            installPhase = ''
              ls -la $src
              mkdir -p $out/bin/
              cp -v $src $out/bin/grlx
              chmod 755 $out/bin/grlx
            '';
          };
      in {
        packages = {
            default = getGrlxPackage{version = "v1.0.5";};
            "v1.0.5" = getGrlxPackage{version = "v1.0.5";};
            "v1.0.4" = getGrlxPackage{version = "v1.0.4";};
            "v1.0.3" = getGrlxPackage{version = "v1.0.3";};
            "v1.0.0" = getGrlxPackage{version = "v1.0.0";};
        };

        devShells = {
          default = pkgs.mkShell {
            buildInputs = [pkgs.python3];
          };
        };

        formatter = pkgs.alejandra;
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}
