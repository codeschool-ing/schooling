#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies; the
# annotated Copies.swift is its parts joined as the copy button joins them.
# Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l05
MD=$HERE/two-kinds.md
se Kinds.swift kinds
sc KindsFixed.swift kindsfixed
MD=$HERE/value-copies.md
sr Copies.swift copies
se Param.swift param
MD=$HERE/reference-shares.md
sr Shares.swift shares
MD=$HERE/mutating.md
se Mutating.swift mutating
sc WeekLog.swift weeklog
se Frozen.swift frozen
MD=$HERE/identity.md
sr Identity.swift identity
se NoEquals.swift noequals
MD=$HERE/copy-on-write.md
sr Cow.swift cow
sr Unique.swift unique
MD=$HERE/choosing.md
sr Choosing.swift choosing
