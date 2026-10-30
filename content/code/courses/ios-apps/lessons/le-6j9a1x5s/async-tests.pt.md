---
title: Testes assíncronos, e uma fonte que falha de propósito
version: 1
---

**Uma função assíncrona é testada por um teste assíncrono, e o Swift Testing não precisa de mais nada
para rodá-lo.** A função de teste é marcada `async`, faz `await` no código, e o framework espera por
ela. O que torna difícil testar código assíncrono não é a espera: é que a fonte real dos dados, um
servidor ou um disco, é lenta, muda e falha quando quer. Então o código é escrito contra um
**protocolo**, e o teste lhe entrega uma fonte que ele controla.

Este arquivo é novo no pacote, e a aula 14 constrói o repositório de verdade do planner sobre a mesma
ideia. Salve-o como `Sources/PlannerCore/Loading.swift`:

```swift
// Sources/PlannerCore/Loading.swift
/// Anything that can hand over a plan, sooner or later: a file, a server, a test.
public protocol PlanSource: Sendable {
    func load() async throws -> Plan
}

/// The week's total of whatever the source holds.
public func loadWeek(from source: some PlanSource, today: String) async throws -> WeekTotal {
    let plan = try await source.load()
    return plan.weekTotal(today: today)
}
```

`some PlanSource` quer dizer qualquer tipo que obedeça, escolhido por quem chama e fixado na
compilação. O `Sendable` está ali porque uma função assíncrona pode rodar em outra thread, e o Swift 6
se recusa a passar um valor entre threads a não ser que o tipo dele diga que é seguro.

Duas fontes para os testes: uma que devolve um plano fixo e uma que sempre falha. Salve isto como
`Tests/PlannerCoreTests/LoadingTests.swift`:

```swift
// Tests/PlannerCoreTests/LoadingTests.swift
import Testing
@testable import PlannerCore

struct FixedSource: PlanSource {
    let plan: Plan
    func load() async throws -> Plan { plan }
}

struct Offline: Error, Equatable {}

struct FailingSource: PlanSource {
    func load() async throws -> Plan { throw Offline() }
}

@Test func aLoadedWeekIsSummed() async throws {
    let source = FixedSource(plan: Plan(
        courses: [Course(id: "sql", title: "SQL Databases")],
        sessions: [StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true)]
    ))
    let total = try await loadWeek(from: source, today: "2026-10-21")
    #expect(total == WeekTotal(monday: "2026-10-19", planned: 50, done: 50))
}

@Test func aFailedLoadIsPassedOn() async {
    await #expect(throws: Offline()) {
        try await loadWeek(from: FailingSource(), today: "2026-10-21")
    }
}
```

**`await #expect(throws:)` é como se espera uma falha assíncrona.** O `await` vai na frente da macro
porque a closure dentro dela é assíncrona. O segundo teste prova que o erro chega intacto a quem chama,
que é a metade que costuma ficar sem escrever: a tela da aula 12 só mostra um estado de erro se o erro
chegar.

```
ana@vm:~/l20$ swift test --filter Loading 2>&1 | grep -E "^(✔|✘)"
✔ Test aFailedLoadIsPassedOn() passed after 0.001 seconds.
✔ Test aLoadedWeekIsSummed() passed after 0.001 seconds.
✔ Test run with 2 tests in 0 suites passed after 0.001 seconds.
```

Uma fonte falsa que falha é também como um teste alcança o código que um servidor de verdade só
alcançaria num dia ruim, e as outras fontes falsas do planner, na aula 14, seguem o mesmo padrão: um
tipo de poucas linhas, escrito no arquivo de teste, que faz uma coisa toda vez.
