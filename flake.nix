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
      self,
      ...
    }:
    let
      systems = import inputs.systems;
      lib' = self.lib;
    in
    flake-parts.lib.mkFlake { inherit inputs; } (
      { flake-parts-lib, ... }:
      let
        inherit (flake-parts-lib) importApply;
        flakeModules.default = (importApply ./src/flake-module.nix { inherit lib'; });
      in
      {
        inherit systems;

        imports = [
          inputs.flake-parts.flakeModules.modules
          inputs.flake-parts.flakeModules.partitions

          ./src/lib

          flakeModules.default
        ];

        flake = { inherit flakeModules; };

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
      }
    );
}
