#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file of the package, Package.swift and the tests included, is lifted
# out of this lesson's .md by ../../lab.sh, so the file compiled is the block
# the student copies. The package grows section by section: each section
# writes the files it shows over the ones before, and nothing else.
#
# STAGED: in section 05, `async-confirm` is the same test file with
# `expectedCount: 2` changed to 3 by `sed`, as the prose says, and changed
# back afterwards.
#
# Swift Testing runs tests in parallel, so the order of its lines is the
# order of this run; another run interleaves them differently.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
G='grep -v frontend'

fresh sw/l18/planner

MD=$HERE/xctest.md
put "$MD" Package.swift
put "$MD" Tests/PlannerCoreTests/WeekXCTests.swift
block xctest-fail
put "$MD" Sources/PlannerCore/Week.swift 1
run "swift build --build-tests 2>&1 | tail -1"
run "swift test --disable-swift-testing 2>&1 | $G"
block xctest-pass
put "$MD" Sources/PlannerCore/Week.swift 2
run "swift test --disable-swift-testing 2>&1 | $G"

MD=$HERE/swift-testing.md
put "$MD" Tests/PlannerCoreTests/WeekTests.swift
block testing-fail
put "$MD" Sources/PlannerCore/Week.swift 1
run "swift test --disable-xctest 2>&1 | $G"
block testing-pass
put "$MD" Sources/PlannerCore/Week.swift 2
run "swift test --disable-xctest 2>&1 | $G"

MD=$HERE/parameterised.md
put "$MD" Tests/PlannerCoreTests/ProgressTests.swift
block param-fail
run "swift test --disable-xctest --filter ProgressTests 2>&1 | $G"
block param-pass
put "$MD" Sources/PlannerCore/Week.swift
run "swift test --disable-xctest --filter ProgressTests 2>&1 | $G"

MD=$HERE/async-tests.md
put "$MD" Sources/PlannerCore/Syncer.swift
put "$MD" Tests/PlannerCoreTests/SyncerTests.swift
block async-pass
run "swift test --disable-xctest --filter SyncerTests 2>&1 | $G"
block async-confirm
quiet "sed -i 's/expectedCount: 2/expectedCount: 3/' Tests/PlannerCoreTests/SyncerTests.swift"
run "swift test --disable-xctest --filter reportsEachSavedSession 2>&1 | $G"
put "$MD" Tests/PlannerCoreTests/SyncerTests.swift

MD=$HERE/doubles.md
put "$MD" Tests/PlannerCoreTests/OfflineTests.swift
block doubles-pass
run "swift test --disable-xctest --filter OfflineTests 2>&1 | $G"

MD=$HERE/running.md
block running-list
run "swift test list"
block running-skip
run "swift test --skip Syncer 2>&1 | $G | tail -4"
block running-cover
run "swift test --enable-code-coverage 2>&1 | $G | tail -3"
run "swift test --show-codecov-path"
block running-llvm
run "llvm-cov report .build/debug/PlannerCoreTests.so -instr-profile=.build/debug/codecov/default.profdata -ignore-filename-regex=Tests -show-region-summary=false -show-branch-summary=false -show-instantiation-summary=false -show-mcdc-summary=false"
