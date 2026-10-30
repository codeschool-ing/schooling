---
title: Testando trabalho que roda quando ninguém está olhando
version: 1
---

**O trabalho em segundo plano é o código de um app mais difícil de ver rodando, e o mais fácil de
entregar quebrado.** O sistema escolhe quando ele roda, talvez horas depois de agendado, num telefone
no bolso de alguém. Um handler de atualização que lança na segunda linha pode falhar toda noite durante
um mês sem aparecer em tela nenhuma. Então ele é testado em duas metades: as decisões no pacote, com
testes que rodam num segundo; e a ligação com o sistema, à mão, num aparelho.

## As decisões, em qualquer computador

Tudo o que as seções 06 e 07 decidiram é função das suas entradas: o momento, o fuso, as sessões
pendentes, se a tarefa foi cancelada. Salve isto como `Tests/PlannerCoreTests/BackgroundTests.swift`;
ele usa o `FakeSource` e o `freshStore` dos testes da aula 14, que estão no mesmo target de testes:

```swift
// Tests/PlannerCoreTests/BackgroundTests.swift
import Foundation
import Testing
@testable import PlannerCore

func moment(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

func calendar(_ zone: String) -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: zone)!
    return c
}

@Test func withNothingWaitingTheNextRefreshIsSixInTheMorning() {
    let next = nextRefresh(after: moment("2026-10-21T22:30:00-03:00"), pending: 0, calendar: calendar("America/Sao_Paulo"))
    #expect(next == moment("2026-10-22T06:00:00-03:00"))
}

@Test func theNightTheClocksGoBackIsAnHourLonger() {
    let now = moment("2026-10-24T22:30:00+01:00")
    let next = nextRefresh(after: now, pending: 0, calendar: calendar("Europe/Lisbon"))
    #expect(next == moment("2026-10-25T06:00:00Z"))
    #expect(next.timeIntervalSince(now) == 8.5 * 3600)
}

@Test func sessionsWaitingAskAgainInFifteenMinutes() {
    let now = moment("2026-10-21T22:30:00-03:00")
    #expect(nextRefresh(after: now, pending: 3, calendar: calendar("America/Sao_Paulo")) == now.addingTimeInterval(900))
}

@Test func aCancelledSyncSendsNothingAndKeepsEverything() async throws {
    let fake = FakeSource()
    let repo = try PlannerRepository(source: fake, store: freshStore())
    try await repo.refresh()
    await fake.set(online: false)
    for n in 1...3 {
        try await repo.add(StudySession(id: "b\(n)", courseID: "sql", date: "2026-10-22", minutes: 20))
    }
    await fake.set(online: true)
    let cut = await Task {
        withUnsafeCurrentTask { $0?.cancel() }      // the system's time is already up
        return await repo.syncUntilCancelled()
    }.value
    #expect(cut.sent == 0 && cut.left == 3)
    let whole = await repo.syncUntilCancelled()
    #expect(whole.sent == 3 && whole.left == 0)
}
```

O teste de Lisboa fixa a hora em que os relógios voltaram. **O teste da sincronização cancelada é a
expiração sem nada deixado ao acaso**: o `withUnsafeCurrentTask` cancela a tarefa em que a closure está
rodando antes de a sincronização começar, que é o caso de uma tarefa cujo tempo já tinha acabado, e a
segunda chamada confere que as três sessões que ela não enviou continuam todas lá para enviar.

```
ana@vm:~/planner$ swift test 2>&1 | grep -E "✔|✘"
✔ Test aSessionFromTheServerBecomesAModelSession() passed after 0.003 seconds.
✔ Test anAnswerLostOnTheWayIsSentAgainAndKeptOnce() passed after 0.003 seconds.
✔ Test offlineTheDeviceStillHasItsPlan() passed after 0.003 seconds.
✔ Test aSessionAddedOfflineIsSentLater() passed after 0.003 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.003 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.003 seconds.
✔ Test aSessionEncodesWithTheServersSpelling() passed after 0.003 seconds.
✔ Test aSessionTheServerRefusesIsDroppedAndReported() passed after 0.003 seconds.
✔ Test aCancelledSyncSendsNothingAndKeepsEverything() passed after 0.003 seconds.
✔ Test theNightTheClocksGoBackIsAnHourLonger() passed after 0.005 seconds.
✔ Test sessionsWaitingAskAgainInFifteenMinutes() passed after 0.005 seconds.
✔ Test withNothingWaitingTheNextRefreshIsSixInTheMorning() passed after 0.006 seconds.
✔ Test run with 12 tests in 0 suites passed after 0.006 seconds.
```

Doze testes agora: os dois da aula 1, os dois da aula 12, os quatro da aula 14 e estes quatro.

## A ligação, num aparelho

Se o sistema chama de fato o handler só dá para ver num telefone. O guia da Apple *Starting and
Terminating Tasks During Development* dá dois comandos de depurador para isso, e diz que eles
**funcionam só em aparelhos**, não no simulador; eles não foram executados para este curso. Pause o app
no depurador do Xcode depois de o pedido ter sido enviado, e digite no prompt `(lldb)`, com o
identificador do planner:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.example.planner.refresh"]
```

Continue, e o sistema abre a tarefa como faria horas depois. Para experimentar a outra ponta, pause
dentro da tarefa rodando e digite o comando de expiração:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.example.planner.refresh"]
```

O mesmo guia avisa que essas são funções privadas, só para desenvolvimento: **um app que as cita no
código que envia é rejeitado**, e é por isso que elas são digitadas no depurador e nunca escritas num
arquivo. O que procurar: o handler roda, o número de pendentes cai em quantas ele conseguiu enviar, a
próxima atualização é agendada, e depois de uma expiração o arquivo do aparelho continua dizendo
exatamente o que foi enviado.
