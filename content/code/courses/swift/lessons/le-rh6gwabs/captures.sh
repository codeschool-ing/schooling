#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
#
# STAGED: the two programs that crash (`unowned`) are run under `script`, a
# pseudo-terminal, because that is where the student runs them. Through a
# pipe, the lines a Swift program printed before it crashed sit in a buffer
# and are lost with the process; in a terminal each line is written as it is
# printed. The `bash: line 1:` prefix on the crash report is the
# non-interactive shell the capture runs in; an interactive terminal says the
# same thing without it.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
trun() { _prompt "$_D" "$*"; bash "$LAB_SH" exec "$_D" "script -qec $(printf %q "$*") /dev/null" | tr -d '\r' | _strip; }

fresh sw/l11
MD=$HERE/arc.md
sr Arc.swift arc
MD=$HERE/cycle.md
sr Cycle.swift cycle
MD=$HERE/weak.md
sr Weak.swift weak
MD=$HERE/unowned.md
block unowned
put "$MD" Unowned.swift
run 'swiftc Unowned.swift -o unowned'
trun 'SWIFT_BACKTRACE=enable=no ./unowned'
MD=$HERE/closures.md
sr Closures.swift closures
MD=$HERE/finding-leaks.md
block asan
put "$HERE/cycle.md" Cycle.swift
run 'swiftc -sanitize=address Cycle.swift -o cycle-asan 2>&1 | grep -c "warning: Cannot export"'
run './cycle-asan 2>&1 | swift demangle --simplified | grep -E "leak of|SUMMARY|__allocating_init"'
block asanweak
put "$HERE/weak.md" Weak.swift
run 'swiftc -sanitize=address Weak.swift -o weak-asan 2>/dev/null'
run './weak-asan 2>&1 | grep -c "leak of"'
