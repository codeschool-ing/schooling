---
title: A decisão, como Swift puro que dá para testar
version: 1
---

**A fase é do SwiftUI; o que o planner faz com ela é do planner.** O `ScenePhase` mora no SwiftUI,
então não compila no Linux. A decisão que ele aciona compila, se for escrita contra um tipo do próprio
planner: três fases, e três coisas que o planner pode fazer quando a fase muda. Essa decisão vai então
para o pacote da aula 1, onde o `swift test` consegue segurá-la.

Duas regras vêm da documentação da Apple sobre o ciclo de vida de um app. **Sair da fase ativa quer
dizer salvar**: a documentação manda salvar os dados ao sair do estado ativo em primeiro plano, e do
segundo plano o iOS pode encerrar o processo sem mais nenhuma palavra. **Voltar a ativa depois do
segundo plano quer dizer atualizar**, porque o dia pode ter mudado enquanto o app estava fora, e com
ele a semana a que os totais pertencem. Um banner puxado por cima do app o deixa inativo por um
instante: salvar nessa hora é uma escrita curta e inofensiva, e atualizar seria desperdício.

## Uma primeira tentativa, e o teste que a pega

A versão óbvia olha só para a fase para onde está indo. Salve isto como
`Sources/PlannerCore/Lifecycle.swift` no pacote `planner` da aula 1:

```swift
// Sources/PlannerCore/Lifecycle.swift
/// The three phases SwiftUI reports for a scene, as a type of the planner's
/// own, so the decision can be tested without SwiftUI.
public enum Phase: Sendable {
    case active, inactive, background
}

public enum PhaseAction: Equatable, Sendable {
    case nothing
    case save     // the app may not come back from the background
    case refresh  // the day, and the week, may have changed while it was away
}

public struct Lifecycle: Sendable {
    public private(set) var phase: Phase

    public init(phase: Phase) {
        self.phase = phase
    }

    public mutating func move(to new: Phase) -> PhaseAction {
        defer { phase = new }
        switch (phase, new) {
        case (.active, .inactive), (.active, .background):
            return .save
        case (_, .active):
            return .refresh
        default:
            return .nothing
        }
    }
}
```

E as duas viagens que um telefone faz de verdade, como testes. Salve isto como
`Tests/PlannerCoreTests/LifecycleTests.swift`:

```swift
// Tests/PlannerCoreTests/LifecycleTests.swift
import Testing
@testable import PlannerCore

/// Start active, move through `phases`, and return what each move decided.
func replay(_ phases: [Phase]) -> [PhaseAction] {
    var life = Lifecycle(phase: .active)
    return phases.map { life.move(to: $0) }
}

@Test func aBannerSavesAndDoesNotRefresh() {
    #expect(replay([.inactive, .active]) == [.save, .nothing])
}

@Test func goingHomeSavesOnceAndComingBackRefreshes() {
    #expect(replay([.inactive, .background, .inactive, .active])
            == [.save, .nothing, .nothing, .refresh])
}
```

```
ana@vm:~/l02/planner$ swift test 2>&1 | grep -v "^\[" | grep -v "^Test Suite\|Executed 0 tests"
Building for debugging...
Build complete! (3.15 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test aBannerSavesAndDoesNotRefresh() started.
◇ Test mondayIsTheStartOfTheWeek() started.
◇ Test goingHomeSavesOnceAndComingBackRefreshes() started.
◇ Test aSessionForNoCourseIsRefused() started.
✔ Test goingHomeSavesOnceAndComingBackRefreshes() passed after 0.001 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.001 seconds.
✘ Test aBannerSavesAndDoesNotRefresh() recorded an issue at LifecycleTests.swift:12:5: Expectation failed: replay([.inactive, .active]) == [.save, .nothing]
↳ replay([.inactive, .active]) == [.save, .nothing] → false
↳   replay([.inactive, .active]) → [PlannerCore.PhaseAction.save, PlannerCore.PhaseAction.refresh]
↳   [.save, .nothing] → [PlannerCore.PhaseAction.save, PlannerCore.PhaseAction.nothing]
✔ Test mondayIsTheStartOfTheWeek() passed after 0.001 seconds.
✘ Test aBannerSavesAndDoesNotRefresh() failed after 0.001 seconds with 1 issue.
✘ Test run with 4 tests in 0 suites failed after 0.001 seconds with 1 issue.
Note: Some test targets reported failures:
  - PlannerCoreTests (Swift Testing)
```

