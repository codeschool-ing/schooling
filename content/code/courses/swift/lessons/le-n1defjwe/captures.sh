#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of swift, as a script that
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

fresh sw/l02
MD=$HERE/two-types.md
se TwoMistakes.swift twomistakes
sr Nulls.swift nulls
sr Spelled.swift spelled
MD=$HERE/if-let.md
sr IfLet.swift iflet
sr Shorthand.swift shorthand
sr Several.swift several
MD=$HERE/guard-let.md
sr GuardLet.swift guardlet
se FallThrough.swift fallthrough
MD=$HERE/coalescing.md
sr Chain.swift chain
sr Coalesce.swift coalesce
MD=$HERE/force-unwrap.md
block bang
put "$MD" Bang.swift
run 'swiftc Bang.swift -o bang'
run './bang 2>&1 | head -5'
run "script -qc ./bang /dev/null | tr -d '\\r' | head -2"
MD=$HERE/optional-map.md
sr OptionalMap.swift optionalmap
