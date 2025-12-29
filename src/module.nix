{ config, lib, ... }:
let
  inherit (builtins) stringLength;
  inherit (lib)
    literalExpression
    mkDefault
    mkOption
    types
    ;

  priorities = {
    env = 100;
    hook = 500;
    late = 900;
  };

  # Accepts strings, paths, and derivations as raw values for env vars
  isRawEnvValue = x: builtins.isString x || builtins.isPath x || lib.isDerivation x;

  rawEnvValueType = types.mkOptionType {
    name = "rawEnvValue";
    description = "string, path, or derivation";
    check = isRawEnvValue;
  };

  envVarType = types.coercedTo rawEnvValueType (value: { value = toString value; }) (
    types.submodule envVarSubmodule
  );

  envVarSubmodule =
    { name, config, ... }:
    {
      options = {
        value = mkOption {
          type = types.str;
          default = "";
          description = ''
            The value of the environment variable.

            If `eval` is false (the default), this value is safely quoted
            before being exported, preventing shell expansion.

            If `eval` is true, this value is used as-is, allowing shell
            variable expansion (e.g., `$OTHER_VAR`) and command substitution
            (e.g., `$(command)`).
          '';
          example = "$XDG_CONFIG_HOME/path/to/something";
        };

        eval = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to evaluate this value at shell startup time.

            When true, the value is not quoted, allowing:
            - Variable expansion: `$OTHER_VAR` or `''${OTHER_VAR}`
            - Command substitution: `$(some-command)`
            - Arithmetic expansion: `$((1 + 2))`

            When false (the default), the value is safely quoted and
            exported literally.
          '';
          example = true;
        };

        priority = mkOption {
          type = types.int;
          default = priorities.env;
          description = ''
            Priority for this environment variable export.

            Lower numbers are exported earlier in the shellHook.
            This is important when `eval` is true and the value
            references other environment variables.

            Default priorities:
            - 100: Standard environment variables
            - 500: User shell hooks
            - 900: Late-stage hooks
          '';
          example = 50;
        };

        unset = mkOption {
          type = types.bool;
          default = false;
          description = ''
            If true, unset this environment variable instead of setting it.
            Takes precedence over `value`.
          '';
        };
      };
    };

  hookSubmodule =
    { ... }:
    {
      options = {
        text = mkOption {
          type = types.lines;
          description = ''
            The shell script text to run.
          '';
          example = ''
            echo "Welcome to the development shell"
          '';
        };

        priority = mkOption {
          type = types.int;
          default = priorities.hook;
          description = ''
            Priority for this hook. Lower numbers run first.

            Default priorities:
            - 100: Environment variables
            - 500: Standard shell hooks (default)
            - 900: Late-stage hooks
          '';
          example = 200;
        };
      };
    };

in
{
  options = {
    name = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Name of the shell. If null, uses the attribute name from the
        shells attrset (e.g., "default" for shells.default).

        This becomes the derivation name and is shown in the shell prompt
        by some shell integrations.
      '';
      example = "my-project-dev";
    };

    motd = mkOption {
      type = types.nullOr types.lines;
      default = null;
      description = ''
        Message of the day to display when entering the shell.

        If set, this is printed at priority 1000 (after all other hooks).
        Set to null to disable.
      '';
      example = ''
        Welcome to the project development environment.
        Run 'make help' for available commands.
      '';
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        Packages to include in the development shell.
        These are added to the shell's PATH.
      '';
      example = literalExpression "[ pkgs.hello pkgs.jq ]";
    };

    packagesFrom = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        Packages whose build inputs should be included in the shell.
        This is passed to mkShell's `inputsFrom` argument.

        Useful for pulling in dependencies from a package you're developing.
      '';
      example = literalExpression "[ self.packages.myapp ]";
    };

    env = mkOption {
      type = types.attrsOf envVarType;
      default = { };
      description = ''
        Environment variables to set in the shell.

        Supports shorthand syntax:
        ```nix
        env.EDITOR = "vim";  # Equivalent to env.EDITOR.value = "vim";
        ```

        Or full form with options:
        ```nix
        env.DATA_DIR = {
          value = "$PROJECT_ROOT/data";
          eval = true;
          priority = 150;
        };
        ```

        Options:
        - `value`: The value to set
        - `eval`: Whether to allow shell expansion (default: false)
        - `priority`: Export order (lower = earlier, default: 100)
        - `unset`: Whether to unset instead of set
      '';
      example = literalExpression ''
        {
          EDITOR = "vim";
          PROJECT_ROOT = {
            value = "$(git rev-parse --show-toplevel)";
            eval = true;
          };
        }
      '';
    };

    shellHook = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Shell script to run when entering the development shell.

        This is a convenience option that creates a hook entry with
        the default priority (500). For more control over ordering,
        use the `hooks` option directly.

        Supports `lib.mkOrder` for priority control:
        ```nix
        shellHook = lib.mkOrder 200 "echo 'Early hook'";
        ```
      '';
      example = ''
        echo "Welcome to the dev shell"
        source .env 2>/dev/null || true
      '';
    };

    hooks = mkOption {
      type = types.listOf (types.submodule hookSubmodule);
      default = [ ];
      description = ''
        List of shell hooks with explicit priorities.

        Use this when you need fine-grained control over hook ordering.
        For simple cases, `shellHook` is more convenient.
      '';
      example = literalExpression ''
        [
          { priority = 200; text = "echo 'Early hook'"; }
          { priority = 800; text = "echo 'Late hook'"; }
        ]
      '';
    };
  };

  config = {
    hooks = lib.mkMerge [
      (lib.mkIf (stringLength (lib.removeSuffix "\n" config.shellHook) > 0) [
        {
          priority = mkDefault priorities.hook;
          text = config.shellHook;
        }
      ])
      (lib.mkIf (config.motd != null) [
        {
          priority = 1000;
          text = ''
            cat <<'DEVSHELVES_MOTD'
            ${config.motd}
            DEVSHELVES_MOTD
          '';
        }
      ])
    ];
  };
}
