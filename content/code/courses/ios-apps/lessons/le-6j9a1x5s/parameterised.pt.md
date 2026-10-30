---
title: Um teste, muitos argumentos
version: 1
---

**Sete testes que só diferem na entrada são um teste com sete argumentos.** Escritos como sete funções,
são sete cópias para manter em dia, e o oitavo caso em que alguém pensa é o que ninguém acrescenta. O
Swift Testing recebe as entradas como uma lista: o `@Test(arguments:)` roda a função uma vez por
elemento, e relata cada execução como um **caso de teste** próprio.

O `mondayOf` é a única conta de calendário do planner, e é justamente o código em que os casos importam
mais que o código. Salve isto como `Tests/PlannerCoreTests/MondayTests.swift`:

```swift
// Tests/PlannerCoreTests/MondayTests.swift
import Testing
@testable import PlannerCore

@Test("Every day of a week finds the same Monday", arguments: [
    "2026-10-19", "2026-10-20", "2026-10-21", "2026-10-22",
    "2026-10-23", "2026-10-24", "2026-10-25",
])
func sameMonday(day: String) {
    #expect(mondayOf(day) == "2026-10-19")
}

@Test("A week that crosses a boundary", arguments: [
    ("2027-01-01", "2026-12-28"),  // New Year's Day, a Friday
    ("2028-03-01", "2028-02-28"),  // the day after a leap day
    ("2026-11-01", "2026-10-26"),  // a Sunday, and a new month
])
func crossing(day: String, monday: String) {
    #expect(mondayOf(day) == monday)
}
```

O primeiro teste recebe todos os dias de uma semana. O segundo recebe pares, e o Swift Testing passa as
duas metades de um par como os dois parâmetros da função. **Os três pares são as fronteiras**: uma
semana que começa num ano e termina no seguinte, uma semana com o 29 de fevereiro dentro, e um domingo
no começo de um mês. Um bug de calendário mora numa fronteira, e estas são as três que o planner
encontra.

```
ana@vm:~/l20$ swift test --filter "sameMonday|crossing" 2>&1 | grep -E "^(✔|✘)"
✔ Test "A week that crosses a boundary" with 3 test cases passed after 0.002 seconds.
✔ Test "Every day of a week finds the same Monday" with 7 test cases passed after 0.002 seconds.
✔ Test run with 2 tests in 0 suites passed after 0.002 seconds.
```

## Vendo falhar

Um teste que nunca falhou não mostrou que testa alguma coisa. Quebre o `mondayOf` de propósito, trocando
o `5` de `(weekday + 5) % 7` por um `6`, e rode os mesmos testes:

```
ana@vm:~/l20$ sed -i 's/(weekday + 5) % 7/(weekday + 6) % 7/' Sources/PlannerCore/Days.swift
ana@vm:~/l20$ swift test --filter crossing 2>&1 | grep -E "^(✘|↳)"
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
✘ Test "A week that crosses a boundary" recorded an issue with 2 arguments day → "2027-01-01", monday → "2026-12-28" at MondayTests.swift:19:5: Expectation failed: mondayOf(day) == monday
↳ mondayOf(day) == monday → false
↳   mondayOf(day) → "2026-12-27"
↳   monday → "2026-12-28"
✘ Test "A week that crosses a boundary" recorded an issue with 2 arguments day → "2028-03-01", monday → "2028-02-28" at MondayTests.swift:19:5: Expectation failed: mondayOf(day) == monday
↳ mondayOf(day) == monday → false
↳   mondayOf(day) → "2028-02-27"
↳   monday → "2028-02-28"
✘ Test "A week that crosses a boundary" recorded an issue with 2 arguments day → "2026-11-01", monday → "2026-10-26" at MondayTests.swift:19:5: Expectation failed: mondayOf(day) == monday
↳ mondayOf(day) == monday → false
↳   mondayOf(day) → "2026-11-01"
↳   monday → "2026-10-26"
✘ Test "A week that crosses a boundary" with 3 test cases failed after 0.002 seconds with 3 issues.
✘ Test run with 1 test in 0 suites failed after 0.002 seconds with 3 issues.
ana@vm:~/l20$ swift test --filter sameMonday 2>&1 | grep -E "^✘ Test .* failed after"
✘ Test "Every day of a week finds the same Monday" with 7 test cases failed after 0.002 seconds with 7 issues.
✘ Test run with 1 test in 0 suites failed after 0.002 seconds with 7 issues.
ana@vm:~/l20$ sed -i 's/(weekday + 6) % 7/(weekday + 5) % 7/' Sources/PlannerCore/Days.swift
```

**Cada caso que falha é nomeado pelo seu argumento**, e embaixo dele as linhas `↳` desmontam a
comparação: a expressão, depois o valor de cada lado. É isso que a macro `#expect` compra em relação a
um `==` simples que devolve `false`. A fórmula errada erra por um dia em todo lugar. A maioria dos dias
cai no domingo antes da sua segunda, e um domingo, `2026-11-01`, decide que é a sua própria segunda. Os
sete dias da semana falham também, e o segundo comando diz isso numa linha. O último comando devolve o
`5`.