Os dois `grep` tiram as linhas de progresso da compilação e o relatório vazio do XCTest que a aula 1
explicou, então o que sobra é o relatório do próprio Swift Testing.

**A falha cita a expressão, os dois lados dela e a linha.** O teste do banner esperava `.nothing` em
segundo e recebeu `.refresh`, porque a primeira versão atualiza a cada volta para ativa, e um banner é
uma volta para ativa. A ida para a tela inicial passou, e essa é a armadilha: o código está certo
para o caso que o autor imaginou e errado para o mais comum.

## A versão que lembra

O que faltava era um fato sobre o passado: se a cena foi para o segundo plano desde a última vez que
esteve ativa. Troque `Sources/PlannerCore/Lifecycle.swift` por isto:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/Lifecycle.swift", "parts": [{"code": "// Sources/PlannerCore/Lifecycle.swift\n/// The three phases SwiftUI reports for a scene, as a type of the planner's\n/// own, so the decision can be tested without SwiftUI.\npublic enum Phase: Sendable {\n    case active, inactive, background\n}\n\npublic enum PhaseAction: Equatable, Sendable {\n    case nothing\n    case save     // the app may not come back from the background\n    case refresh  // the day, and the week, may have changed while it was away\n}\n", "note": "Os mesmos dois tipos. `Phase` espelha o `ScenePhase` do SwiftUI caso a caso, e a seção 07 mostra as linhas que transformam um no outro."}, {"code": "public struct Lifecycle: Sendable {\n    public private(set) var phase: Phase\n    private var wasInBackground = false\n\n    public init(phase: Phase) {\n        self.phase = phase\n    }\n", "note": "Mais um pedaço de estado, privado: se o segundo plano aconteceu desde a última vez que a cena esteve ativa. O `private(set)` deixa quem chama ler a fase e não alterá-la."}, {"code": "    public mutating func move(to new: Phase) -> PhaseAction {\n        defer { phase = new }\n        if new == .background { wasInBackground = true }\n        switch (phase, new) {\n        case (.active, .inactive), (.active, .background):\n            return .save\n        case (_, .active) where wasInBackground:\n            wasInBackground = false\n            return .refresh\n        default:\n            return .nothing\n        }\n    }\n}\n", "note": "O switch é sobre o par, fase antiga e fase nova. `case (_, .active) where wasInBackground` é um padrão com condição: qualquer ida para ativa, mas só depois do segundo plano. O `defer` grava a fase nova depois que o switch leu a antiga."}]}
```

```
ana@vm:~/l02/planner$ swift test 2>&1 | grep -v "^\[" | grep -v "^Test Suite\|Executed 0 tests"
Building for debugging...
Build complete! (1.66 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test goingHomeSavesOnceAndComingBackRefreshes() started.
◇ Test aBannerSavesAndDoesNotRefresh() started.
◇ Test mondayIsTheStartOfTheWeek() started.
◇ Test aSessionForNoCourseIsRefused() started.
✔ Test aBannerSavesAndDoesNotRefresh() passed after 0.001 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.001 seconds.
✔ Test goingHomeSavesOnceAndComingBackRefreshes() passed after 0.001 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.001 seconds.
✔ Test run with 4 tests in 0 suites passed after 0.001 seconds.
```

Quatro testes, como na primeira execução, porque os dois da aula 1 estão no mesmo pacote e rodam com
estes. **Nada nesses arquivos importa o SwiftUI**, e foi isso que os deixou rodar aqui. A metade do
app, que transforma `ScenePhase` em `Phase` e age sobre a resposta, está na seção 07.
