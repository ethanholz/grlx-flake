{
  description = "A simple repackaging of grlx with Nix";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
      ];
      systems =
        [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          version = "1.0.0";
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
            name = "grlx-cli";
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
            default = grlx-cli;
            all = grlx;
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
