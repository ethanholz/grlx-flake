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
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        version = "1.0.3";
        binaryVersion = "1.0.3";
        shortCommit = "b08e2e8";
        # TODO: Add filterSource to pkgs to ignore testing directories
        grlx-src = pkgs.fetchFromGitHub {
          owner = "gogrlx";
          repo = "grlx";
          rev = "v${version}";
          hash = "sha256-bfECj03gTC9gM9ei9Ewa3+c+XUrfahYW7OGnxzQ2QWg=";
        };
        vendorHash = "";
        ldflags = [
          "-X main.Tag=${grlx-src.rev}"
          "-X main.GitCommit=${shortCommit}"
        ];

        convertSystem = system:
          if system == "x86_64-linux"
          then {
            system = "linux-amd64";
            hash = "sha256-rJUTp0bZmCS1W8s3ajkvPZ5pZ5DNuD+CJ9tcp/Jg3sk=";
          }
          else if system == "x86_64-darwin"
          then {
            system = "darwin-amd64";
            hash = "sha256-yrpWtt3tZqCxaRmJzEfknCYw4G8nIIQio5IXT0kSg4A=";
          }
          else if system == "aarch64-linux"
          then {
            system = "linux-arm64";
            hash = "sha256-PaQ74f6qERxCIwBW4LAAEUZktaiWhzw/lqNunOt3ab8=";
          }
          else if system == "aarch64-darwin"
          then {
            system = "darwin-arm64";
            hash = "sha256-yMMxtrNXeENXMuYs96peod6ARZLH0C/8M5qK2Yl7BUo=";
          }
          else if system == "i686-linux"
          then {
            system = "linux-386";
            hash = "sha256-I4qSC/zuDXt6p0KTusHml2agJ7izMG2Y4IZ9E7BzdrE=";
          }
          else abort "Unsupported system ${system}";
        converted = convertSystem system;

        buildGrlxPackage = {
          name,
          subPackages,
          converted,
        }:
          pkgs.buildGoModule {
            inherit name version vendorHash subPackages ldflags;
            src = grlx-src;
            meta = with pkgs.lib; {
              description = "Effective Fleet Configuration Management";
              homepage = "https://grlx.dev";
              license = licenses.bsd0;
              maintainer = with maintainers; [ethanholz];
            };
          };
        # TODO: we need to fix this to handle all binary versions as this looks to only be on binary version.
        grlxBinary = pkgs.stdenv.mkDerivation {
          name = "grlx";
          inherit version;
          src = pkgs.fetchurl {
            url = "https://github.com/gogrlx/grlx/releases/download/v${binaryVersion}/grlx-v${binaryVersion}-${converted.system}";
            sha256 = converted.hash;
          };
          dontUnpack = true;
          installPhase = ''
            ls -la $src
            mkdir -p $out/bin/
              cp -v $src $out/bin/grlx
            chmod 755 $out/bin/grlx
          '';
        };

        buildGrlxContainer = {
          name,
          package,
          tag,
        }:
          pkgs.dockerTools.buildImage {
            inherit name tag;
            created = "now";
            copyToRoot = [
              pkgs.dockerTools.caCertificates
              pkgs.curl
              pkgs.dockerTools.binSh
            ];
            config = {Cmd = ["${package}/bin/${name}"];};
          };

        grlx = buildGrlxPackage {
          name = "grlx";
          subPackages = ["cmd/grlx" "cmd/farmer" "cmd/sprout"];
        };
        grlx-cli = buildGrlxPackage {
          name = "grlx";
          subPackages = ["cmd/grlx"];
        };
        grlx-farmer = buildGrlxPackage {
          name = "grlx-farmer";
          subPackages = ["cmd/farmer"];
        };
        grlx-sprout = buildGrlxPackage {
          name = "grlx-sprout";
          subPackages = ["cmd/sprout"];
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
          inherit
            grlx-farmer
            grlx-sprout
            grlx-cli
            grlx-farmer-docker
            grlx-sprout-docker
            ;
          default = grlxBinary;
          all = grlx;
          grlx-binary = grlxBinary;
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
