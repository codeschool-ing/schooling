---
title: Um servidor falso, e os testes que ele torna possíveis
version: 1
---

**A seção 05 precisou de um servidor parado e depois iniciado de novo, à mão, em outro terminal.**
Esse é um bom jeito de ver algo uma vez e um jeito ruim de conferi-lo toda vez que o código muda. Um
teste precisa de um servidor que fique offline quando mandado, recuse quando mandado, e consiga perder
uma resposta no caminho de volta, coisa que nenhum servidor de verdade faz quando pedem. Como o
repositório só conhece `PlanSource`, um teste pode entregar um a ele.

## O falso

Salve isto como `Tests/PlannerCoreTests/RepositoryTests.swift`. O falso vem primeiro, e os quatro
testes depois dele seguram as promessas da seção 02 e os dois casos difíceis da seção 07:

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

O `FakeSource` é um `actor`, como o repositório, porque os testes o mudam de fora enquanto o
repositório o chama. O `add` dele guarda uma sessão uma vez só, seja qual for o id, que é o que o
servidor da aula 12 faz, e o `loseNextAnswer` o faz guardar a sessão **e depois lançar** `timedOut`: o
servidor fez o trabalho e a resposta nunca chegou ao telefone.

**Cada teste cria o próprio arquivo** no diretório temporário, com um `UUID` novo no nome, para que o
Swift Testing consiga rodá-los em paralelo sem dois deles lerem o plano um do outro.

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

Oito testes: dois da aula 1, dois da aula 12 e quatro daqui. Nenhum deles iniciou um servidor.
