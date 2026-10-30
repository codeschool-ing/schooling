#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
# Nothing is staged. Reminder.swift's second line reads the machine's real
# clock: it was recorded on 30 October 2026, which no session in the list
# falls on.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l10
MD=$HERE/inheritance-problem.md
sr Hierarchy.swift hierarchy
MD=$HERE/composition.md
sr Composed.swift composed
MD=$HERE/mixins.md
sr Mixins.swift mixins
MD=$HERE/injection.md
sr Reminder.swift reminder
MD=$HERE/when-classes.md
se Final.swift final
