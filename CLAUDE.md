# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Project Overview

**devshelves** is a Nix flake-parts module that provides composable,
module-based development shells. It allows shell configurations to be
split across multiple files and merged using standard NixOS module
semantics, with priority-ordered hooks and environment variables.

## Development Commands

```bash
# Enter development shell (via direnv or manually)
direnv allow
# or: nix develop

# Format all files (nixfmt + biome)
just fmt

# Run linting/validation
just check

# Interactive command menu
just --choose

# Prepare a release (uses conventional commits)
just release
```

## Architecture

### Core Module System (`src/`)

The library follows a pipeline pattern for building shells:

```text
module.nix (schema) -> build-shell.nix -> pkgs.mkShell
                            |
                mk-env-exports.nix (env vars)
                sort-hooks.nix (hook ordering)
```

- **`flake-module.nix`** - Flake-parts integration defining
  `perSystem.shells` option, maps configurations to `devShells` output
- **`module.nix`** - NixOS-style submodule defining shell configuration
  schema (packages, env, hooks with priorities)
- **`lib/build-shell.nix`** - Orchestrates shell derivation creation,
  converting config to `mkShell` arguments
- **`lib/mk-env-exports.nix`** - Generates shell export statements with
  support for quoted/evaluated values and unset operations
- **`lib/sort-hooks.nix`** - Priority-based hook sorting (ascending order)

### Configuration Partition (`.config/`)

Development tooling is isolated in a separate flake partition:

- **`devshells/default.nix`** - This project's own dev shell definitions
- **`git-hooks.nix`** - Pre-commit/pre-push hooks
  (biome, treefmt, markdownlint, reuse)
- **`treefmt.nix`** - Formatter configuration

### Key Design Patterns

1. **Priority System**: Both `env` and `hooks` use numeric priorities for
   deterministic ordering and conflict resolution (lower = earlier)
2. **Module Merging**: Multiple shell definitions merge via NixOS module
   semantics - lists concatenate, attrs merge with `mkMerge`/`mkOverride`
3. **Partitioned Inputs**: Dev-only dependencies live in `.config/flake.nix`
   to keep the main flake lean for consumers

## Consuming This Module

```nix
{
  inputs.devshelves.url = "git+https://codeberg.org/astratagem/devshelves.nix";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ inputs.devshelves.flakeModules.default ];

    perSystem = { pkgs, ... }: {
      shells.default = {
        packages = [ pkgs.hello ];
        hooks.greet = { priority = 100; text = "echo 'Hello'"; };
      };
    };
  };
}
```
