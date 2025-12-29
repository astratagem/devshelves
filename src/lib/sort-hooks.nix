# SPDX-FileCopyrightText: (C) 2025 chris montgomery <chmont@protonmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

{ lib, ... }:
{
  /**
    Sort a list of hook entries by ascending priority.

    Each entry should have `{ priority, text }` attributes.
  */
  flake.lib.sortHooks =
    hooks:
    let
      sorted = lib.sort (a: b: a.priority < b.priority) hooks;
    in
    map (h: h.text) sorted;
}
