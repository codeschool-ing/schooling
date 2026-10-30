---
title: A que uma view está inscrita, medido
version: 1
---

**Uma view está inscrita exatamente nas propriedades que o `body` dela leu da última vez que rodou, e
em nada mais.** Esse é o contrato inteiro do Observation com o SwiftUI, e dá para vê-lo no Linux,
porque o SwiftUI usa a mesma função pública que qualquer um pode chamar:
`withObservationTracking(_:onChange:)`. Ela roda uma closure, registra cada propriedade observável que
a closure leu, e chama o `onChange` na primeira vez que uma delas está para ser escrita.

Este programa faz o papel de três views. Cada "view" é uma closure que lê o que o `body` daquela tela
leria, e o `onChange` imprime onde o SwiftUI desenharia de novo. Cada cena faz um modelo novo, para que
as inscrições de uma cena não vazem para a próxima. Salve-o como `Sources/track/main.swift`:

```schooling-example
{"language": "swift", "file": "Sources/track/main.swift", "parts": [{"code": "// Sources/track/main.swift\nimport Observation\nimport PlannerCore\n\n@MainActor func sampleModel() -> PlannerModel {\n    PlannerModel(\n        plan: Plan(\n            courses: [Course(id: \"sql\", title: \"SQL Databases\"), Course(id: \"mobile\", title: \"Mobile Fundamentals\")],\n            sessions: [\n                StudySession(id: \"s1\", courseID: \"sql\", date: \"2026-10-19\", minutes: 50, done: true),\n                StudySession(id: \"s3\", courseID: \"sql\", date: \"2026-10-23\", minutes: 60),\n            ]\n        ),\n        today: \"2026-10-21\"\n    )\n}\n", "note": "Um plano pequeno, dois cursos e duas sessões, os mesmos dados que as outras aulas usam."}, {"code": "@MainActor func scene(_ title: String, _ change: (PlannerModel) throws -> Void) rethrows {\n    let model = sampleModel()\n    print(title)\n    withObservationTracking { _ = model.plan.courses.map(\\.title) } onChange: {\n        print(\"  CourseListView would run body again\")\n    }\n    withObservationTracking { _ = model.week } onChange: {\n        print(\"  WeekView would run body again\")\n    }\n    withObservationTracking { _ = model.today } onChange: {\n        print(\"  Header would run body again\")\n    }\n    try change(model)\n}\n", "note": "Três inscrições, uma por tela. A lista de cursos lê os títulos dos cursos; a tela da semana lê `week`, que lê `plan` e `today`; um cabeçalho lê só `today`. Depois a cena faz uma mudança."}, {"code": "scene(\"today moves on a week\") { $0.today = \"2026-10-28\" }\ntry scene(\"s3 is marked done\") { try $0.markDone(\"s3\") }\nscene(\"a course is renamed\") { $0.plan.courses[0].title = \"SQL\" }\nscene(\"lastSaved is set\") { $0.lastSaved = \"2026-10-21T18:00\" }\n", "note": "Quatro mudanças, uma por cena."}]}
```

```
ana@vm:~/observe$ swift build 2>&1 | grep -E "error|warning"
ana@vm:~/observe$ .build/debug/track
today moves on a week
  WeekView would run body again
  Header would run body again
s3 is marked done
  WeekView would run body again
  CourseListView would run body again
a course is renamed
  WeekView would run body again
  CourseListView would run body again
lastSaved is set
```

O `swift build` compila o modelo novo e o programa novo, e o `grep` não mostra nada porque nada do
que ele devia mostrar, um erro ou um aviso, foi impresso. Depois, as quatro cenas:

- **`today` mudou, e só as duas telas que o leram foram avisadas.** A lista de cursos leu títulos, que
  moram em `plan`, então ficou de fora.
- **Marcar `s3` como feita avisou a tela da semana, o que está certo, e a lista de cursos, que não
  desenhou nada que mudou.** A lista leu `model.plan.courses`, e o Observation rastreia `plan` como uma
  propriedade só: qualquer escrita nela, inclusive numa sessão, é uma escrita em `plan`.
- **Renomear um curso avisou a tela da semana também**, cujos números não mexeram, pelo mesmo motivo.
- **`lastSaved` não avisou ninguém**, porque o `@ObservationIgnored` o tirou do rastreamento.

A ordem das linhas dentro de uma cena não é algo em que se apoiar, e em outra execução ela pode mudar:
o Observation não guarda ordem entre as views que avisa.

**A segunda e a terceira cenas são o custo de guardar o plano como um valor só.** Uma tela que lê
qualquer parte de `plan` é redesenhada quando qualquer parte dele muda. Para um planner com algumas
dezenas de sessões isso não custa nada que alguém veja, e a simplicidade vale mais. Quando importa,
uma lista de alguns milhares de linhas, a correção é quebrar o estado em pedaços observáveis que cada
tela lê em separado, e a aula 8 mede o que uma lista realmente redesenha.
