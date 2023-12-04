{
  description = "A simple repackaging of grlx with Nix";

  inputs = { 
     nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
      ];
      systems = [
        "i686-linux"
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          version = "1.0.0";
          binaryVersion = "1.0.0";
          shortCommit = "c8745ea";
          # TODO: Add filterSource to pkgs to ignore testing directories
          grlx-src = pkgs.fetchFromGitHub {
            owner = "gogrlx";
            repo = "grlx";
            rev = "v${version}";
            hash = "sha256-Z+IaeJ1BK2WzfUNLyUc68Gmin9olgZem6Epo4kK8Dp8=";
          };
          vendorHash = "sha256-1Ts/2sgYIreUh0n2WnX4ARYFEPGc8ZKmTZsMJvduqpY=";
          ldflags = [
            "-X main.Tag=${grlx-src.rev}"
            "-X main.GitCommit=${shortCommit}"
          ];

          convertSystem = system:
            if system == "x86_64-linux" then
              "linux-amd64"
            else if system == "x86_64-darwin" then
              "darwin-amd64"
            else if system == "aarch64-linux" then
              "linux-arm64"
            else if system == "aarch64-darwin" then
              "darwin-arm64"
            else if system == "i686-linux" then
              "linux-386"
            else
              abort "Unsupported system ${system}";
          converted = convertSystem system;

          buildGrlxPackage = { name, subPackages, }:
            pkgs.buildGoModule {
              inherit name version vendorHash subPackages ldflags;
              src = grlx-src;
              meta = with pkgs.lib; {
                description = "Effective Fleet Configuration Management";
                homepage = "https://grlx.dev";
                license = licenses.bsd0;
                maintainer = with maintainers; [ ethanholz ];
              };
            };
          grlxBinary = pkgs.stdenv.mkDerivation {
            name = "grlx";
            inherit version;
            src = pkgs.fetchurl {
              url =
                "https://github.com/gogrlx/grlx/releases/download/v${binaryVersion}/grlx-v${binaryVersion}-${converted}";
              hash = "sha256-z3JeIWyhIybCE4JA7ugqX9InCZ8eGeTJ8oArecaJToo=";
            };
            dontUnpack = true;
            installPhase = ''
              ls -la $src
              mkdir -p $out/bin/
                cp -v $src $out/bin/grlx 
              chmod 755 $out/bin/grlx
            '';
          };

          buildGrlxContainer = { name, package, tag, }:
            pkgs.dockerTools.buildImage {
              inherit name tag;
              created = "now";
              copyToRoot = [
                pkgs.dockerTools.caCertificates
                pkgs.curl
                pkgs.dockerTools.binSh
              ];
              config = { Cmd = [ "${package}/bin/${name}" ]; };
            };

          grlx = buildGrlxPackage {
            name = "grlx";
            subPackages = [ "cmd/grlx" "cmd/farmer" "cmd/sprout" ];
          };
          grlx-cli = buildGrlxPackage {
            name = "grlx";
            subPackages = [ "cmd/grlx" ];
          };
          grlx-farmer = buildGrlxPackage {
            name = "grlx-farmer";
            subPackages = [ "cmd/farmer" ];
          };
          grlx-sprout = buildGrlxPackage {
            name = "grlx-sprout";
            subPackages = [ "cmd/sprout" ];
          };
          grlx-farmer-docker = buildGrlxContainer {
            name = "grlx-farmer";
            package = grlx-farmer;
            tag = "latest";
          };
          grlx-sprout-docker = buildGrlxContainer {
            name = "grlx-sprout";
            package = grlx-sprout;
            tag = "latest";
          };
        in {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
          packages = {
            inherit grlx-farmer grlx-sprout grlx-cli grlx-farmer-docker
              grlx-sprout-docker;
            default = grlxBinary;
            all = grlx;
            grlx-binary = grlxBinary;
          };

          formatter = pkgs.nixfmt;
        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}
