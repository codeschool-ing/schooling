#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
#
# STAGED: the two programs that crash (`uncaught`, `tryvariants`) are run
# under `script`, a pseudo-terminal, because that is where the student runs
# them. Through a pipe, the lines a Swift program printed before it crashed
# sit in a buffer and are lost with the process; in a terminal each line is
# written as it is printed.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
trun() { _prompt "$_D" "$*"; bash "$LAB_SH" exec "$_D" "script -qec $(printf %q "$*") /dev/null" | tr -d '\r' | _strip; }

fresh sw/l12
MD=$HERE/throws.md
se Throws.swift throws
block uncaught
put "$MD" Uncaught.swift
run 'swiftc Uncaught.swift -o uncaught'
trun 'SWIFT_BACKTRACE=enable=no ./uncaught'
MD=$HERE/do-catch.md
sr DoCatch.swift docatch
se NotExhaustive.swift notexhaustive
MD=$HERE/try-variants.md
block tryvariants
put "$MD" TryVariants.swift
run 'swiftc TryVariants.swift -o tryvariants'
trun 'SWIFT_BACKTRACE=enable=no ./tryvariants'
MD=$HERE/typed-throws.md
sr Typed.swift typed
se TypedWrong.swift typedwrong
MD=$HERE/result.md
sr ResultDemo.swift result
MD=$HERE/rethrows.md
sr Rethrows.swift rethrows
