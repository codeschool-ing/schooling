---
title: Swift Testing, com uma macro para toda verificação
version: 1
---

O XCTest dá a cada tipo de verificação uma função própria, e cada função precisa ser informada do que
está comparando. **O Swift Testing tem uma verificação, `#expect`, e ela recebe uma expressão Swift
comum**: `#expect(week.total == 45)`. Quando a expressão é falsa, o framework imprime a expressão e o
valor de cada parte dela, então uma falha se explica sem mensagem de asserção. Ele chegou com o Swift
6 em 2024, vem no mesmo toolchain e roda no mesmo `swift test`.

O planner ganha uma porcentagem, para a barra que uma tela vai desenhar:

```swift
// Sources/PlannerCore/Week.swift
public struct StudySession: Equatable, Sendable {
    public let course: String
    public let minutes: Int
    public var done: Bool

    public init(course: String, minutes: Int, done: Bool = false) {
        self.course = course
        self.minutes = minutes
        self.done = done
    }
}

public struct Week: Sendable {
    public private(set) var sessions: [StudySession] = []
    public let goal: Int

    public init(goal: Int = 300) { self.goal = goal }

    public mutating func add(_ session: StudySession) {
        sessions.append(session)
    }

    public var total: Int {
        sessions.filter(\.done).map(\.minutes).reduce(0, +)
    }

    public var remaining: Int { max(goal - total, 0) }

    public var progress: Int { total / goal * 100 }
}
```

e os testes são escritos no framework novo, num arquivo próprio no mesmo target de testes:

```schooling-example
{"language": "swift", "file": "Tests/PlannerCoreTests/WeekTests.swift", "parts": [
{"code": "import Testing\n@testable import PlannerCore", "note": "O módulo é `Testing`. Os dois frameworks podem morar num mesmo target de testes, e o `swift test` roda os dois."},
{"code": "@Suite(\"A week of study\")\nstruct WeekTests {", "note": "Uma suíte é qualquer tipo que guarda testes, aqui uma struct. O `@Suite` é opcional e lhe dá um nome para a saída. Cada teste recebe uma instância nova, então nenhum teste vê sobras de outro."},
{"code": "    @Test(\"Only finished sessions count\")\n    func total() {\n        var week = Week()\n        week.add(StudySession(course: \"swift\", minutes: 45, done: true))\n        week.add(StudySession(course: \"swift\", minutes: 30))\n        #expect(week.total == 45)\n    }", "note": "Um teste é qualquer função marcada `@Test`; o nome não precisa mais começar com `test`, e a string é como a saída o chama."},
{"code": "    @Test(\"Progress is a percentage of the goal\")\n    func progress() {\n        var week = Week()\n        week.add(StudySession(course: \"swift\", minutes: 45, done: true))\n        #expect(week.progress == 15)\n    }", "note": "45 minutos de uma meta de 300 são 15%."},
{"code": "    @Test func firstSessionIsTheOneAdded() throws {\n        var week = Week()\n        week.add(StudySession(course: \"kotlin\", minutes: 20))\n        let first = try #require(week.sessions.first)\n        #expect(first.course == \"kotlin\")\n    }\n}", "note": "O `#require` é um `#expect` que para o teste quando falha. Diante de um opcional ele devolve o valor desembrulhado, então a linha seguinte trabalha com uma `StudySession` simples; diante de `nil` ele registra a falha e lança um erro, e é por isso que o teste está marcado `throws`."}
]}
```

O `swift test --disable-xctest` roda só os testes deste framework:

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest 2>&1 | grep -v frontend
Building for debugging...
[Provisioning 4 / 4]
[Planning 1 / 95]
[Planning deferred tasks]
[6 / 20] PlannerCore
[14 / 26] PlannerCore
[16 / 26] PlannerCoreTests-product
[19 / 25] PlannerCoreTests-product
[23 / 26] PlannerCoreTests-product
[27 / 29] PlannerCoreTests-test-runner
[28 / 30] PlannerCoreTests-test-runner
[31 / 31] PlannerCoreTests-test-runner
Build complete! (2.18 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite "A week of study" started.
◇ Test "Only finished sessions count" started.
◇ Test firstSessionIsTheOneAdded() started.
◇ Test "Progress is a percentage of the goal" started.
✔ Test "Only finished sessions count" passed after 0.001 seconds.
✔ Test firstSessionIsTheOneAdded() passed after 0.001 seconds.
✘ Test "Progress is a percentage of the goal" recorded an issue at WeekTests.swift:16:9: Expectation failed: week.progress == 15
↳ week.progress == 15 → false
↳   week.progress → 0
✘ Test "Progress is a percentage of the goal" failed after 0.001 seconds with 1 issue.
✘ Suite "A week of study" failed after 0.001 seconds with 1 issue.
✘ Test run with 3 tests in 1 suite failed after 0.001 seconds with 1 issue.
Note: Some test targets reported failures:
  - PlannerCoreTests (Swift Testing)
```

