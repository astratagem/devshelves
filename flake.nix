# SPDX-FileCopyrightText: (C) 2025 chris montgomery <chmont@protonmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

{
  description = "devshelves.nix -- composable Nix development shells via flake-parts";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Dev inputs
    git-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-unit.url = "github:nix-community/nix-unit";

    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-unit.inputs.nixpkgs.follows = "nixpkgs";
    nix-unit.inputs.flake-parts.follows = "flake-parts";
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
          inputs.git-hooks.flakeModule
          inputs.treefmt-nix.flakeModule
          inputs.nix-unit.modules.flake.default

          ./src/lib
          ./.config/devshells
          ./.config/git-hooks.nix
          ./.config/treefmt.nix
          ./tests

          flakeModules.default
        ];

        flake = {
          inherit flakeModules;
          modules.shell = ./src/module.nix;
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

            # Pass all flake inputs to nix-unit for sandbox evaluation
            nix-unit.inputs = {
              inherit (inputs)
                nixpkgs
                flake-parts
                systems
                git-hooks
                treefmt-nix
                nix-unit
                ;
              "flake-parts/nixpkgs-lib" = inputs.flake-parts.inputs.nixpkgs-lib;
            };
          };
      }
    );
}
