{ inputs, lib, ... }:
{
  perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    let
      nativeBuildInputs = [
      ];

      buildInputs = [
      ];

      commonPkgs =
        buildInputs
        ++ nativeBuildInputs
        ++ [
          inputs'.nixpkgs-trunk.legacyPackages.just
          pkgs.reuse
        ];

      checksPkgs = config.pre-commit.settings.enabledPackages ++ [
        pkgs.biome
      ];

      formatterPkgs = (lib.attrValues config.treefmt.build.programs) ++ [
        config.formatter
        config.treefmt.build.wrapper
      ];

      ciPkgs = commonPkgs ++ checksPkgs;
      devPkgs =
        commonPkgs
        ++ checksPkgs
        ++ formatterPkgs
        ++ [
        ];

      shellHook = ''
        ${config.pre-commit.installationScript}
      '';
    in
    {
      shells.default = {
        inherit shellHook;
        packages = devPkgs;
        env = {
          DEVSHELVES_DEV = "1";
          PRJ_BIN_HOME = "\${PRJ_BIN_HOME:=\${PRJ_PATH:-\${PRJ_ROOT}/.bin}}";
        };
      };

      shells.ci.packages = ciPkgs;
    };
}
