---
title: XCTest, o framework que veio primeiro
version: 1
---

Um teste é um pequeno programa que usa o seu código como um chamador usaria e **afirma o que deve
sair**. Quando a afirmação é falsa, o teste falha, aponta a linha e diz o que recebeu no lugar. Rode
os testes depois de cada mudança e um erro aparece minutos depois de você cometê-lo, numa função de
que você se lembra de ter escrito, e não semanas depois na tela de uma estudante.

O Swift tem dois frameworks de teste, e os dois vêm dentro do toolchain que a aula 1 instalou. O
**XCTest** é o mais antigo, dos tempos do Objective-C, e ainda está em todo projeto iOS que você vai
abrir. O **Swift Testing** chegou em 2024 e é o assunto da seção 03. Esta aula escreve os mesmos
testes nos dois, para você conseguir ler qualquer um quando o encontrar.

## Um pacote com um target de testes

Os testes moram num pacote, ao lado do código que testam. Este tem a biblioteca do planner e um
target de testes que depende dela:

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "planner",
    targets: [
        .target(name: "PlannerCore"),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

A biblioteca guarda uma sessão de estudo e uma semana delas. Uma semana conta só as sessões
concluídas, e diz quantos minutos faltam para a meta:

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

    public var remaining: Int { goal - total }
}
```

## Dois testes de XCTest

```schooling-example
{"language": "swift", "file": "Tests/PlannerCoreTests/WeekXCTests.swift", "parts": [
{"code": "import XCTest\n@testable import PlannerCore", "note": "O `@testable` deixa os testes enxergarem os nomes `internal` do módulo além dos públicos. Os níveis de acesso da aula 17 continuam valendo para todo outro importador."},
{"code": "final class WeekXCTests: XCTestCase {", "note": "Uma suíte de XCTest é uma classe que herda de `XCTestCase`. O executor a encontra procurando subclasses."},
{"code": "    func testTotalCountsOnlyDoneSessions() {\n        var week = Week()\n        week.add(StudySession(course: \"swift\", minutes: 45, done: true))\n        week.add(StudySession(course: \"swift\", minutes: 30))\n        XCTAssertEqual(week.total, 45)\n    }", "note": "Um teste é um método cujo nome começa com `test`, que não recebe nada e não devolve nada. Monte uma semana, aja sobre ela e afirme: o `XCTAssertEqual` compara dois valores e reprova o teste se forem diferentes."},
{"code": "    func testRemainingNeverGoesBelowZero() {\n        var week = Week(goal: 60)\n        week.add(StudySession(course: \"swift\", minutes: 90, done: true))\n        XCTAssertEqual(week.remaining, 0)\n    }\n}", "note": "O segundo afirma uma regra que o código nunca recebeu: uma estudante que estuda mais que a meta tem zero minutos restantes, não um número negativo."}
]}
```

O primeiro build de um pacote com testes também compila o código de apoio dos frameworks de teste,
então é lento uma vez. O `swift build --build-tests` faz isso sozinho, e o `--disable-swift-testing`
pede ao `swift test` que rode só os testes de XCTest:

```
ana@vm:~/sw/l18/planner$ swift build --build-tests 2>&1 | tail -1
Build complete! (9.20 secs)
ana@vm:~/sw/l18/planner$ swift test --disable-swift-testing 2>&1 | grep -v frontend
Building for debugging...
[Pre-planning 1 / 95]
[Planning deferred tasks]
Build complete! (0.81 secs)
Test Suite 'All tests' started at 2026-10-30 15:26:21.343
Test Suite 'Debug-linux-x86_64.xctest' started at 2026-10-30 15:26:21.344
Test Suite 'WeekXCTests' started at 2026-10-30 15:26:21.344
Test Case 'WeekXCTests.testRemainingNeverGoesBelowZero' started at 2026-10-30 15:26:21.344
/home/ana/sw/l18/planner/Tests/PlannerCoreTests/WeekXCTests.swift:13: error: WeekXCTests.testRemainingNeverGoesBelowZero : XCTAssertEqual failed: ("-30") is not equal to ("0") - 
Test Case 'WeekXCTests.testRemainingNeverGoesBelowZero' failed (0.002 seconds)
Test Case 'WeekXCTests.testTotalCountsOnlyDoneSessions' started at 2026-10-30 15:26:21.347
Test Case 'WeekXCTests.testTotalCountsOnlyDoneSessions' passed (0.001 seconds)
Test Suite 'WeekXCTests' failed at 2026-10-30 15:26:21.347
	 Executed 2 tests, with 1 failure (0 unexpected) in 0.003 (0.003) seconds
Test Suite 'Debug-linux-x86_64.xctest' failed at 2026-10-30 15:26:21.347
	 Executed 2 tests, with 1 failure (0 unexpected) in 0.003 (0.003) seconds
Test Suite 'All tests' failed at 2026-10-30 15:26:21.347
	 Executed 2 tests, with 1 failure (0 unexpected) in 0.003 (0.003) seconds
Note: Some test targets reported failures:
  - PlannerCoreTests (XCTest)
```

**Leia primeiro a linha da falha, a que diz `error`.** Ela dá o arquivo e a linha da asserção, o
nome do teste e o que foi comparado: `("-30") is not equal to ("0")`. A semana tinha meta de 60 e 90
minutos concluídos, e `remaining` respondeu −30, que uma tela mostraria como "faltam −30 minutos". O
outro teste passou. O resto da saída é a contabilidade do executor, uma linha de início e uma de fim
para cada teste e três resumos que dizem a mesma coisa em três níveis: a classe, o pacote de testes e
a execução inteira.

## Conserte o código, não o teste

Um teste que falha é ou um erro no código ou um erro no teste, e o teste só vale a pena se você
decidir qual antes de mexer em qualquer coisa. Aqui o teste afirma a regra que o planner quer, então
o código muda: `remaining` vira `max(goal - total, 0)`.

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
}
```

```
ana@vm:~/sw/l18/planner$ swift test --disable-swift-testing 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[2 / 9] PlannerCore
[5 / 11] PlannerCore
[9 / 12] PlannerCoreTests-product
[13 / 15] PlannerCoreTests-test-runner
[16 / 16] PlannerCoreTests-test-runner
Build complete! (1.36 secs)
Test Suite 'All tests' started at 2026-10-30 15:26:23.628
Test Suite 'Debug-linux-x86_64.xctest' started at 2026-10-30 15:26:23.629
Test Suite 'WeekXCTests' started at 2026-10-30 15:26:23.629
Test Case 'WeekXCTests.testRemainingNeverGoesBelowZero' started at 2026-10-30 15:26:23.629
Test Case 'WeekXCTests.testRemainingNeverGoesBelowZero' passed (0.001 seconds)
Test Case 'WeekXCTests.testTotalCountsOnlyDoneSessions' started at 2026-10-30 15:26:23.631
Test Case 'WeekXCTests.testTotalCountsOnlyDoneSessions' passed (0.0 seconds)
Test Suite 'WeekXCTests' passed at 2026-10-30 15:26:23.631
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'Debug-linux-x86_64.xctest' passed at 2026-10-30 15:26:23.631
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'All tests' passed at 2026-10-30 15:26:23.631
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
```

O `XCTAssertEqual` é um de uma família: `XCTAssertTrue`, `XCTAssertNil`, `XCTAssertThrowsError` e
mais uma dúzia, cada um uma função com nome próprio para seu tipo de verificação. Essa família é a
principal coisa que o Swift Testing veio substituir, como mostra a seção 03.
