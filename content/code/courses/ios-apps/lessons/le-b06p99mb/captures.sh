#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled here is lifted out of a lesson's .md by ../../lab.sh:
# lesson 1's four package files from its the-package.md, and this lesson's
# Package.swift, SessionDraft.swift, DraftTests.swift and main.swift from
# validation.md and numbers-and-dates.md. So the files compiled are the
# blocks the student copies.
#
# Nothing is staged: the dates the program reads are written in it.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md

fresh l10
for f in Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift Sources/week/main.swift \
         Tests/PlannerCoreTests/PlanTests.swift; do put "$L1" "$f"; done
put "$HERE/validation.md" Package.swift
put "$HERE/validation.md" Sources/PlannerCore/SessionDraft.swift
put "$HERE/validation.md" Tests/PlannerCoreTests/DraftTests.swift
put "$HERE/numbers-and-dates.md" Sources/draft/main.swift

block test
run 'swift test'
block draft
run 'swift build'
run '.build/debug/draft'
