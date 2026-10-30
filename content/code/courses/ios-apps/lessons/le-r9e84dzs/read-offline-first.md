---
title: Reading offline first
version: 1
---

**The repository answers from the device and asks the server when it can.** That order is the whole
of offline-first reading, and it is simpler than it sounds: there is a value the device already has,
which the screens read, and a refresh that replaces it when the server answers. A refresh that fails
changes nothing, so the plan on screen is the last one that was true.

## The repository

Save this as `Sources/PlannerCore/PlannerRepository.swift`. This section is about its first half,
the read; section 05 is about the write:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/PlannerRepository.swift", "parts": [{"code": "// Sources/PlannerCore/PlannerRepository.swift\nimport Foundation\n\npublic actor PlannerRepository {\n    let source: any PlanSource\n    let store: any PlanStore\n    var snapshot: Snapshot\n    /// The last time the device could not write its file, said rather than swallowed.\n    public private(set) var storeError: String?\n\n    public init(source: any PlanSource, store: any PlanStore) throws {\n        self.source = source\n        self.store = store\n        self.snapshot = try store.load()\n    }\n\n", "note": "An `actor`, because two screens may ask it things at the same moment, and an actor runs one of its methods at a time between each `await`. It holds the two halves, a source and a store, by their protocols, and loads what the device kept the moment it is made. A write that fails is recorded in `storeError` rather than dropped."}, {"code": "    /// The plan as the device knows it now: what the server last said,\n    /// plus what was added here and not yet confirmed. Never waits.\n    public var plan: Plan {\n        let confirmed = snapshot.sessions.map(\\.session)\n        let waiting = snapshot.pending.map(\\.session).filter { p in !confirmed.contains { $0.id == p.id } }\n        return Plan(courses: snapshot.courses.map(\\.course), sessions: confirmed + waiting)\n    }\n\n    public var pendingCount: Int { snapshot.pending.count }\n\n", "note": "The read never waits for the network. It is what the server last said, plus every session added here that the server has not confirmed, so a session added offline shows at once."}, {"code": "    /// Ask the server for everything. On failure the plan on the device is untouched.\n    public func refresh() async throws(APIError) {\n        let courses = try await source.courses()\n        var sessions: [StudySession] = []\n        for c in courses { sessions += try await source.sessions(course: c.id) }\n        snapshot.courses = courses.map { WireCourse(id: $0.id, title: $0.title) }\n        snapshot.sessions = sessions.map(WireSession.init)\n        save()\n    }\n\n", "note": "The refresh replaces the server's half and leaves `pending` alone. If any request fails, the `throw` leaves before the snapshot is touched, so a refresh that fails halfway changes nothing on the device."}, {"code": "    /// Add a session on the device first, then try to tell the server.\n    /// Returns the ids the server refused for good, as `sync` does.\n    @discardableResult\n    public func add(_ s: StudySession) async throws(PlanError) -> [String] {\n        var check = plan\n        try check.add(s)                       // refuses a course the device does not know\n        snapshot.pending.append(WireSession(s))\n        save()\n        return await sync()\n    }\n\n", "note": "A write goes to the device first and to the server second. The check against the plan refuses a course the device does not know, as lesson 1's `Plan.add` does, before anything is kept."}, {"code": "    /// Send every pending session. Returns the ids the server refused for good.\n    @discardableResult\n    public func sync() async -> [String] {\n        var refused: [String] = []\n        for p in snapshot.pending {\n            do throws(APIError) {\n                let sent = try await source.add(p.session)\n                snapshot.pending.removeAll { $0.id == sent.id }\n                if !snapshot.sessions.contains(where: { $0.id == sent.id }) {\n                    snapshot.sessions.append(WireSession(sent))\n                }\n            } catch {\n                switch error {\n                case .status(let code, _) where (400..<500).contains(code):\n                    snapshot.pending.removeAll { $0.id == p.id }\n                    refused.append(p.id)\n                default:\n                    break                      // offline or cancelled: try again later\n                }\n            }\n        }\n        save()\n        return refused\n    }\n\n", "note": "`sync` walks the pending sessions and sends each. A success moves it across; a `4xx` is a refusal that will never change, so it is dropped and reported; anything else, offline above all, leaves it pending for the next try."}, {"code": "    func save() {\n        do {\n            try store.save(snapshot)\n            storeError = nil\n        } catch {\n            storeError = \"\\(error)\"\n        }\n    }\n}\n", "note": "One place writes the file, and it says when it could not."}]}
```

**`plan` is a property, not a request.** A screen reads it and gets an answer in the time it takes to
build a `Plan` from two arrays, whatever the network is doing. The only thing that waits is
`refresh`, and a screen starts that in the background and redraws when it finishes.

## Driving it from the terminal

`repo` is a program that does one thing to the repository and then prints what the device would
show. Save this as `Sources/repo/main.swift`:

```swift
// Sources/repo/main.swift
import Foundation
import PlannerCore

let args = Array(CommandLine.arguments.dropFirst())
let api = APIClient(base: URL(string: "http://127.0.0.1:8012")!)
let repo = try PlannerRepository(source: api, store: FileStore(url: URL(fileURLWithPath: "planner.json")))

switch args.first {
case "refresh":
    do throws(APIError) {
        try await repo.refresh()
        print("refreshed from the server")
    } catch {
        print("could not refresh:", error.message)
    }
case "add":
    let s = StudySession(id: args[1], courseID: args[2], date: args[3], minutes: Int(args[4])!)
    do throws(PlanError) {
        let refused = try await repo.add(s)
        print("added \(s.id) on the device" + (refused.isEmpty ? "" : ", and the server refused \(refused)"))
    } catch {
        print("not added:", error)
    }
case "sync":
    let refused = await repo.sync()
    print("synced" + (refused.isEmpty ? "" : ", and the server refused \(refused)"))
default:
    break
}
let plan = await repo.plan
print("\(plan.courses.count) courses, \(plan.sessions.count) sessions, \(await repo.pendingCount) waiting to be sent")
print(plan.weekTotal(today: "2026-10-21"))
if let problem = await repo.storeError { print("could not save:", problem) }
```

It keeps its file as `planner.json` in the directory you run it from, and judges the week from
Wednesday 21 October, as lesson 1's `week` did. Build it, and run a refresh **with the server
stopped**, the way a phone with no signal would open the app for the first time:

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (6.58 secs)
ana@vm:~/planner$ .build/debug/repo refresh
could not refresh: You are offline, or the planner's server is not answering.
0 courses, 0 sessions, 0 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 0, done: 0)
```

Nothing on the device yet, and an honest sentence about why. Now start the server in its own
terminal, as in lesson 12, and refresh again:

```
ana@vm:~/planner$ .build/debug/repo refresh
refreshed from the server
2 courses, 4 sessions, 0 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 150, done: 90)
```

Two courses and four sessions, saved to `planner.json` on the way in. **Then stop the server**, with
`Ctrl-C` in its terminal, and run `repo` with no command, which only reads:

```
ana@vm:~/planner$ .build/debug/repo
2 courses, 4 sessions, 0 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 150, done: 90)
```

The same plan, with no server anywhere. That last run is the train: the app opened, read what it
had, and showed it. The week's numbers are the server's four sessions, 150 minutes planned and 90
done, since the session `s5` from lesson 1 was never on the server.
