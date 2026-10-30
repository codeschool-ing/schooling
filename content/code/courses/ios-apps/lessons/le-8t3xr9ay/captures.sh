#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled here is lifted out of a lesson's .md by ../../lab.sh,
# so the file compiled is the block the student copies.
#
# What is STAGED rather than typed:
#   - derived: the prose tells the student to `cp -r ~/planner ~/derived`;
#     here ~/derived is filled with lesson 1's five files straight from
#     lesson 1's the-package.md, which is the same package, so this lesson's
#     capture does not depend on the state lesson 1's capture left behind;
#     the package is built once, quietly, before the transcript starts, so
#     the transcript shows the test run rather than the first compile.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md

fresh bindings
put "$HERE/binding-by-hand.md" binding.swift
block binding
run 'swift binding.swift'

fresh derived
for f in Package.swift Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift \
         Sources/week/main.swift Tests/PlannerCoreTests/PlanTests.swift; do put "$L1" "$f"; done
put "$HERE/derived-values.md" Tests/PlannerCoreTests/DerivedTests.swift
quiet 'swift build --build-tests'
block derived
run 'swift test --filter TotalFollows'
