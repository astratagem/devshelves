# SPDX-FileCopyrightText: (C) 2025 chris montgomery <chmont@protonmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

{
  perSystem =
    { ... }:
    {
      treefmt = {
        projectRootFile = ".git/config";
        programs = {
          biome.enable = true;
          nixfmt.enable = true;
        };
      };
    };
}
