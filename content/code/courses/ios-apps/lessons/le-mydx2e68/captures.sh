#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled here is lifted out of a lesson's .md by ../../lab.sh,
# so the file compiled is the block the student copies.
#
# What is STAGED rather than typed:
#   - editing: the prose tells the student to `cp -r ~/planner ~/editing`;
#     here ~/editing is filled with lesson 1's five files straight from
#     lesson 1's the-package.md, and built once, quietly, before the
#     transcript, so it shows the test run rather than the first compile.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md

fresh rows
put "$HERE/ids-not-indices.md" identity.swift
put "$HERE/performance.md" diff.swift
block identity
run 'swift identity.swift'
block diff
run 'swift diff.swift'

fresh editing
for f in Package.swift Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift \
         Sources/week/main.swift Tests/PlannerCoreTests/PlanTests.swift; do put "$L1" "$f"; done
put "$HERE/edit-move.md" Sources/PlannerCore/PlanEditing.swift
put "$HERE/edit-move.md" Tests/PlannerCoreTests/EditingTests.swift
quiet 'swift build --build-tests'
block editing
run 'swift test --filter Editing'
