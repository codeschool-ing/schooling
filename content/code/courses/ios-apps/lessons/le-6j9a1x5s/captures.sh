#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled here is lifted out of this lesson's .md, or out of
# lesson 1's the-package.md for the package it starts from, so the file
# compiled is the block the student copies.
#
# What is STAGED rather than typed: ~/l20 is lesson 1's package written
# fresh from lesson 1's blocks (the lesson's `cp -r ~/planner ~/l20`), and
# it is built once, quietly, before the first transcript, so the first
# transcript is not a page of compiler progress.
#
# Nothing from Xcode was run: the UI tests, the previews and the test
# navigator are written from Apple's documentation and marked not run.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
P1=$HERE/../le-r8sx9rjk/the-package.md
T=Tests/PlannerCoreTests

fresh l20
for f in Package.swift Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift \
         Sources/week/main.swift $T/PlanTests.swift; do put "$P1" "$f"; done
put "$HERE/swift-testing.md" $T/WeekTests.swift
put "$HERE/parameterised.md" $T/MondayTests.swift
put "$HERE/async-tests.md" Sources/PlannerCore/Loading.swift
put "$HERE/async-tests.md" $T/LoadingTests.swift
put "$HERE/xctest.md" $T/LegacyTests.swift
quiet 'swift build --build-tests'

block suite
run 'swift test --filter WeekTests 2>&1 | grep -E "^(✔|✘)"'

block params
run 'swift test --filter "sameMonday|crossing" 2>&1 | grep -E "^(✔|✘)"'

block params-fail
run "sed -i 's/(weekday + 5) % 7/(weekday + 6) % 7/' Sources/PlannerCore/Days.swift"
run 'swift test --filter crossing 2>&1 | grep -E "^(✘|↳)"'
run 'swift test --filter sameMonday 2>&1 | grep -E "^✘ Test .* failed after"'
run "sed -i 's/(weekday + 6) % 7/(weekday + 5) % 7/' Sources/PlannerCore/Days.swift"

block async
run 'swift test --filter Loading 2>&1 | grep -E "^(✔|✘)"'

block xctest
run 'swift test --filter LegacyTests 2>&1 | grep -E "^(Test Case|Test Suite .LegacyTests|	 Executed)" | head -6'

block coverage
run 'swift test --enable-code-coverage > /dev/null 2>&1; echo $?'
run 'llvm-cov report .build/debug/PlannerCoreTests.so -instr-profile .build/debug/codecov/default.profdata -ignore-filename-regex Tests -show-region-summary=false -show-branch-summary=false'
run 'llvm-cov show .build/debug/PlannerCoreTests.so -instr-profile .build/debug/codecov/default.profdata Sources/PlannerCore/Plan.swift | grep -E "^ +[0-9]+\| +0\|"'
