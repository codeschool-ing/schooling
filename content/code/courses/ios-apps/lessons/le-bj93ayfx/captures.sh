#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled here is lifted out of this lesson's .md, or out of
# lesson 1's the-package.md for the package it starts from, so the file
# compiled is the block the student copies.
#
# What is STAGED rather than typed: ~/l19 is lesson 1's package, written
# fresh from lesson 1's blocks, as the lesson tells the student to copy it.
# Nothing from SwiftUI, VoiceOver or Xcode's Accessibility Inspector was run.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
P1=$HERE/../le-r8sx9rjk/the-package.md

fresh l19
for f in Package.swift Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift \
         Sources/week/main.swift Tests/PlannerCoreTests/PlanTests.swift; do put "$P1" "$f"; done
put "$HERE/labels-values.md" Sources/PlannerCore/SpokenLabels.swift
put "$HERE/labels-values.md" Tests/PlannerCoreTests/SpokenLabelTests.swift
quiet 'swift build'
block labels
run 'swift test 2>&1 | grep -E "^(✔|✘|◇ Test run|Expectation)|passed after|failed after"'

fresh contrast
put "$HERE/contrast.md" contrast.swift
block contrast
run 'swift contrast.swift'
