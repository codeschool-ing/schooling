#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# SwiftData does not exist on Linux, and `wall` records the compiler saying
# so. `query` and `refused` run the Foundation half of a query, #Predicate
# and SortDescriptor, on lesson 1's values. Lesson 1's four package files
# come from its the-package.md, and this lesson's Package.swift,
# swiftdata.swift and Sources/query/main.swift from what-runs-here.md, so
# the files compiled are the blocks the student copies. Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md
MD=$HERE/what-runs-here.md

fresh l13
put "$MD" swiftdata.swift
block wall
run 'swift swiftdata.swift'

for f in Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift Sources/week/main.swift \
         Tests/PlannerCoreTests/PlanTests.swift; do put "$L1" "$f"; done
put "$MD" Package.swift
put "$MD" Sources/query/main.swift
block query
run 'swift build'
run '.build/debug/query'

block refused
run "echo 'let thisWeek = #Predicate<StudySession> { mondayOf(\$0.date) == \"2026-10-19\" }' >> Sources/query/main.swift"
run 'swift build 2>&1 | grep -m1 "Global functions"'
run "sed -i '\$d' Sources/query/main.swift"
run 'swift build 2>&1 | tail -1'
