---
title: Testando código que espera
version: 1
---

A maior parte do trabalho de um planner real espera por algo: um servidor, um disco, outra tarefa.
A aula 14 escreveu essa espera com `async` e `await`, e **o teste de código assíncrono é um teste
assíncrono**: marque a função de teste como `async`, use `await` na chamada, e o framework espera
junto. Sem callbacks, sem dormir "o suficiente" e sem teste que passa porque terminou antes do
trabalho.

## Algo para sincronizar

A biblioteca ganha a peça que envia as sessões concluídas de uma semana para algum lugar. Para onde
elas vão é um protocolo, a costura da aula 10, então a biblioteca não sabe se é um servidor, um
arquivo ou um teste:

```swift
// Sources/PlannerCore/Syncer.swift
public protocol SessionStore: Sendable {
    func save(_ sessions: [StudySession]) async throws
}

public struct Syncer: Sendable {
    let store: any SessionStore

    public init(store: any SessionStore) {
        self.store = store
    }

    public func sync(
        _ week: Week,
        onSaved: (StudySession) -> Void = { _ in }
    ) async throws -> Int {
        let done = week.sessions.filter(\.done)
        for session in done {
            try await store.save([session])
            onSaved(session)
        }
        return done.count
    }
}
```

O `sync` salva as sessões concluídas uma de cada vez, chama `onSaved` depois de cada uma e devolve
quantas salvou. Ele suspende em cada `await`, e um teste precisa segui-lo até lá.

## Dois testes assíncronos

```schooling-example
{"language": "swift", "file": "Tests/PlannerCoreTests/SyncerTests.swift", "parts": [
{"code": "import Testing\n@testable import PlannerCore", "note": "O mesmo framework; nada a mais é importado para código assíncrono."},
{"code": "actor MemoryStore: SessionStore {\n    private(set) var saved: [StudySession] = []\n\n    func save(_ sessions: [StudySession]) async throws {\n        saved += sessions\n    }\n}", "note": "Um store que guarda na memória o que recebe. É um `actor` porque o `sync` o chama de uma tarefa e o teste o lê depois, e a aula 15 explica por que estado mutável compartilhado mora num."},
{"code": "@Suite struct SyncerTests {\n    @Test func savesOnlyDoneSessions() async throws {\n        var week = Week()\n        week.add(StudySession(course: \"swift\", minutes: 45, done: true))\n        week.add(StudySession(course: \"swift\", minutes: 30))\n        week.add(StudySession(course: \"kotlin\", minutes: 60, done: true))\n        let store = MemoryStore()\n        let count = try await Syncer(store: store).sync(week)\n        #expect(count == 2)\n        #expect(await store.saved.map(\\.course) == [\"swift\", \"kotlin\"])\n    }", "note": "`async throws` no teste, `try await` na chamada. Ler o `saved` do ator é atravessar para dentro dele, então a expectativa também precisa de `await`, e o `#expect` o aceita."},
{"code": "    @Test func reportsEachSavedSession() async throws {\n        var week = Week()\n        week.add(StudySession(course: \"swift\", minutes: 45, done: true))\n        week.add(StudySession(course: \"kotlin\", minutes: 60, done: true))\n        let syncer = Syncer(store: MemoryStore())\n        try await confirmation(expectedCount: 2) { saved in\n            _ = try await syncer.sync(week) { _ in saved() }\n        }\n    }\n}", "note": "Uma **confirmação** verifica que algo acontece, e quantas vezes: o teste falha a menos que `saved()` seja chamado exatamente duas vezes antes de o bloco retornar. É como se testa um callback, um evento ou uma notificação, que não têm valor de retorno para o `#expect`."}
]}
```

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest --filter SyncerTests 2>&1 | grep -v frontend
Building for debugging...
[Pre-planning 1 / 95]
[Planning deferred tasks]
[9 / 26] PlannerCore
[17 / 30] PlannerCoreTests-product
[18 / 31] PlannerCoreTests-product
[19 / 31] PlannerCore
[20 / 31] PlannerCoreTests-product
[24 / 30] PlannerCoreTests-product
[28 / 31] PlannerCoreTests-product
[32 / 34] PlannerCoreTests-test-runner
[33 / 35] PlannerCoreTests-test-runner
[35 / 35] PlannerCoreTests-test-runner
Build complete! (2.86 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite SyncerTests started.
◇ Test reportsEachSavedSession() started.
◇ Test savesOnlyDoneSessions() started.
✔ Test reportsEachSavedSession() passed after 0.001 seconds.
✔ Test savesOnlyDoneSessions() passed after 0.001 seconds.
✔ Suite SyncerTests passed after 0.004 seconds.
✔ Test run with 2 tests in 1 suite passed after 0.004 seconds.
```

Os dois passaram, e nenhum esperou um instante a mais do que o trabalho levou: o executor aguardou
cada teste até ele retornar. **Um teste assíncrono nunca precisa de sleep.** Um teste que dorme "até
o trabalho provavelmente terminar" é lento, quando a espera é generosa, ou às vezes errado, quando a
máquina está ocupada, e as duas coisas são piores que nenhum teste.

## Quando a contagem está errada

A `confirmation` é rígida nas duas direções. Se o `sync` esquecesse de chamar `onSaved`, a
confirmação veria zero chamadas onde esperava duas e falharia; se chamasse duas vezes por sessão,
quatro chamadas a reprovariam também. Trocar o `expectedCount` do teste para 3 mostra a mensagem:

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest --filter reportsEachSavedSession 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[2 / 7] PlannerCoreTests-product
[5 / 10] PlannerCoreTests-product
[9 / 12] PlannerCoreTests-product
[13 / 15] PlannerCoreTests-test-runner
[16 / 16] PlannerCoreTests-test-runner
Build complete! (1.93 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite SyncerTests started.
◇ Test reportsEachSavedSession() started.
✘ Test reportsEachSavedSession() recorded an issue at SyncerTests.swift:26:31: Confirmation was confirmed 2 times, but expected to be confirmed 3 times
✘ Test reportsEachSavedSession() failed after 0.001 seconds with 1 issue.
✘ Suite SyncerTests failed after 0.001 seconds with 1 issue.
✘ Test run with 1 test in 1 suite failed after 0.001 seconds with 1 issue.
Note: Some test targets reported failures:
  - PlannerCoreTests (Swift Testing)
```

`Confirmation was confirmed 2 times, but expected to be confirmed 3 times`. O número no teste é uma
afirmação sobre o código, e o framework contou.

## O XCTest também espera

Métodos de teste do XCTest também podem ser `async`, e o `await` funciona neles do mesmo jeito;
código XCTest mais antigo usa `XCTestExpectation` e `wait(for:timeout:)`, que é o formato da era dos
callbacks e carrega um tempo limite porque não tinha como saber quando o trabalho terminava. Você vai
ler os dois em projetos existentes. Testes assíncronos novos ficam mais simples no Swift Testing,
como acima.
