---
title: '@Binding: escrever num armazenamento que não é seu'
version: 1
---

**Uma view filha que muda um valor que não é dela recebe um binding para ele.** Um binding não é uma
cópia nem o armazenamento: é um par de operações, ler o valor e escrever o valor, que alcançam o
lugar onde o dono o guarda. Os controles do SwiftUI são feitos sobre ele. Um `Toggle` recebe
`isOn: Binding<Bool>`, um `TextField` recebe `text: Binding<String>`, e nenhum dos dois faz ideia se o
valor mora num `@State`, num objeto observável ou em outro lugar.

Nada nesta seção foi executado para o curso; ela foi escrita a partir da documentação da Apple para o
`Binding` e o `Toggle`. Esta é uma linha da tela de curso do planner que marca uma sessão como feita:

```swift
// SessionRow.swift
import SwiftUI
import PlannerCore

struct SessionRow: View {
    @Binding var session: StudySession

    var body: some View {
        Toggle(isOn: $session.done) {
            Text("\(session.date) · \(session.minutes) min")
        }
    }
}
```

**O cifrão é o valor projetado.** Numa propriedade `@State` ou `@Binding`, `$nome` é um `Binding`
para ela. `$session.done` vai um passo além: um binding para o campo `done` dentro da sessão, feito a
partir do binding para a sessão inteira. O `Binding` permite isso pelo dynamic member lookup do Swift
com key paths, e é por isso que `$plan.sessions[2].done` também é um binding.

O pai entrega um binding por linha. O `ForEach` aceita um binding para uma coleção e dá à closure um
binding para cada elemento:

```swift
// in CourseDetailView's body
List {
    ForEach($plan.sessions) { $session in
        SessionRow(session: $session)
    }
}
```

`{ $session in` declara o parâmetro da closure como um binding e, lá dentro, `session` lê o valor e
`$session` é o binding de novo. Quando a pessoa vira um toggle, a escrita passa por dois bindings até
o `@State` do pai, o `body` do pai roda de novo, e o total embaixo da lista é recalculado a partir do
mesmo plano. **A filha nunca guardou uma cópia de `done`, então não há cópia para ficar para trás.**

Um binding também pode ser feito do zero, com `Binding(get:set:)`, e `Binding.constant(true)` é um que
ignora escritas, que é como um preview mostra uma linha sem pai. A seção 05 monta o próprio tipo.
