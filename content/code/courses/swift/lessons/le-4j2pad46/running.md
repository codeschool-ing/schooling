---
title: Choosing what runs, and what a number says
version: 1
---

The test target now holds ten tests in two frameworks, and they finish in well under a second. A
real project's suite takes minutes, and while you work on one function you want the tests about
that function, not all of them. **`swift test` can list the tests, run a subset, skip a subset, and
measure which lines the tests reached.**

## Listing

```
ana@vm:~/sw/l18/planner$ swift test list
Building for debugging...
[Using on-disk description]
Build complete! (1.01 secs)
PlannerCoreTests.WeekXCTests/testRemainingNeverGoesBelowZero
PlannerCoreTests.WeekXCTests/testTotalCountsOnlyDoneSessions
PlannerCoreTests.OfflineTests/aFailureHalfwayKeepsWhatWasSaved()
PlannerCoreTests.OfflineTests/anOfflineStoreStopsTheSync()
PlannerCoreTests.ProgressTests/progress(minutes:expected:)
PlannerCoreTests.SyncerTests/reportsEachSavedSession()
PlannerCoreTests.SyncerTests/savesOnlyDoneSessions()
PlannerCoreTests.WeekTests/firstSessionIsTheOneAdded()
PlannerCoreTests.WeekTests/progress()
PlannerCoreTests.WeekTests/total()
```

One line per test, as `module.Type/test` for a test inside a type and `module.test` for a free
function. The two XCTest tests come first, named the XCTest way, and the Swift Testing ones follow
with their parentheses and argument labels. These names are what `--filter` and `--skip` match.

## Filtering and skipping

Sections 04 to 06 used `--filter` with a suite's name. **The argument is a regular expression**,
matched against these names, so `--filter Syncer` runs every test whose name contains `Syncer` and
`--filter 'progress\('` runs the tests named `progress`, whichever type they are in. `--skip` is the
opposite, and the two can be combined:

```
ana@vm:~/sw/l18/planner$ swift test --skip Syncer 2>&1 | grep -v frontend | tail -4
✔ Suite "A week of study" passed after 0.001 seconds.
✔ Suite ProgressTests passed after 0.001 seconds.
✔ Suite OfflineTests passed after 0.001 seconds.
✔ Test run with 6 tests in 3 suites passed after 0.001 seconds.
```

`tail -4` keeps the last four lines. **Six tests ran in Swift Testing**, the eight minus the two in
`SyncerTests`, and the two XCTest tests ran too, in the part of the output `tail` cut off, because
`--skip` applies to both frameworks. A test you skip is a test you are not running; skipping is for the length of a task,
and the full suite runs before the change is finished.

**Swift Testing runs in parallel by default; XCTest runs one test at a time** unless `swift test
--parallel` is given, which starts several test processes for it. A suite that passes in order and
fails in parallel has tests that share something, a file, a global or a database row, and the
failure is real information about the code even when it is inconvenient.

## Coverage, and what it does not mean

`--enable-code-coverage` records which lines of the code ran while the tests ran, and
`--show-codecov-path` says where the result went:

```
ana@vm:~/sw/l18/planner$ swift test --enable-code-coverage 2>&1 | grep -v frontend | tail -3
✔ Suite ProgressTests passed after 0.002 seconds.
✔ Suite "A week of study" passed after 0.001 seconds.
✔ Test run with 8 tests in 4 suites passed after 0.002 seconds.
ana@vm:~/sw/l18/planner$ swift test --show-codecov-path
/home/ana/sw/l18/planner/.build/out/Products/Debug-linux-x86_64/codecov/planner.json
```

The JSON file is for tools. The toolchain's `llvm-cov` reads the raw data beside it and prints a
table; `-ignore-filename-regex=Tests` leaves the test files out, and the four `-show-…=false`
options drop the columns about branches and regions, which this lesson does not need:

```
ana@vm:~/sw/l18/planner$ llvm-cov report .build/debug/PlannerCoreTests.so -instr-profile=.build/debug/codecov/default.profdata -ignore-filename-regex=Tests -show-region-summary=false -show-branch-summary=false -show-instantiation-summary=false -show-mcdc-summary=false
Filename                    Functions  Missed Functions  Executed       Lines      Missed Lines     Cover
---------------------------------------------------------------------------------------------------------
Syncer.swift                        4                 0   100.00%          13                 0   100.00%
Week.swift                         10                 0   100.00%          18                 0   100.00%
---------------------------------------------------------------------------------------------------------
TOTAL                              14                 0   100.00%          31                 0   100.00%
```

**Every line of `Week.swift` and `Syncer.swift` ran.** That is a fact about the lines, and nothing
more. The progress bug of section 03 sat on a line that ran in every test of section 02 that touched
a week's total, and coverage would have reported it as covered; what caught it was a test that
**stated** 15% and compared. A test that calls `progress` and checks nothing raises the percentage
exactly as much as one that checks the right answer.

So read coverage the other way round: **a line nobody runs is a line no test can be catching
anything about**, and a low number in a file is a list of places to look. A high number is not a
verdict, and adding tests to raise it, rather than to state something the code must do, produces
tests that state nothing.
