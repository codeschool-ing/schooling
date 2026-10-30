---
title: ObservableObject, o jeito de antes do iOS 17
version: 1
---

**A maior parte do código SwiftUI escrito antes de 2023, e muito do escrito depois, usa um mecanismo
mais antigo, e você vai lê-lo muito antes de parar de encontrá-lo.** É o protocolo `ObservableObject`
do framework Combine, com propriedades `@Published`, e quatro wrappers que andam com ele. O Combine só
existe em sistemas da Apple, então nada disto compila no Linux e nada foi executado para o curso; foi
escrito a partir do guia da Apple *Migrating from the Observable Object protocol to the Observable
macro*.

```swift
import Combine
import SwiftUI

final class OldPlannerModel: ObservableObject {
    @Published var plan = Plan()
    @Published var today = "2026-10-21"
}

struct OldWeekView: View {
    @ObservedObject var model: OldPlannerModel
    var body: some View {
        Text("\(model.plan.weekTotal(today: model.today).done) min")
    }
}
```

**A diferença que importa é a que uma view está inscrita.** Com o `ObservableObject`, uma view que
guarda o objeto está inscrita no objeto inteiro: a classe anuncia *algo vai mudar* antes de qualquer
propriedade `@Published` ser escrita, e toda view que o guarda roda o `body` de novo, leia o que tiver
lido. As cenas da seção 03 teriam redesenhado as três telas a cada mudança, `lastSaved` inclusive se
ele não ficasse sem publicar. Com o `@Observable`, como medido lá, uma view está inscrita no que o seu
`body` leu.

Os wrappers se correspondem assim:

| antes do iOS 17 | com o Observation |
|---|---|
| `@StateObject var model = Model()` | `@State var model = Model()` |
| `@ObservedObject var model: Model` | `let model: Model`, ou `@Bindable` para bindings |
| `@EnvironmentObject var model: Model` | `@Environment(Model.self) var model` |
| `.environmentObject(model)` | `.environment(model)` |

**O `@StateObject` e o `@ObservedObject` são o par que as pessoas confundem**, e a confusão é a
primeira armadilha da aula 6 com um objeto dentro. O `@StateObject` cria e guarda; o `@ObservedObject`
só observa um que recebeu. Escrever `@ObservedObject var model = Model()` cria um modelo novo toda vez
que o pai redesenha, e a tela perde tudo o que tinha. A grafia do Observation não comete esse erro em
silêncio do mesmo jeito, porque a posse é sempre `@State`.

O guia da Apple converte um app uma classe por vez, e os dois tipos convivem num app enquanto isso
acontece. Para um app novo com o iOS 17 como piso, como o planner, o `@Observable` é o que escrever.
