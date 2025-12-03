{
  description = "devshelves.nix -- composable Nix development shells via flake-parts";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      ...
    }:
    let
      systems = import inputs.systems;

    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      inherit systems;

      imports = [
        inputs.flake-parts.flakeModules.modules
        inputs.flake-parts.flakeModules.partitions

        ./src/flake-module.nix
        ./src/lib
      ];

      flake.flakeModules = {
        default = ./flake-module.nix;
      };

      perSystem =
        { system, pkgs, ... }:
        {
          _module.args = {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ ];
            };
          };
          formatter = pkgs.nixfmt-rfc-style;
        };

      partitions.dev = {
        extraInputsFlake = ./.config;
        module =
          { inputs, ... }:
          {
            imports = [
              inputs.git-hooks.flakeModule
              inputs.treefmt-nix.flakeModule
              ./.config/devshells
              ./.config/git-hooks.nix
              ./.config/treefmt.nix
            ];
          };
      };

      partitionedAttrs = {
        checks = "dev";
        devShells = "dev";
      };
    };
}
