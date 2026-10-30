---
title: Test doubles, through the protocol
version: 1
---

`MemoryStore` in section 05 stood in for a real server. A stand-in like that is a **test double**,
named after the stunt double who takes the fall so the actor does not, and the protocol from lesson
10 is what made one possible: `Syncer` asks for `any SessionStore`, and anything conforming will do.
A double is how a test reaches the cases a real server would only produce on a bad day.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l18-seam\" aria-label=\"Syncer asks for any SessionStore, a protocol. Four things conform to it: the real server, used by the app; MemoryStore, a fake that keeps sessions in an array; OfflineStore, a stub that always throws; and FlakyStore, a spy that counts its calls and fails the second.\"><defs><marker id=\"l18-seam-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-seam-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"110\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Syncer</text><text x=\"105\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">asks for a store</text><rect x=\"260\" y=\"110\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"355\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">any SessionStore</text><text x=\"355\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the seam, a protocol</text><path d=\"M182 140 L256 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-seam-ah-phosphor)\"></path><rect x=\"520\" y=\"30\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the real server</text><text x=\"610\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">in the app</text><path d=\"M516 55 L452 140\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-seam-ah-amber)\"></path><rect x=\"520\" y=\"100\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">MemoryStore</text><text x=\"610\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fake: an array</text><path d=\"M516 125 L452 140\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-seam-ah-amber)\" stroke-dasharray=\"5 4\"></path><rect x=\"520\" y=\"170\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">OfflineStore</text><text x=\"610\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">stub: always throws</text><path d=\"M516 195 L452 140\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-seam-ah-amber)\" stroke-dasharray=\"5 4\"></path><rect x=\"520\" y=\"240\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">FlakyStore</text><text x=\"610\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">spy: counts, fails 2nd</text><path d=\"M516 265 L452 140\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-seam-ah-amber)\" stroke-dasharray=\"5 4\"></path><text x=\"250\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Syncer is compiled once, and</text><text x=\"250\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">never knows which one it got.</text></svg>", "caption": "The protocol is the seam: the code under test asks for any SessionStore, and each test hands it the double that produces the case it needs."}
```

## Four kinds, by what they are for

The names come from Gerard Meszaros's book on test patterns and are used loosely; what matters is
what each one lets a test do.

| double | what it does | in this lesson |
|---|---|---|
| **fake** | works, in a simpler way than the real thing | `MemoryStore`, an array instead of a server |
| **stub** | gives a fixed answer, or a fixed failure | `OfflineStore` below, which always throws |
| **spy** | records how it was used, for the test to inspect | `FlakyStore` below counts its calls |
| **mock** | is told in advance what calls to expect, and checks them itself | none: Swift has no standard mocking library, and a spy covers the same ground |

## A store that is offline

The most valuable test of `sync` is the one where the network is down, and that is the one a real
server cannot be asked for on demand:

```swift
// Tests/PlannerCoreTests/OfflineTests.swift
import Testing
@testable import PlannerCore

enum StoreError: Error {
    case offline
}

struct OfflineStore: SessionStore {
    func save(_ sessions: [StudySession]) async throws {
        throw StoreError.offline
    }
}

actor FlakyStore: SessionStore {
    private(set) var attempts = 0
    private(set) var saved: [StudySession] = []

    func save(_ sessions: [StudySession]) async throws {
        attempts += 1
        if attempts == 2 { throw StoreError.offline }
        saved += sessions
    }
}

func weekOfThree() -> Week {
    var week = Week()
    week.add(StudySession(course: "swift", minutes: 45, done: true))
    week.add(StudySession(course: "kotlin", minutes: 60, done: true))
    week.add(StudySession(course: "swift", minutes: 30, done: true))
    return week
}

@Suite struct OfflineTests {
    @Test func anOfflineStoreStopsTheSync() async {
        let syncer = Syncer(store: OfflineStore())
        await #expect(throws: StoreError.offline) {
            try await syncer.sync(weekOfThree())
        }
    }

    @Test func aFailureHalfwayKeepsWhatWasSaved() async {
        let store = FlakyStore()
        await #expect(throws: StoreError.offline) {
            try await Syncer(store: store).sync(weekOfThree())
        }
        #expect(await store.attempts == 2)
        #expect(await store.saved.count == 1)
    }
}
```

**`#expect(throws:)` passes only if the block throws that error**, and fails if it throws another
or returns normally. Its block is async here, so the whole expectation is awaited.

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest --filter OfflineTests 2>&1 | grep -v frontend
Building for debugging...
[Pre-planning 1 / 95]
[Planning deferred tasks]
[7 / 17] PlannerCoreTests-product
[7 / 18] PlannerCoreTests-product
[11 / 17] PlannerCoreTests-product
[14 / 17] PlannerCoreTests-product
[18 / 20] PlannerCoreTests-test-runner
[19 / 21] PlannerCoreTests-test-runner
[21 / 21] PlannerCoreTests-test-runner
Build complete! (3.73 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite OfflineTests started.
◇ Test anOfflineStoreStopsTheSync() started.
◇ Test aFailureHalfwayKeepsWhatWasSaved() started.
✔ Test anOfflineStoreStopsTheSync() passed after 0.049 seconds.
✔ Test aFailureHalfwayKeepsWhatWasSaved() passed after 0.184 seconds.
✔ Suite OfflineTests passed after 0.219 seconds.
✔ Test run with 2 tests in 1 suite passed after 0.219 seconds.
```

## What the spy found

The second test passes, and what it pins down is worth saying in words: when the store fails on
the second session, `sync` stops there, **the first session is already saved, and the third was
never tried**. Nothing in `Syncer` says so in a comment, and before this test nobody had decided
whether that was the behaviour wanted. It is a reasonable one, because saving a session twice would
be worse than saving it late, and lessons 9 and 10 of `mobile-offline` are about retrying such a sync
safely. The test now holds the code to it: if somebody rewrites `sync` to keep going after a
failure, this test is the one that says so.

**A double should be as small as the test needs.** `OfflineStore` has one line of behaviour.
Doubles that grow their own logic, their own bugs and their own tests are a sign that the protocol
asks for too much, which is lesson 10's question about seams coming back from the other side.
