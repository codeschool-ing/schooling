#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled here is lifted out of a lesson's .md by ../../lab.sh,
# so the file compiled is the block the student copies.
#
# What is STAGED rather than typed:
#   - the prose tells the student to `cp -r ~/planner ~/navigate`; here
#     ~/navigate is filled with lesson 1's five files straight from lesson
#     1's the-package.md, and built once, quietly, before the first
#     transcript, so `route` shows an incremental build of the new file.
#     The three sections then add their files in the order the lesson does.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md

fresh navigate
for f in Package.swift Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift \
         Sources/week/main.swift Tests/PlannerCoreTests/PlanTests.swift; do put "$L1" "$f"; done
quiet 'swift build'

put "$HERE/the-path.md" Sources/PlannerCore/Route.swift
block route
run 'swift build'

put "$HERE/saving-the-path.md" Package.swift
put "$HERE/saving-the-path.md" Sources/PlannerCore/RoutePruning.swift
put "$HERE/saving-the-path.md" Sources/paths/main.swift
quiet 'swift build'
block paths
run '.build/debug/paths'

put "$HERE/deep-links.md" Sources/PlannerCore/RouteLinks.swift
put "$HERE/deep-links.md" Tests/PlannerCoreTests/RouteLinkTests.swift
quiet 'swift build --build-tests'
block links
run 'swift test --filter Link'
