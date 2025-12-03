{
  self,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;

  lib' = self.lib;

in
{
  options = {
    perSystem = mkPerSystemOption (
      {
        config,
        pkgs,
        system,
        ...
      }:
      {
        options.shells = mkOption {
          type = types.attrsOf (
            types.submoduleWith {
              modules = [ ./module.nix ];
              specialArgs = { inherit pkgs; };
            }
          );
          default = { };
          description = ''
            Attribute set of development shells to create.

            Each shell is defined as a module that can be composed across
            multiple files. Shell definitions with the same name are merged
            using the standard NixOS module merging semantics.
          '';
          example = lib.literalExpression ''
            {
              default = {
                packages = [ pkgs.hello ];
                env.GREETING = "Hello";
                shellHook = "echo $GREETING";
              };
            }
          '';
        };

        config.devShells = lib.mapAttrs (name: shellCfg: lib'.buildShell pkgs name shellCfg) config.shells;
      }
    );
  };
}
