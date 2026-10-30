---
title: Calcule, não guarde
version: 1
---

**Um valor que pode ser calculado a partir da fonte da verdade vira uma segunda fonte da verdade se
você o guarda.** Ele concorda no dia em que é escrito e discorda na primeira vez que uma mudança chega
a um e não ao outro. No SwiftUI a versão calculada não custa nada a mais: o `body` roda de novo
depois de cada mudança no estado que ele leu, então um total calculado dentro dele, ou numa
propriedade calculada que ele lê, é sempre o total do plano na tela.

Isto roda em qualquer computador, porque a pergunta é sobre structs do Swift e não sobre o SwiftUI.
Copie o pacote da aula 1 para um diretório próprio, `cp -r ~/planner ~/derived`, e acrescente um
arquivo de teste ao lado do da aula 1. Salve isto como `Tests/PlannerCoreTests/DerivedTests.swift`:

```swift
// Tests/PlannerCoreTests/DerivedTests.swift
import Testing
@testable import PlannerCore

func samplePlan() -> Plan {
    Plan(
        courses: [Course(id: "sql", title: "SQL Databases"), Course(id: "mobile", title: "Mobile Fundamentals")],
        sessions: [
            StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true),
            StudySession(id: "s2", courseID: "mobile", date: "2026-10-20", minutes: 40, done: true),
            StudySession(id: "s3", courseID: "sql", date: "2026-10-23", minutes: 60),
        ]
    )
}

struct StoredTotal {
    var plan: Plan
    var total: WeekTotal

    init(plan: Plan) {
        self.plan = plan
        self.total = plan.weekTotal(today: "2026-10-21")
    }
}

struct DerivedTotal {
    var plan: Plan
    var total: WeekTotal { plan.weekTotal(today: "2026-10-21") }
}

@Test func aStoredTotalFollowsThePlan() throws {
    var screen = StoredTotal(plan: samplePlan())
    try screen.plan.markDone("s3")
    #expect(screen.total.done == 150)
}

@Test func aDerivedTotalFollowsThePlan() throws {
    var screen = DerivedTotal(plan: samplePlan())
    try screen.plan.markDone("s3")
    #expect(screen.total.done == 150)
}
```

`StoredTotal` é o primeiro rascunho que alguém escreve quando pensa numa tela como um lugar que guarda
números: calcule o total uma vez, guarde. `DerivedTotal` guarda só o plano e calcula o total sempre
que alguém pergunta. Os dois testes marcam `s3` como feita e esperam 150 minutos, os 50 e os 40 já
feitos mais os 60 dela. **Um deles falha, de propósito:**

```
ana@vm:~/derived$ swift test --filter TotalFollows
Building for debugging...
[Pre-planning 1 / 153]
[Starting]
Build complete! (0.67 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test aStoredTotalFollowsThePlan() started.
◇ Test aDerivedTotalFollowsThePlan() started.
✔ Test aDerivedTotalFollowsThePlan() passed after 0.001 seconds.
✘ Test aStoredTotalFollowsThePlan() recorded an issue at DerivedTests.swift:34:5: Expectation failed: screen.total.done == 150
↳ screen.total.done == 150 → false
↳   screen.total.done → 90
✘ Test aStoredTotalFollowsThePlan() failed after 0.001 seconds with 1 issue.
✘ Test run with 2 tests in 0 suites failed after 0.002 seconds with 1 issue.
Note: Some test targets reported failures:
  - PlannerCoreTests (Swift Testing)
```

O `--filter TotalFollows` roda só os dois testes cujo nome tem essas palavras. O Swift Testing diz
qual expectativa falhou, em qual linha, e **quanto o lado esquerdo realmente valia: 90**, o total de
antes de `s3` ser marcada. Não há nada errado na aritmética; o número guardado simplesmente nunca foi
avisado. Numa view SwiftUI o mesmo erro aparece como uma tela cuja lista mostra três sessões marcadas
e cujo rodapé ainda diz 90.

Apague o `StoredTotal` e o teste dele depois de vê-lo falhar. A regra que fica é a que a aula 7 mantém
para o modelo observável: **guarde o que a pessoa fez, e calcule o que decorre disso.**
