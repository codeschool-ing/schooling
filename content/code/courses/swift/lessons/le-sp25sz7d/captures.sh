#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
# Nothing is staged. The two SwiftUI fragments in wrappers-outside.md and
# builders-outside.md are not compiled anywhere: SwiftUI does not exist on
# Linux, and the lesson says so beside each of them.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l16
MD=$HERE/wrappers-outside.md
sr ByHand.swift byhand
MD=$HERE/writing-a-wrapper.md
sr Clamped.swift clamped
sc Storage.swift storage
MD=$HERE/projected-value.md
sr Projected.swift projected
MD=$HERE/builders-outside.md
sr LogLine.swift logline
MD=$HERE/writing-a-builder.md
sr Report.swift report
se ReportLoop.swift reportloop
sr ReportFull.swift reportfull
MD=$HERE/macros.md
block observed
put "$MD" Observed.swift
run 'swiftc Observed.swift -o observed && ./observed'
block expand
run "swiftc -Xfrontend -dump-macro-expansions Observed.swift -o observed 2>&1 | sed -n '/private  var _minutes/p; /^    get {/,/^    }/p'"
