#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
# Nothing is staged. The network is played by Task.sleep and by
# DispatchQueue.asyncAfter, as the lesson says; the timings printed are the
# ones measured on the recording machine and differ by a few milliseconds
# from run to run.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l14
MD=$HERE/why.md
sr Callbacks.swift callbacks
MD=$HERE/async-await.md
sr Planner.swift planner
se Report.swift report
MD=$HERE/task.md
sr Tasks.swift tasks
sr Forgotten.swift forgotten
MD=$HERE/async-let.md
sr Week.swift week
MD=$HERE/task-group.md
sr Group.swift group
MD=$HERE/cancellation.md
sr Cancel.swift cancel
sr Cooperate.swift cooperate
