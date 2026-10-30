---
title: Swift Testing, o framework de toda plataforma
version: 1
---

**Um teste é um programa que sabe a resposta.** Ele monta um plano, chama o código e diz qual o
resultado tem de ser; rodado toda vez que algo muda, é a única conferência que não se cansa. A aula 1
escreveu dois com o **Swift Testing**, o framework que o toolchain do Swift 6 traz no macOS, no Linux e
no Windows. Esta aula escreve o resto dos testes do planner, e todos rodam aqui, com `swift test`,
exatamente como rodam no Xcode.

Comece pelo pacote da aula 1. Copie-o com `cp -r ~/planner ~/l20` e trabalhe na cópia; nada nos
arquivos da aula 1 muda nesta aula, e cada teste abaixo é um arquivo novo em `Tests/PlannerCoreTests/`.

## Uma suíte de testes sobre uma coisa só

Salve isto como `Tests/PlannerCoreTests/WeekTests.swift`:

```schooling-example
{"language": "swift", "file": "Tests/PlannerCoreTests/WeekTests.swift", "parts": [{"code": "// Tests/PlannerCoreTests/WeekTests.swift\nimport Testing\n@testable import PlannerCore\n\n@Suite(\"A week's total\")\nstruct WeekTests {\n    let plan = Plan(\n        courses: [Course(id: \"sql\", title: \"SQL Databases\")],\n        sessions: [\n            StudySession(id: \"s1\", courseID: \"sql\", date: \"2026-10-19\", minutes: 50, done: true),\n            StudySession(id: \"s2\", courseID: \"sql\", date: \"2026-10-23\", minutes: 60),\n            StudySession(id: \"s3\", courseID: \"sql\", date: \"2026-10-26\", minutes: 45, done: true),\n        ]\n    )\n\n", "note": "O `@Suite` agrupa testes sob um nome que uma pessoa lê, e uma suíte é uma `struct` comum. As propriedades guardadas são o fixture: o Swift Testing cria uma instância nova da struct para cada teste, então cada teste começa deste plano e nenhum teste vê o que outro mudou."}, {"code": "    @Test func countsOnlyTheWeekOfToday() {\n        let total = plan.weekTotal(today: \"2026-10-21\")\n        #expect(total.planned == 110)\n        #expect(total.done == 50)\n    }\n\n", "note": "O `#expect` é uma macro, então quando falha consegue imprimir os dois lados da comparação e a expressão de onde vieram. A semana do dia 21 tem `s1` e `s2`: 110 planejados, 50 feitos. A `s3` é da segunda seguinte."}, {"code": "    @Test func markingDoneMovesOnlyDone() throws {\n        var plan = plan\n        try plan.markDone(\"s2\")\n        let total = plan.weekTotal(today: \"2026-10-21\")\n        #expect(total.planned == 110)\n        #expect(total.done == 110)\n    }\n\n    @Test func anUnknownSessionIsAnError() {\n        var plan = plan\n        #expect(throws: PlanError.unknownSession(\"s9\")) {\n            try plan.markDone(\"s9\")\n        }\n    }\n}\n", "note": "O `var plan = plan` copia o fixture, porque `Plan` é um valor, e muda só a cópia. Uma função de teste marcada `throws` falha se algo dentro dela lançar, então um erro inesperado do `markDone` é uma falha com a sua mensagem. O último teste espera o erro, pelo valor."}]}
```

O `--filter` roda só os testes cujos nomes batem, e o `grep` guarda as linhas que dão resultado. Sem os
dois, o `swift test` roda tudo e imprime também o progresso:

```
ana@vm:~/l20$ swift test --filter WeekTests 2>&1 | grep -E "^(✔|✘)"
✔ Test anUnknownSessionIsAnError() passed after 0.001 seconds.
✔ Test markingDoneMovesOnlyDone() passed after 0.001 seconds.
✔ Test countsOnlyTheWeekOfToday() passed after 0.001 seconds.
✔ Suite "A week's total" passed after 0.001 seconds.
✔ Test run with 3 tests in 1 suite passed after 0.001 seconds.
```

**O nome da suíte, e não o tipo, é o que o relatório imprime**, e por isso o nome é uma frase. Os três
testes são três afirmações sobre uma coisa, cada uma com o seu nome, e quando uma falha as outras duas
continuam dizendo o que ainda vale.

## `#expect` e `#require`

O `#expect` registra uma falha e deixa o teste seguir, então uma execução relata toda expectativa que
não se cumpriu. **O `#require` para o teste** quando a condição falha, e é o que usar quando o resto do
teste não faria sentido: `let session = try #require(plan.sessions.first)` encerra o teste de forma
limpa num plano vazio, onde `plan.sessions.first!` derrubaria a execução inteira.
