#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled or run here is lifted out of a lesson's .md by
# ../../lab.sh: lesson 1's package files from its the-package.md, and this
# lesson's from its own sections, so the file run is the block the student
# copies. The lesson works in ~/planner and ~/server, as it tells the
# student to; both are emptied and rebuilt from the lessons first.
#
# What is STAGED rather than typed:
#   - the server. The lesson has the student start `python3 serve.py` in a
#     second terminal and leave it running. Here it is started in the
#     background with setsid, its output going to ~/server/serve.log, and
#     stopped with kill at the end; the block server-log prints the command
#     the student types and then that log, which is what their second
#     terminal shows by the end of the lesson.
#   - `swift build` is piped to `tail -1`, shown as typed, so each build is
#     one line; section 03's first build keeps only the `error:` lines with
#     grep, also shown.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2 and Python 3.12, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md

at .
quiet 'rm -rf ~/planner ~/server && mkdir -p ~/planner/Sources/PlannerCore ~/planner/Sources/week ~/planner/Sources/fetch ~/planner/Tests/PlannerCoreTests ~/server'
at planner
for f in Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift Sources/week/main.swift \
         Tests/PlannerCoreTests/PlanTests.swift; do put "$L1" "$f"; done
at server
put "$HERE/the-server.md" serve.py
quiet '{ setsid python3 serve.py > serve.log 2>&1 < /dev/null & echo $! > serve.pid; }'
sleep 1

block curl
run 'curl -si http://127.0.0.1:8012/courses'
run 'curl -s http://127.0.0.1:8012/courses/sql/sessions'
run 'curl -si http://127.0.0.1:8012/courses/art/sessions'

at planner
MD=$HERE/fetching.md
put "$MD" Package.swift
put "$MD" Sources/fetch/main.swift 1
block no-import
run 'swift build 2>&1 | grep error:'
put "$MD" Sources/fetch/main.swift 2
block fetch
run 'swift build | tail -1'
run '.build/debug/fetch'

MD=$HERE/decoding.md
put "$MD" Sources/PlannerCore/Wire.swift
put "$MD" Sources/fetch/main.swift
block decode
run 'swift build | tail -1'
run '.build/debug/fetch'
put "$MD" Tests/PlannerCoreTests/WireTests.swift
block wire-tests
run 'swift test 2>&1 | grep -E "✔|✘"'

MD=$HERE/status-codes.md
put "$MD" Sources/PlannerCore/APIClient.swift
put "$MD" Sources/fetch/main.swift
block outcomes
run 'swift build | tail -1'
run '.build/debug/fetch'

MD=$HERE/the-error-state.md
put "$MD" Sources/PlannerCore/Loadable.swift
put "$MD" Sources/fetch/main.swift
block states
run 'swift build | tail -1'
run '.build/debug/fetch'

MD=$HERE/cancellation.md
put "$MD" Sources/fetch/main.swift
block cancel
run 'swift build | tail -1'
run '.build/debug/fetch'

sleep 3   # the cancelled and timed-out requests finish on the server's side
at server
block server-log
_prompt server 'python3 serve.py'
bash "$LAB_SH" exec server 'cat serve.log'
quiet 'kill $(cat serve.pid); rm -f serve.pid serve.log'
