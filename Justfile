# SPDX-FileCopyrightText: (C) 2025 chris montgomery <chmont@protonmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

###: <https://just.systems/man/en/>

mod reuse '.config/reuse.just'
mod release '.config/release.just'

prj-root := env("PRJ_ROOT")

default:
  @just --choose

[doc: "Check the project for issues"]
check:
    biome check {{prj-root}}

[doc: "Format the project files"]
fmt:
    treefmt
