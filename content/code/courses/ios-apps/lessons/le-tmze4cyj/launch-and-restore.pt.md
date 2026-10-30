---
title: Abrir, ser encerrado e voltar
version: 1
---

**Um app que foi encerrado em segundo plano e aberto de novo começa do nada, e a pessoa não deveria
perceber.** Ela o deixou na tela de detalhe de um curso com uma sessão digitada pela metade; o iOS
recuperou a memória; ela toca no ícone e espera estar onde estava. Duas coisas diferentes têm de
sobreviver para isso, e o SwiftUI dá a cada uma o seu lugar.

| o quê | exemplo | para onde vai |
|---|---|---|
| os dados | o plano: cursos e sessões | gravados em disco pelo app, no momento em que a seção 05 decidiu salvar |
| onde a pessoa estava | qual curso estava aberto, qual aba, o que foi digitado num campo | `@SceneStorage`, que o SwiftUI salva e restaura por cena |

**Misturar os dois é o erro comum.** O `@SceneStorage`, diz a documentação da Apple, é para valores
pequenos: ele não garante quando nem com que frequência o valor é salvo, e é destruído junto com a
cena, por exemplo quando uma pessoa tira a janela do app do seletor do iPad. Um plano guardado ali
poderia sumir com uma janela. Dados de que a pessoa sentiria falta vão para um arquivo ou um banco de
dados, que as aulas 13 e 14 constroem; o `@SceneStorage` guarda só o que é barato perder.

## Ligando a decisão ao app

A seção 05 escreveu a decisão em Swift puro. Esta é a metade do app: ler a fase, transformá-la no
`Phase` do planner, e agir sobre o que o `Lifecycle` responde. Nada aqui foi executado para o curso:

```swift
// PlannerApp.swift
import SwiftUI
import PlannerCore

extension Phase {
    init(_ phase: ScenePhase) {
        switch phase {
        case .active: self = .active
        case .inactive: self = .inactive
        case .background: self = .background
        @unknown default: self = .inactive
        }
    }
}

@main
struct PlannerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var lifecycle = Lifecycle(phase: .active)

    var body: some Scene {
        WindowGroup {
            CourseListView()
        }
        .onChange(of: scenePhase) { _, new in
            switch lifecycle.move(to: Phase(new)) {
            case .save: print("save the plan")        // lesson 14 writes it
            case .refresh: print("recompute the week") // lesson 6 shows it
            case .nothing: break
            }
        }
    }
}
```

**O `@unknown default` está ali porque o `ScenePhase` pertence à Apple e pode ganhar um caso num iOS
futuro.** O compilador o pede num switch sobre um enum de outro módulo que pode crescer, e mapear uma
fase desconhecida para `inactive` quer dizer "não fazer nada por enquanto" em vez de travar. Como o
`onChange` está no `App`, a fase que ele vê é o agregado de todas as janelas, que é o que decidir
quando salvar o plano compartilhado precisa.

As duas linhas de `print` estão no lugar de trabalho que aulas posteriores fazem. Elas também deixam a
decisão visível: num Mac, o console do Xcode mostraria uma linha por movimento, e a sequência bateria
com os testes da seção 05.

## O que a abertura em si faz

Numa abertura a frio o iOS inicia o processo, o SwiftUI cria o `PlannerApp`, lê o `body` dele, e a
cena vai do nada para ativa. **Não existe um callback de abertura separado onde pôr trabalho**, e a
aula 12 mostra onde carregar dados deve ficar: numa task presa à view que precisa deles, para que ela
comece quando a view aparece e seja cancelada se a view sumir antes.
