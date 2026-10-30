---
title: Ligando às telas
version: 1
---

**Tudo acima roda sem tela, e é por isso que pôde ser testado.** Num Mac, as telas recebem o
repositório e leem dele, e o código que faz isso é curto porque o repositório já decidiu tudo o que era
difícil. Esta seção é SwiftUI, escrita a partir da documentação da Apple para a macro `Observable`, o
`task` e o `refreshable`, e **não foi executada**.

## Um objeto para as telas observarem

O repositório é um actor, e o SwiftUI desenha no main actor, então uma view não lê o repositório
diretamente. Ela lê o `PlannerModel` da aula 7, uma classe `@Observable` que guarda o plano que as
telas desenham e pergunta ao repositório por elas:

```swift
// PlannerModel+Repository.swift
import Observation
import PlannerCore

@MainActor
@Observable
final class PlannerModel {
    private(set) var plan = Plan()
    private(set) var waiting = 0
    private(set) var notice: String?
    let repository: PlannerRepository

    init(repository: PlannerRepository) {
        self.repository = repository
    }

    func show() async {
        plan = await repository.plan
        waiting = await repository.pendingCount
    }

    func refresh() async {
        await show()                                  // what the device has, at once
        do throws(APIError) {
            try await repository.refresh()
            notice = nil
        } catch {
            notice = error.message                    // say so, and keep the plan
        }
        await show()
    }

    func add(_ s: StudySession) async {
        do throws(PlanError) {
            let refused = try await repository.add(s)
            notice = refused.isEmpty ? nil : "The server did not keep \(refused.joined(separator: ", "))."
        } catch {
            notice = "\(error)"
        }
        await show()
    }
}
```

É na aula 7 que o `PlannerModel` é construído e explicado; este é o formato que ele toma quando um
repositório fica atrás dele. **O `show` é chamado primeiro no `refresh`**, então a tela desenha o que
o aparelho tem antes de a rede responder, que é a promessa da seção 04 chegando ao vidro.

## A tela

O `CourseListView` da aula 12 não guarda mais um `Loadable`. Ele desenha o plano do modelo, que nunca
fica vazio por causa da rede, e uma linha acima dele quando há algo a dizer:

```swift
// CourseListView.swift
import SwiftUI
import PlannerCore

struct CourseListView: View {
    let model: PlannerModel

    var body: some View {
        List {
            if let notice = model.notice {
                Text(notice).font(.footnote)
            }
            if model.waiting > 0 {
                Text("\(model.waiting) not yet sent").font(.footnote)
            }
            ForEach(model.plan.courses) { course in
                Text(course.title)
            }
        }
        .task { await model.refresh() }
        .refreshable { await model.refresh() }
    }
}
```

O `refreshable` acrescenta puxar-para-atualizar à lista, e o sistema mostra o indicador dele enquanto
a closure roda. **O estado offline agora é uma linha de texto sobre uma lista que funciona, não uma
tela própria**, e essa diferença é o que o repositório comprou. A tela de erro da aula 12 ainda tem o
seu lugar: a primeira abertura, quando o aparelho não tem nada para mostrar.
