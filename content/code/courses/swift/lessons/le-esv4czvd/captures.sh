#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies; the
# two annotated examples are joined part by part, as the copy button joins
# them. Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l03
MD=$HERE/functions.md
sr Functions.swift functions
se Unused.swift unused
MD=$HERE/labels.md
sr Labels.swift labels
se NoLabels.swift nolabels
MD=$HERE/defaults-inout.md
sr Defaults.swift defaults
sr Variadic.swift variadic
se ParamLet.swift paramlet
sr Inout.swift inout
MD=$HERE/closures.md
sr FunctionValues.swift functionvalues
sr Shorthand.swift shorthand
MD=$HERE/trailing.md
sr Trailing.swift trailing
sr TwoClosures.swift twoclosures
MD=$HERE/capturing.md
sr Counter.swift counter
sr CaptureList.swift capturelist
se Escaping.swift escaping
