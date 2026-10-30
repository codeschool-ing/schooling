#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
# Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l09
MD=$HERE/generic-functions.md
sr Generic.swift generic
se Largest.swift largest
MD=$HERE/constraints.md
sr Constrained.swift constrained
se NotComparable.swift notcomparable
sr WeekTotal.swift weektotal
MD=$HERE/generic-types.md
sr Stack.swift stack
MD=$HERE/associated-types.md
sr Store.swift store
MD=$HERE/some.md
sr Some.swift some
se TwoTypes.swift twotypes
MD=$HERE/any.md
sr Box.swift box
se AnyStore.swift anystore
