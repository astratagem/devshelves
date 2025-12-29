# SPDX-FileCopyrightText: (C) 2025 chris montgomery <chmont@protonmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

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
