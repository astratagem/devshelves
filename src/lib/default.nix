{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ./build-shell.nix
    ./mk-env-exports.nix
    ./sort-hooks.nix
  ];

  options.flake.lib = mkOption {
    description = "Internal helpers library";
    type = with types; lazyAttrsOf raw;
    default = { };
  };
}
