---
title: Um teste, muitos casos
version: 1
---

O teste de progresso da seção 03 confere uma semana: 45 minutos, 15%. As semanas interessantes são as
bordas: nada concluído, a meta atingida exatamente, a meta ultrapassada. O jeito do XCTest é um
método por caso, quatro métodos que diferem em dois números. **O Swift Testing recebe os casos como
argumentos**, e roda a mesma função uma vez para cada:

```swift
// Tests/PlannerCoreTests/ProgressTests.swift
import Testing
@testable import PlannerCore

@Suite struct ProgressTests {
    @Test("Progress for a 300-minute goal", arguments: [
        (0, 0),
        (45, 15),
        (300, 100),
        (450, 100),
    ])
    func progress(minutes: Int, expected: Int) {
        var week = Week()
        week.add(StudySession(course: "swift", minutes: minutes, done: true))
        #expect(week.progress == expected)
    }
}
```

Cada elemento de `arguments` é um **caso de teste**, e uma tupla de dois valores preenche os dois
parâmetros da função em ordem. O `--filter` roda só os testes cujo nome bate com o que vem depois
dele, aqui o da suíte:

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest --filter ProgressTests 2>&1 | grep -v frontend
Building for debugging...
[Pre-planning 1 / 95]
[Planning deferred tasks]
[6 / 16] PlannerCoreTests-product
[13 / 16] PlannerCoreTests-product
[17 / 19] PlannerCoreTests-test-runner
[20 / 20] PlannerCoreTests-test-runner
Build complete! (1.90 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite ProgressTests started.
◇ Test "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 0, expected → 0 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 45, expected → 15 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 300, expected → 100 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 450, expected → 100 to "Progress for a 300-minute goal" started.
✘ Test "Progress for a 300-minute goal" recorded an issue with 2 arguments minutes → 450, expected → 100 at ProgressTests.swift:15:9: Expectation failed: week.progress == expected
↳ week.progress == expected → false
↳   week.progress → 150
↳   expected → 100
✘ Test "Progress for a 300-minute goal" with 4 test cases failed after 0.001 seconds with 1 issue.
✘ Suite ProgressTests failed after 0.001 seconds with 1 issue.
✘ Test run with 1 test in 1 suite failed after 0.001 seconds with 1 issue.
Note: Some test targets reported failures:
  - PlannerCoreTests (Swift Testing)
```

**Três casos passaram e um falhou, e a falha nomeia os argumentos**: `minutes → 450, expected →
100`, e abaixo deles `week.progress → 150`. O teste afirmou que uma estudante que estudou 450
minutos está em 100%, e o código diz 150%. Nenhum dos dois está errado como aritmética, e é isso que
um caso de borda faz: obriga você a decidir. Uma barra de progresso que sai do trilho é o retrato
errado de uma boa semana, então o planner a limita:

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

    public var progress: Int { min(total * 100 / goal, 100) }
}
```

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest --filter ProgressTests 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[2 / 7] PlannerCore
[5 / 11] PlannerCore
[9 / 12] PlannerCoreTests-product
[13 / 15] PlannerCoreTests-test-runner
[14 / 16] PlannerCoreTests-test-runner
[16 / 16] PlannerCoreTests-test-runner
Build complete! (1.54 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite ProgressTests started.
◇ Test "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 0, expected → 0 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 45, expected → 15 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 300, expected → 100 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 450, expected → 100 to "Progress for a 300-minute goal" started.
✔ Test "Progress for a 300-minute goal" with 4 test cases passed after 0.003 seconds.
✔ Suite ProgressTests passed after 0.008 seconds.
✔ Test run with 1 test in 1 suite passed after 0.008 seconds.
```

Quatro casos, uma função, e o resumo os conta: `with 4 test cases passed`.

## Casos como dados, e como se combinam

Os argumentos podem ser qualquer coleção cujos elementos o framework saiba descrever, e os casos
podem rodar sozinhos. Dois detalhes valem saber antes de escrever muitos:

- **Uma coleção, um parâmetro, ou uma tupla por caso**, como acima. A tupla mantém cada entrada ao
  lado da saída esperada, que é como quem lê confere a tabela.
- **Duas coleções formam todas as combinações.** `arguments: [0, 45], [60, 300]` com dois
  parâmetros roda quatro casos, cada valor da primeira com cada valor da segunda. Quando as duas
  listas devem andar juntas em pares, `zip(minutesList, expectedList)` passa os pares em vez disso.

**Um caso que falha continua sendo só um caso**: os outros três rodaram, passaram e foram relatados,
e a falha diz que entradas quebraram. Um único método de XCTest percorrendo a mesma tabela num laço
também rodaria todas as linhas, e a falha dele nomearia a linha da asserção e não a da tabela,
deixando você descobrir qual par de números era o problema.
