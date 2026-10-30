#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled here is lifted out of a lesson's .md by ../../lab.sh:
# the package's lesson 1 files from lesson 1's the-package.md, and this
# lesson's from phase-machine.md, so the file compiled is the block the
# student copies.
#
# What is STAGED rather than typed: the package from lesson 1 is rebuilt
# in ~/l02/planner from lesson 1's blocks, standing for the student's own
# ~/planner.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md
MD=$HERE/phase-machine.md

fresh l02/planner
for f in Package.swift Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift \
         Sources/week/main.swift Tests/PlannerCoreTests/PlanTests.swift; do put "$L1" "$f"; done
quiet 'swift build'

put "$MD" Sources/PlannerCore/Lifecycle.swift 1
put "$MD" Tests/PlannerCoreTests/LifecycleTests.swift
block first
run 'swift test 2>&1 | grep -v "^\[" | grep -v "^Test Suite\|Executed 0 tests"'

put "$MD" Sources/PlannerCore/Lifecycle.swift 2
block second
run 'swift test 2>&1 | grep -v "^\[" | grep -v "^Test Suite\|Executed 0 tests"'
