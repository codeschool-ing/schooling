---
title: What to test, and what coverage does not say
version: 1
---

**Test the rules where they live, in the package, and keep the app's tests for what only the app can
do.** Every test in this lesson so far is in `Tests/PlannerCoreTests/`, runs in a fraction of a second
on any computer, and checks a rule a person would notice breaking: the week's sum, the Monday of a
day, an error that must reach the screen. The UI tests of section 06 check a handful of flows end to
end. Previews are for looking.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l20-where\" aria-label=\"Where each kind of test lives. On the left, the planner&#x27;s Swift package, with its unit tests in Swift Testing and XCTest, run by swift test on any computer in a fraction of a second. On the right, the Xcode project on a Mac, holding the UI tests, which launch the app in a simulator and take seconds each, and the previews, which are looked at rather than run. The arrow from the package to the app says the app imports the tested rules.\"><defs><marker id=\"l20-where-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l20-where-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-where-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l20-where-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"320\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">the package, any computer</text><rect x=\"40\" y=\"66\" width=\"280\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Swift Testing</text><text x=\"180\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the week, Mondays, loading</text><rect x=\"40\" y=\"136\" width=\"280\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">XCTest</text><text x=\"180\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the older tests, beside them</text><rect x=\"40\" y=\"206\" width=\"280\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">swift test</text><text x=\"180\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milliseconds, on every change</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"550\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the app, on a Mac (not run here)</text><rect x=\"420\" y=\"66\" width=\"260\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">UI tests (XCTest)</text><text x=\"550\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a few flows, seconds each</text><rect x=\"420\" y=\"136\" width=\"260\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">#Preview</text><text x=\"550\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">looked at, never failing</text><rect x=\"420\" y=\"206\" width=\"260\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PlannerApp</text><text x=\"550\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">imports PlannerCore</text><path d=\"M340 233 L418 233\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-where-ah-phosphor)\"></path></svg>", "caption": "The rules are tested where they live, fast and anywhere; the app keeps the few tests only an app can run."}
```

## Coverage, measured once

`swift test --enable-code-coverage` records which lines of the package the tests ran, and
`llvm-cov`, which the toolchain ships, reports it. The test binary on Linux is
`.build/debug/PlannerCoreTests.so`; on a Mac it is a bundle ending in `.xctest`, and
`swift test --show-codecov-path` prints where SwiftPM writes the same report as JSON:

```
ana@vm:~/l20$ swift test --enable-code-coverage > /dev/null 2>&1; echo $?
0
ana@vm:~/l20$ llvm-cov report .build/debug/PlannerCoreTests.so -instr-profile .build/debug/codecov/default.profdata -ignore-filename-regex Tests -show-region-summary=false -show-branch-summary=false
Filename                    Functions  Missed Functions  Executed       Lines      Missed Lines     Cover
---------------------------------------------------------------------------------------------------------
Days.swift                          4                 1    75.00%          18                 1    94.44%
Loading.swift                       1                 0   100.00%           4                 0   100.00%
Plan.swift                         12                 0   100.00%          40                 2    95.00%
---------------------------------------------------------------------------------------------------------
TOTAL                              17                 1    94.12%          62                 3    95.16%
ana@vm:~/l20$ llvm-cov show .build/debug/PlannerCoreTests.so -instr-profile .build/debug/codecov/default.profdata Sources/PlannerCore/Plan.swift | grep -E "^ +[0-9]+\| +0\|"
   51|      0|        sessions.append(session)
   52|      0|    }
```

**The number is less interesting than the two lines it points at.** Lines 51 and 52 of `Plan.swift`
are the end of `add`: the session appended, the success path. Every test that calls `add` expects it
to refuse, and no test adds a valid session and checks it is there. `week/main.swift` does it, and a
program is not a test. That is a missing test with a name, and it is worth writing.

What is missed in `Days.swift` is the other kind. It belongs to the `preconditionFailure`, whose
message is a closure that runs only for a day that is not a day, and testing it would mean a test
that crashes on purpose. Lesson 10 checks
typed text before it gets that far, which is where that case is tested.

**So coverage is a map, not a target.** A line nobody runs is a question: is this a case nobody
thought of, or a case that cannot happen? Raising the percentage by writing tests that touch lines
without asserting anything answers neither, and makes the next map harder to read.

## The order to write them in

When a bug is found, the first thing written is the test that fails because of it, and then the fix
that makes it pass. The test is the bug's description in a form that cannot be forgotten. The same
habit answers "what should I test next?" in a project with few tests: **the next bug**, and then the
cases beside it, the way section 03 tested the boundaries beside a week.
