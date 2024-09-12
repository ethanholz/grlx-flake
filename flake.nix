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
      }: {
        packages = import ./default.nix {inherit system pkgs;};

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
