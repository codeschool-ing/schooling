#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
# Nothing is staged: planner.json is written by Encode.swift in the first
# block and read by Decode.swift in the second, in the same directory.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l13
MD=$HERE/encode.md
block encode
put "$MD" Encode.swift
run 'swift Encode.swift'
run 'cat planner.json; echo'
block order
run 'for run in 1 2 3; do swift Encode.swift | head -1; done'
MD=$HERE/decode.md
sr Decode.swift decode
MD=$HERE/coding-keys.md
sr Keys.swift keys
sr Snake.swift snake
MD=$HERE/dates.md
sr Dates.swift dates
MD=$HERE/missing.md
sr Missing.swift missing
sr Defaults.swift defaults
MD=$HERE/errors.md
sr Errors.swift errors
