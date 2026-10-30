---
title: XCTest, que todo projeto Xcode já tem
version: 1
---

**O XCTest é o framework com que os projetos iOS testam desde antes de o Swift existir, e um projeto
Xcode novo ainda vem com ele.** Os testes de interface da seção 06 são XCTest e nada mais, e a maioria
dos projetos em que você entrar terá milhares de testes unitários em XCTest escritos antes de o Swift
Testing chegar. Os dois frameworks rodam no mesmo `swift test`, lado a lado, e por isso a saída da
aula 1 imprimiu dois relatórios.

As mesmas duas conferências que a aula 1 fez, escritas em XCTest. Salve isto como
`Tests/PlannerCoreTests/LegacyTests.swift`:

```swift
// Tests/PlannerCoreTests/LegacyTests.swift
import XCTest
@testable import PlannerCore

final class LegacyTests: XCTestCase {
    func testMondayOfASunday() {
        XCTAssertEqual(mondayOf("2026-10-25"), "2026-10-19")
    }

    func testASessionForNoCourseIsRefused() {
        var plan = Plan(courses: [Course(id: "sql", title: "SQL Databases")])
        XCTAssertThrowsError(try plan.add(
            StudySession(id: "s1", courseID: "art", date: "2026-10-19", minutes: 30)
        ))
        XCTAssertTrue(plan.sessions.isEmpty)
    }
}
```

Quatro diferenças carregam quase todo o resto:

| | XCTest | Swift Testing |
|---|---|---|
| um teste é | um método cujo nome começa com `test`, numa subclasse de `XCTestCase` | qualquer função marcada `@Test` |
| uma expectativa | uma função por tipo: `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertThrowsError` | `#expect` com qualquer expressão booleana |
| um fixture | os métodos `setUp()` e `tearDown()` | o `init` da suíte, ou as propriedades guardadas |
| rodar em paralelo | desligado por padrão | ligado por padrão |

```
ana@vm:~/l20$ swift test --filter LegacyTests 2>&1 | grep -E "^(Test Case|Test Suite .LegacyTests|	 Executed)" | head -6
Test Suite 'LegacyTests' started at 2026-10-30 15:44:57.851
Test Case 'LegacyTests.testASessionForNoCourseIsRefused' started at 2026-10-30 15:44:57.851
Test Case 'LegacyTests.testASessionForNoCourseIsRefused' passed (0.001 seconds)
Test Case 'LegacyTests.testMondayOfASunday' started at 2026-10-30 15:44:57.852
Test Case 'LegacyTests.testMondayOfASunday' passed (0.202 seconds)
Test Suite 'LegacyTests' passed at 2026-10-30 15:44:58.054
```

**O XCTest imprime uma linha quando cada teste começa e quando termina**, com os nomes da classe e do
método, e um resumo por suíte. O nome do método é o único nome que o teste tem, e por isso nomes de
XCTest viram frases em camel case.

Não há motivo para reescrever testes XCTest que funcionam. Escreva os novos em Swift Testing e deixe os
testes de interface onde estão: o Swift Testing não dirige a interface de um app.
