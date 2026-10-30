---
title: A fake server, and the tests it makes possible
version: 1
---

**Section 05 needed a server that was stopped and then started again, by hand, in another terminal.**
That is a fine way to see something once and a poor way to check it every time the code changes. A
test needs a server that goes offline on command, refuses on command, and can lose an answer on its
way back, which no real server does when asked. Because the repository only knows `PlanSource`, a
test can hand it one.

## The fake

Save this as `Tests/PlannerCoreTests/RepositoryTests.swift`. The fake comes first, and the four
tests after it hold section 02's promises and section 07's two hard cases:

```swift
// Tests/PlannerCoreTests/RepositoryTests.swift
import Foundation
import Testing
@testable import PlannerCore

/// A server that lives in the test: it can go offline, refuse, or lose an answer.
actor FakeSource: PlanSource {
    var online = true
    var known = [Course(id: "sql", title: "SQL Databases")]
    var received: [StudySession] = []
    var loseNextAnswer = false

    func set(online: Bool) { self.online = online }
    func loseTheNextAnswer() { loseNextAnswer = true }

    func courses() async throws(APIError) -> [Course] {
        guard online else { throw .offline("notConnectedToInternet") }
        return known
    }

    func sessions(course id: String) async throws(APIError) -> [StudySession] {
        guard online else { throw .offline("notConnectedToInternet") }
        return received.filter { $0.courseID == id }
    }

    func add(_ s: StudySession) async throws(APIError) -> StudySession {
        guard online else { throw .offline("notConnectedToInternet") }
        guard known.contains(where: { $0.id == s.courseID }) else { throw .status(422, "no course \(s.courseID)") }
        if !received.contains(where: { $0.id == s.id }) { received.append(s) }
        if loseNextAnswer {               // the server kept it; the answer never arrived
            loseNextAnswer = false
            throw .offline("timedOut")
        }
        return s
    }
}

func freshStore() -> FileStore {
    FileStore(url: FileManager.default.temporaryDirectory.appending(path: "planner-\(UUID().uuidString).json"))
}

let s5 = StudySession(id: "s5", courseID: "sql", date: "2026-10-22", minutes: 30)

@Test func offlineTheDeviceStillHasItsPlan() async throws {
    let fake = FakeSource()
    let store = freshStore()
    try await PlannerRepository(source: fake, store: store).refresh()  // one good refresh, saved
    await fake.set(online: false)
    let repo = try PlannerRepository(source: fake, store: store)       // the app opens again, offline
    await #expect(throws: APIError.offline("notConnectedToInternet")) { try await repo.refresh() }
    #expect(await repo.plan.courses.map(\.id) == ["sql"])
}

@Test func aSessionAddedOfflineIsSentLater() async throws {
    let fake = FakeSource()
    let repo = try PlannerRepository(source: fake, store: freshStore())
    try await repo.refresh()
    await fake.set(online: false)
    try await repo.add(s5)
    #expect(await repo.pendingCount == 1)
    #expect(await repo.plan.sessions.map(\.id) == ["s5"])
    await fake.set(online: true)
    #expect(await repo.sync() == [])
    #expect(await repo.pendingCount == 0)
    #expect(await fake.received.map(\.id) == ["s5"])
}

@Test func aSessionTheServerRefusesIsDroppedAndReported() async throws {
    let store = freshStore()
    var known = Snapshot()
    known.courses = [WireCourse(id: "sql", title: "SQL Databases"), WireCourse(id: "art", title: "Art History")]
    try store.save(known)                   // the device knows a course the server has deleted
    let repo = try PlannerRepository(source: FakeSource(), store: store)
    let art = StudySession(id: "s6", courseID: "art", date: "2026-10-22", minutes: 30)
    #expect(try await repo.add(art) == ["s6"])
    #expect(await repo.pendingCount == 0)
    #expect(await repo.plan.sessions.isEmpty)
}

@Test func anAnswerLostOnTheWayIsSentAgainAndKeptOnce() async throws {
    let fake = FakeSource()
    let repo = try PlannerRepository(source: fake, store: freshStore())
    try await repo.refresh()
    await fake.loseTheNextAnswer()
    try await repo.add(s5)
    #expect(await repo.pendingCount == 1)   // the device cannot know the server kept it
    await repo.sync()
    #expect(await repo.pendingCount == 0)
    #expect(await fake.received.count == 1)
    #expect(await repo.plan.sessions.filter { $0.id == "s5" }.count == 1)
}
```

`FakeSource` is an `actor`, like the repository, because the tests change it from outside while the
repository calls it. Its `add` keeps a session once, whatever its id, which is what lesson 12's
server does, and `loseNextAnswer` makes it keep the session **and then throw** `timedOut`: the server
did the work and the answer never reached the phone.

**Each test makes its own file** in the temporary directory, named with a fresh `UUID`, so that
Swift Testing can run them in parallel without two of them reading each other's plan.

```
ana@vm:~/planner$ swift test 2>&1 | grep -E "✔|✘"
✔ Test aSessionAddedOfflineIsSentLater() passed after 0.002 seconds.
✔ Test anAnswerLostOnTheWayIsSentAgainAndKeptOnce() passed after 0.002 seconds.
✔ Test aSessionEncodesWithTheServersSpelling() passed after 0.002 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.002 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.002 seconds.
✔ Test aSessionFromTheServerBecomesAModelSession() passed after 0.002 seconds.
✔ Test offlineTheDeviceStillHasItsPlan() passed after 0.003 seconds.
✔ Test aSessionTheServerRefusesIsDroppedAndReported() passed after 0.002 seconds.
✔ Test run with 8 tests in 0 suites passed after 0.003 seconds.
```

Eight tests: two from lesson 1, two from lesson 12 and four here. None of them started a server.
