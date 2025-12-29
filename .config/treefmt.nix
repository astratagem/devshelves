# SPDX-FileCopyrightText: (C) 2025 chris montgomery <chmont@protonmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

{
  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = ".git/config";
        programs.nixfmt.enable = true;
        # Use custom biome formatter to reference local biome.json
        settings.formatter.biome = {
          command = "${pkgs.biome}/bin/biome";
          options = [
            "check"
            "--write"
            "--no-errors-on-unmatched"
          ];
          includes = [
            "*.json"
            "*.js"
            "*.ts"
            "*.jsx"
            "*.tsx"
            "*.css"
          ];
        };
      };
    };
}
