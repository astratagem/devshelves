{
  self,
  lib,
  ...
}:
let
  lib' = self.lib;
in
{
  /**
    Build a shell derivation from a shell module configuration.
  */
  flake.lib.buildShell =
    pkgs: attrName: cfg:
    let
      name = if cfg.name != null then cfg.name else attrName;
      envExports = lib'.mkEnvExports cfg.env;
      allHooks = envExports ++ cfg.hooks;
      sortedHooks = lib'.sortHooks allHooks;
      shellHook = lib.concatStringsSep "\n" sortedHooks;
      inputsFrom = map (
        drv: if lib.isDerivation drv then drv else throw "`packagesFrom` entries must be derivations"
      ) cfg.packagesFrom;
    in
    pkgs.mkShell {
      inherit name inputsFrom shellHook;
      packages = cfg.packages;
    };
}
