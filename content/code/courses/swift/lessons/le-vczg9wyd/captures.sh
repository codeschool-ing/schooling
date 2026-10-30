#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies; the
# annotated Patterns.swift is its parts joined as the copy button joins them.
# Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l07
MD=$HERE/cases.md
sc Cases.swift cases
MD=$HERE/associated-values.md
sr Associated.swift associated
MD=$HERE/switch.md
se Missing.swift missing
sr Grades.swift grades
MD=$HERE/patterns.md
sr Patterns.swift patterns
MD=$HERE/optional-is-an-enum.md
sr Optional.swift optional
MD=$HERE/state.md
sr Status.swift status
