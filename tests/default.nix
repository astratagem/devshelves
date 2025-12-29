{
  lib,
  ...
}:
let
  # Import lib functions directly to avoid flake re-evaluation in sandbox
  sortHooks =
    hooks:
    let
      sorted = lib.sort (a: b: a.priority < b.priority) hooks;
    in
    map (h: h.text) sorted;

  mkEnvExports =
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

  # Helper to evaluate a shell module config
  evalShellModule =
    config:
    (lib.evalModules {
      modules = [
        ../src/module.nix
        config
      ];
    }).config;
in
{
  flake.tests = {
    # ─────────────────────────────────────────────────────────────────────────
    # sortHooks tests
    # ─────────────────────────────────────────────────────────────────────────

    testSortHooksEmpty = {
      expr = sortHooks [ ];
      expected = [ ];
    };

    testSortHooksSingleItem = {
      expr = sortHooks [
        {
          priority = 100;
          text = "echo hello";
        }
      ];
      expected = [ "echo hello" ];
    };

    testSortHooksOrdering = {
      expr = sortHooks [
        {
          priority = 300;
          text = "third";
        }
        {
          priority = 100;
          text = "first";
        }
        {
          priority = 200;
          text = "second";
        }
      ];
      expected = [
        "first"
        "second"
        "third"
      ];
    };

    testSortHooksStability = {
      expr = sortHooks [
        {
          priority = 100;
          text = "a";
        }
        {
          priority = 100;
          text = "b";
        }
      ];
      # Same priority items maintain relative order
      expected = [
        "a"
        "b"
      ];
    };

    # ─────────────────────────────────────────────────────────────────────────
    # mkEnvExports tests
    # ─────────────────────────────────────────────────────────────────────────

    testMkEnvExportsSimple = {
      expr = mkEnvExports {
        FOO = {
          value = "bar";
          eval = false;
          priority = 100;
          unset = false;
        };
      };
      # escapeShellArg only adds quotes when needed (for special chars)
      expected = [
        {
          priority = 100;
          text = "export FOO=\"bar\"";
        }
      ];
    };

    testMkEnvExportsEval = {
      expr = mkEnvExports {
        PATH_VAR = {
          value = "$HOME/bin";
          eval = true;
          priority = 100;
          unset = false;
        };
      };
      expected = [
        {
          priority = 100;
          text = "export PATH_VAR=\"$HOME/bin\"";
        }
      ];
    };

    testMkEnvExportsUnset = {
      expr = mkEnvExports {
        UNWANTED = {
          value = "";
          eval = false;
          priority = 100;
          unset = true;
        };
      };
      expected = [
        {
          priority = 100;
          text = "unset UNWANTED";
        }
      ];
    };

    testMkEnvExportsPriorities = {
      expr =
        let
          exports = mkEnvExports {
            EARLY = {
              value = "first";
              eval = false;
              priority = 50;
              unset = false;
            };
            LATE = {
              value = "second";
              eval = false;
              priority = 200;
              unset = false;
            };
          };
        in
        map (e: e.priority) (lib.sort (a: b: a.priority < b.priority) exports);
      expected = [
        50
        200
      ];
    };

    # ─────────────────────────────────────────────────────────────────────────
    # Module env type coercion tests
    # ─────────────────────────────────────────────────────────────────────────

    testEnvStringCoercion = {
      expr = (evalShellModule { env.EDITOR = "vim"; }).env.EDITOR.value;
      expected = "vim";
    };

    testEnvStringCoercionDefaults = {
      expr =
        let
          cfg = (evalShellModule { env.EDITOR = "vim"; }).env.EDITOR;
        in
        {
          inherit (cfg) eval priority unset;
        };
      expected = {
        eval = false;
        priority = 100;
        unset = false;
      };
    };

    testEnvPathCoercion = {
      expr =
        let
          cfg = (evalShellModule { env.CONFIG_PATH = ./.; }).env.CONFIG_PATH;
        in
        builtins.substring 0 11 cfg.value;
      expected = "/nix/store/";
    };

    # Note: Derivation coercion is tested via testEnvPathCoercion since both
    # use toString. A direct derivation test would require builtins.currentSystem
    # which isn't available in pure evaluation mode.

    testEnvFullForm = {
      expr =
        let
          cfg =
            (evalShellModule {
              env.DATA_DIR = {
                value = "$PROJECT_ROOT/data";
                eval = true;
                priority = 150;
              };
            }).env.DATA_DIR;
        in
        {
          inherit (cfg) value eval priority;
        };
      expected = {
        value = "$PROJECT_ROOT/data";
        eval = true;
        priority = 150;
      };
    };

    # ─────────────────────────────────────────────────────────────────────────
    # Module hooks tests
    # ─────────────────────────────────────────────────────────────────────────

    testShellHookCreatesHook = {
      expr =
        let
          cfg = evalShellModule { shellHook = "echo hello"; };
        in
        builtins.length cfg.hooks > 0;
      expected = true;
    };

    testShellHookDefaultPriority = {
      expr =
        let
          cfg = evalShellModule { shellHook = "echo hello"; };
          hook = builtins.head cfg.hooks;
        in
        hook.priority;
      expected = 500;
    };

    testMotdCreatesLateHook = {
      expr =
        let
          cfg = evalShellModule { motd = "Welcome"; };
          hook = builtins.head cfg.hooks;
        in
        hook.priority;
      expected = 1000;
    };

    testExplicitHooks = {
      expr =
        let
          cfg = evalShellModule {
            hooks = [
              {
                priority = 200;
                text = "early";
              }
              {
                priority = 800;
                text = "late";
              }
            ];
          };
        in
        map (h: h.priority) cfg.hooks;
      expected = [
        200
        800
      ];
    };
  };
}
