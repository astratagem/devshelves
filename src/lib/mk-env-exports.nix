{ lib, self, ... }:
{
  /**
    Generate shell export statements for environment variables.

    Takes an attrset of environment variable definitions where each value
    is either:

    - A submodule with `{ value, eval, priority, unset }` attributes

    Returns a list of `{ priority, text }` entries suitable for sortHooks.

    Variables with `eval = true` are exported without quoting, allowing
    shell expansion.  Variables with `eval = false` (the default) are
    safely quoted.
  */
  flake.lib.mkEnvExports =
    envAttrs:
    let
      mkExport =
        name: cfg:
        if cfg.unset then
          {
            inherit (cfg) priority;
            text = "unset ${name}";
          }
        else if cfg.eval then
          {
            inherit (cfg) priority;
            text = "export ${name}=\"${cfg.value}\"";
          }
        else
          {
            inherit (cfg) priority;
            text = "export ${name}=\"${lib.escapeShellArg cfg.value}\"";
          };
    in
    lib.mapAttrsToList mkExport envAttrs;
}
