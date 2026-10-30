#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled here is lifted out of a lesson's .md by ../../lab.sh,
# so the file compiled is the block the student copies.
#
# What is STAGED rather than typed:
#   - the prose tells the student to `cp -r ~/planner ~/observe`; here
#     ~/observe is filled with lesson 1's files straight from lesson 1's
#     the-package.md, then this lesson's Package.swift (which replaces
#     lesson 1's), PlannerModel.swift and track/main.swift.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md

fresh observe
for f in Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift \
         Sources/week/main.swift Tests/PlannerCoreTests/PlanTests.swift; do put "$L1" "$f"; done
put "$HERE/observable.md" Package.swift
put "$HERE/observable.md" Sources/PlannerCore/PlannerModel.swift
put "$HERE/what-is-tracked.md" Sources/track/main.swift
block track
run 'swift build 2>&1 | grep -E "error|warning"'
run '.build/debug/track'
