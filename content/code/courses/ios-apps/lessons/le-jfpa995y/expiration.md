---
title: When the time runs out
version: 1
---

**A background task ends when the system says so, and the app's work has to be correct at whatever
point that falls.** Section 03 quoted Apple's documentation: when the time is up, the system cancels
the task the handler is running. The work does not get to finish its loop, write its summary, or tidy
up. Whatever it had not saved is lost, and whatever it had half done is half done.

So the question for the planner's background sync is not how to finish in 30 seconds. **It is how to
be right after any number of seconds**: every session the server confirmed is recorded as sent, every
session it did not is still waiting, and nothing is sent twice. Lesson 14's `sync` saved once, at the
end, which is the wrong shape for this.

## Sync, one session at a time

Save this as `Sources/PlannerCore/BackgroundSync.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/BackgroundSync.swift", "parts": [{"code": "// Sources/PlannerCore/BackgroundSync.swift\nextension PlannerRepository {\n    /// Send pending sessions one at a time for as long as the task is allowed\n    /// to run. Each success is saved at once, so a task the system cancels\n    /// halfway keeps everything it had already sent.\n", "note": "An extension of lesson 14's repository, in a file of its own: it reaches the same `snapshot`, `source` and `save`, because an extension in the same module sees internal members."}, {"code": "    public func syncUntilCancelled() async -> (sent: Int, left: Int) {\n        var sent = 0\n        for p in snapshot.pending {\n", "note": "The loop sends one pending session at a time and returns what it managed. It asks `Task.isCancelled` before each one, so a cancelled task starts nothing new."}, {"code": "            if Task.isCancelled { break }\n            do throws(APIError) {\n                let s = try await source.add(p.session)\n                snapshot.pending.removeAll { $0.id == s.id }\n                if !snapshot.sessions.contains(where: { $0.id == s.id }) {\n                    snapshot.sessions.append(WireSession(s))\n                }\n                sent += 1\n                save()\n", "note": "**Each success is saved at once**, not at the end. That is the whole point: when the system's time runs out between two sessions, the first is already on the device as sent, and nothing will send it twice."}, {"code": "            } catch {\n                if case .status(let code, _) = error, (400..<500).contains(code) {\n                    snapshot.pending.removeAll { $0.id == p.id }\n                    save()\n                    continue\n                }\n                break                          // offline or cancelled: stop, keep the rest\n            }\n        }\n        return (sent, snapshot.pending.count)\n    }\n}\n", "note": "A refusal is dropped as lesson 14's `sync` drops it, and the loop goes on. Anything else, including the cancellation that arrives as `APIError.cancelled` in the middle of a request, stops the loop and leaves the rest pending."}]}
```

## Expiration, on Linux

The system's cancellation is ordinary Swift cancellation, so it can be practised without the system:
start the work in a `Task`, wait for as long as the budget allows, and cancel. Replace
`Sources/background/main.swift` with this version, which keeps section 06's work as the `next`
command and adds `run`. Its `SlowSource` wraps the real client and makes every post take 400
milliseconds, a slow mobile network, so that a short budget cuts the work off in the middle:

```swift
// Sources/background/main.swift
import Foundation
import PlannerCore

/// The planner's server, reached over a slow connection: every post takes 400 ms.
struct SlowSource: PlanSource {
    let api: APIClient

    func courses() async throws(APIError) -> [Course] { try await api.courses() }
    func sessions(course id: String) async throws(APIError) -> [StudySession] { try await api.sessions(course: id) }
    func add(_ s: StudySession) async throws(APIError) -> StudySession {
        do { try await Task.sleep(for: .milliseconds(400)) } catch { throw .cancelled }
        return try await api.add(s)
    }
}

let args = Array(CommandLine.arguments.dropFirst())
let api = APIClient(base: URL(string: "http://127.0.0.1:8012")!)
let repo = try PlannerRepository(source: SlowSource(api: api), store: FileStore(url: URL(fileURLWithPath: "planner.json")))

switch args.first {
case "run":
    // The system's budget for this run, in seconds; when it is up, the task is cancelled.
    let budget = Double(args[1])!
    let work = Task { await repo.syncUntilCancelled() }
    try await Task.sleep(for: .seconds(budget))
    work.cancel()
    let (sent, left) = await work.value
    print("given \(budget) s: sent \(sent), \(left) still waiting")
case "next":
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: args[1])!
    let format = ISO8601DateFormatter()
    format.timeZone = calendar.timeZone
    let now = format.date(from: args[2])!
    for pending in [0, 3] {
        let next = nextRefresh(after: now, pending: pending, calendar: calendar)
        print("\(pending) waiting: next refresh \(format.string(from: next)), in \(Int(next.timeIntervalSince(now) / 60)) min")
    }
default:
    print(await repo.pendingCount, "waiting to be sent")
}
```

