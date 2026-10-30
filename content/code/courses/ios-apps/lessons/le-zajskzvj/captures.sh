#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Lesson 1's four package files come from its the-package.md; this lesson's
# files from triggers.md (Package.swift with `remind`, Reminders.swift,
# remind/main.swift, ReminderTests.swift) and payload.md (Package.swift with
# `push`, Push.swift, push/main.swift). So the files compiled are the blocks
# the student copies.
#
# Nothing is staged: the dates and the Lisbon time zone are written in the
# program, and the time-zone rules are the ones Ubuntu's tzdata carries. No
# notification is scheduled or sent: the User Notifications framework and
# APNs are not on this machine.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md
T=$HERE/triggers.md
P=$HERE/payload.md

fresh l17
for f in Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift Sources/week/main.swift \
         Tests/PlannerCoreTests/PlanTests.swift; do put "$L1" "$f"; done
for f in Package.swift Sources/PlannerCore/Reminders.swift Sources/remind/main.swift \
         Tests/PlannerCoreTests/ReminderTests.swift; do put "$T" "$f"; done
block remind
run 'swift build'
run '.build/debug/remind'
run 'swift test 2>&1 | grep "✔"'

for f in Package.swift Sources/PlannerCore/Push.swift Sources/push/main.swift; do put "$P" "$f"; done
block push
run 'swift build'
run '.build/debug/push'
