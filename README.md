<!--
SPDX-FileCopyrightText: (C) 2025 chris montgomery <chmont@protonmail.com>

SPDX-License-Identifier: GPL-3.0-or-later
-->

# devshelves

Composable Nix development shells via flake-parts.

`devshelves` provides a module-based approach to defining development shells,
allowing you to compose shell configurations across multiple files and merge
them using standard NixOS module semantics.

## Features

- **Composable**: Define shells across multiple modules/files and merge them
- **Priority-ordered hooks**: Control the order of shell hooks and environment variables
- **Evaluated environment variables**: Reference other env vars with shell expansion
- **Standard module merging**: Use `mkDefault`, `mkForce`, etc. for conflict resolution
- **flake-parts integration**: Works seamlessly with flake-parts

## Quick Start

Add to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshelves.url = "github:your-username/devshelves";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devshelves.flakeModule ];

      perSystem = { pkgs, ... }: {
        shells.default = {
          packages = [ pkgs.hello ];
          env.GREETING.value = "Hello, World!";
          shellHook = ''
            echo $GREETING
          '';
        };
      };
    };
}
```


## Options

### `perSystem.shells.<name>`

Each shell is a submodule with the following options:

#### `name`

Optional name override for the shell derivation. Defaults to the attribute name.

```nix
shells.myshell = {
  name = "my-project-dev";  # Override derivation name
};
```

#### `motd`

Optional message displayed when entering the shell. Runs after all hooks.

```nix
shells.default.motd = ''
  Welcome to the project development environment.
  Run 'make help' for available commands.
'';
```

#### `packages`

List of packages to add to the shell's PATH.

```nix
shells.default.packages = [ pkgs.nodejs pkgs.yarn ];
```

#### `packagesFrom`

List of packages whose build inputs should be included (passed to `inputsFrom`).

```nix
shells.default.packagesFrom = [ self.packages.myapp ];
```

#### `env`

Attribute set of environment variables. Supports shorthand and full syntax:

```nix
shells.default.env = {
  # Shorthand: just a string
  EDITOR = "vim";

  # Equivalent full form
  PAGER = { value = "less"; };

  # With shell expansion
  PROJECT_ROOT = {
    value = "$(git rev-parse --show-toplevel)";
    eval = true;
  };

  # Reference another env var (must set priority higher)
  PRJ_BIN_HOME = {
    value = "$PRJ_ROOT/.bin";
    eval = true;
    priority = 150;
  };
};
```

Each variable supports:

- `value` (string): The value to set
- `eval` (bool, default: false): Allow shell expansion
- `priority` (int, default: 100): Export order (lower = earlier)
- `unset` (bool, default: false): Unset instead of set

#### `shellHook`

Convenience option for adding shell hooks with default priority (500).

```nix
shells.default.shellHook = ''
  echo "Welcome to the dev shell"
'';
```

Supports `lib.mkOrder` for priority control:

```nix
shells.default.shellHook = lib.mkOrder 200 ''
  echo "Early hook"
'';
```

#### `hooks`

List of hooks with explicit priorities for fine-grained control.

```nix
shells.default.hooks = [
  { priority = 100; text = "echo 'First'"; }
  { priority = 900; text = "echo 'Last'"; }
];
```

## Composition Example

Define a base shell in one file:

```nix
# shells/base.nix
{ pkgs, ... }: {
  perSystem = { ... }: {
    shells.default = {
      packages = [ pkgs.git pkgs.curl ];
      env.EDITOR.value = "vim";
      shellHook = ''
        echo "Base shell loaded"
      '';
    };
  };
}
```

Extend it in another:

```nix
# shells/nodejs.nix
{ pkgs, ... }: {
  perSystem = { ... }: {
    shells.default = {
      packages = [ pkgs.nodejs pkgs.yarn ];
      env.NODE_ENV.value = "development";
      shellHook = lib.mkOrder 600 ''
        echo "Node.js environment ready"
      '';
    };
  };
}
```

Import both in your flake:

```nix
{
  imports = [
    inputs.devshelves.flakeModule
    ./shells/base.nix
    ./shells/nodejs.nix
  ];
}
```

The result merges packages, env vars, and hooks according to module semantics
and priority ordering.

## Priority System

Default priorities:

| Type | Default Priority |
|------|-----------------|
| Environment variables | 100 |
| Shell hooks | 500 |
| Late hooks | 900 |

Lower numbers execute first. Use priorities to ensure:

1. Env vars are exported before hooks that use them
2. Dependent env vars are exported after their dependencies
3. Cleanup hooks run after setup hooks

## Conflict Resolution

Environment variables use standard NixOS module conflict handling:

```nix
# In module A
env.FOO.value = "a";

# In module B - this would error without priority
env.FOO.value = lib.mkDefault "b";  # A wins (has higher priority)
# or
env.FOO.value = lib.mkForce "b";    # B wins (forced)
```

## License

MIT