To have something to send, the device needs sessions that were added offline. With the server from
lesson 12 running, refresh once so the device knows the courses, then stop the server and add six
sessions with lesson 14's `repo`:

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (2.46 secs)
ana@vm:~/planner$ .build/debug/repo refresh | head -1
refreshed from the server
ana@vm:~/planner$ for n in 1 2 3 4 5 6; do .build/debug/repo add b$n mobile 2026-10-22 20 | head -1; done
added b1 on the device
added b2 on the device
added b3 on the device
added b4 on the device
added b5 on the device
added b6 on the device
ana@vm:~/planner$ .build/debug/background
6 waiting to be sent
```

Start the server again, and give the background work one second at a time:

```
ana@vm:~/planner$ .build/debug/background run 1.0
given 1.0 s: sent 2, 4 still waiting
ana@vm:~/planner$ .build/debug/background run 1.0
given 1.0 s: sent 2, 2 still waiting
ana@vm:~/planner$ .build/debug/background run 1.0
given 1.0 s: sent 2, 0 still waiting
```

**Three runs of one second sent two sessions each, and nothing was lost or doubled between them.** Each
run sent two in its 800 milliseconds of posting and was cancelled during the third post's wait; that
session stayed pending and went first in the next run. The server's terminal logged six posts, one per
session. On a phone this is the same work spread over three app refreshes, perhaps hours apart, each
cut off by the system wherever its time ended.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l16-runs\" aria-label=\"Three background runs drawn as rows on a time line, each one second long. In each, two posts of 400 milliseconds complete, each followed by a save, and a third post starts and is cut off when the second ends and the task is cancelled. Beside each row, the sessions waiting: six before the first run, four after it, two after the second, none after the third. Between the rows, the note that on a phone the runs may be hours apart.\"><defs><marker id=\"l16-runs-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l16-runs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16-runs-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l16-runs-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 s</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0 s</text><text x=\"670\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waiting</text><text x=\"60\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">run 1</text><rect x=\"120.0\" y=\"48\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"213.0\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">post b1, saved</text><rect x=\"312.0\" y=\"48\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"405.0\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">post b2, saved</text><rect x=\"504.0\" y=\"48\" width=\"96.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"552.0\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">b3</text><path d=\"M600 42 L600 86\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"670\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6 → 4</text><text x=\"360.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on a phone, perhaps hours later</text><text x=\"60\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">run 2</text><rect x=\"120.0\" y=\"130\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"213.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">post b3, saved</text><rect x=\"312.0\" y=\"130\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"405.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">post b4, saved</text><rect x=\"504.0\" y=\"130\" width=\"96.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"552.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">b5</text><path d=\"M600 124 L600 168\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"670\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4 → 2</text><text x=\"360.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on a phone, perhaps hours later</text><text x=\"60\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">run 3</text><rect x=\"120.0\" y=\"212\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"213.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">post b5, saved</text><rect x=\"312.0\" y=\"212\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"405.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">post b6, saved</text><path d=\"M600 206 L600 250\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"670\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2 → 0</text><text x=\"600\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cancelled</text></svg>", "caption": "Every success is saved the moment it happens, so wherever the cancellation falls, the cut post stays waiting and goes first next time."}
```

## Noticing, when there is something to tidy

The planner's work needs no tidying: the pending list is always right. Work that holds a resource, a
file half written or a transaction open, can be told the moment cancellation arrives, which is what
the documentation's suggestion of `withTaskCancellationHandler` is for. The handler runs at once, on
whatever thread cancelled the task, so it should only signal, never do the cleaning itself.