**A falha imprime a expressão e depois o valor de cada parte dela**: `week.progress == 15` foi falso
porque `week.progress` era `0`. Nada no teste pediu essa segunda linha; o `#expect` é uma **macro**,
que a aula 16 descreveu de fora, e na compilação ela reescreveu a comparação em código que registra
os dois lados. A causa é a divisão inteira da aula 1: `45 / 300` é 0, e 0 vezes 100 continua 0.

Os símbolos no começo de cada linha são do framework: `◇` um teste ou suíte que começou, `✔` um que
passou, `✘` um que falhou, e `↳` um detalhe da linha de cima. Os testes rodaram **em paralelo**, que
é o padrão do Swift Testing, então as linhas se intercalam e a ordem muda de uma execução para
outra. Um teste que depende de rodar depois de outro é um teste com um defeito, e rodar em paralelo
encontra esses.

Multiplique antes de dividir:

```swift
// Sources/PlannerCore/Week.swift
public struct StudySession: Equatable, Sendable {
    public let course: String
    public let minutes: Int
    public var done: Bool

    public init(course: String, minutes: Int, done: Bool = false) {
        self.course = course
        self.minutes = minutes
        self.done = done
    }
}

public struct Week: Sendable {
    public private(set) var sessions: [StudySession] = []
    public let goal: Int

    public init(goal: Int = 300) { self.goal = goal }

    public mutating func add(_ session: StudySession) {
        sessions.append(session)
    }

    public var total: Int {
        sessions.filter(\.done).map(\.minutes).reduce(0, +)
    }

    public var remaining: Int { max(goal - total, 0) }

    public var progress: Int { total * 100 / goal }
}
```

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[2 / 7] PlannerCore
[5 / 11] PlannerCore
[9 / 12] PlannerCoreTests-product
[13 / 15] PlannerCoreTests-test-runner
[16 / 16] PlannerCoreTests-test-runner
Build complete! (1.66 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite "A week of study" started.
◇ Test "Only finished sessions count" started.
◇ Test "Progress is a percentage of the goal" started.
◇ Test firstSessionIsTheOneAdded() started.
✔ Test "Only finished sessions count" passed after 0.001 seconds.
✔ Test "Progress is a percentage of the goal" passed after 0.001 seconds.
✔ Test firstSessionIsTheOneAdded() passed after 0.001 seconds.
✔ Suite "A week of study" passed after 0.001 seconds.
✔ Test run with 3 tests in 1 suite passed after 0.001 seconds.
```

## As diferenças que importam

| | XCTest | Swift Testing |
|---|---|---|
| um teste é | um método chamado `test…` numa subclasse de `XCTestCase` | qualquer função marcada `@Test` |
| uma verificação é | uma de uma família de funções `XCTAssert…` | `#expect(expressão)`, ou `#require` para parar |
| uma falha mostra | os dois valores que você passou | a expressão e cada valor dentro dela |
| roda | um depois do outro, a menos que se peça | em paralelo, a menos que se peça |
| argumentos | nenhum; um método por caso | `@Test(arguments:)`, seção 04 |

**Os testes novos deste curso são escritos com Swift Testing**, e o XCTest continua valendo a
leitura: a maioria dos projetos iOS escritos antes de 2024 o usa do começo ao fim, e os testes que
conduzem as telas de um app, que o `ios-apps` encontra, são escritos com as classes de teste de
interface do XCTest.
