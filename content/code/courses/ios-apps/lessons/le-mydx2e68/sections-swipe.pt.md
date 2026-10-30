---
title: Seções, ações de deslizar e apagar uma linha
version: 1
---

**Uma lista agrupa linhas em seções, e dá a cada linha ações que a pessoa alcança deslizando.** As
duas coisas são recursos do `List`, que é um dos motivos para usar `List` em vez de uma stack. Nada
nesta seção foi executado; ela foi escrita a partir da documentação da Apple para `Section`,
`onDelete(perform:)` e `swipeActions(edge:allowsFullSwipe:content:)`.

A tela de curso agrupa as sessões de um curso entre as que faltam e as feitas:

```swift
// in CourseDetailView's body
let shown = model.plan.sessions(of: course.id)
List {
    Section("To do") {
        ForEach(shown.filter { !$0.done }) { session in
            SessionRow(session: session)
                .swipeActions(edge: .leading) {
                    Button("Done") { try? model.markDone(session.id) }
                        .tint(.green)
                }
        }
    }
    Section("Done") {
        ForEach(shown.filter(\.done)) { session in
            SessionRow(session: session)
        }
    }
}
```

O `swipeActions` acrescenta botões revelados por um deslizar a partir da borda indicada; um deslizar
pela borda inicial é o que o Mail usa para marcar como lida. **O `try?` joga o erro fora**, e aqui
isso se defende por um motivo: o id veio da linha que a pessoa acabou de deslizar, que existe, então o
`unknownSession` não tem como acontecer. Uma tela em que ele pudesse acontecer mostraria o erro, e a
aula 12 trata de mostrar um.

O jeito padrão de apagar é o `onDelete`, aplicado a um `ForEach` dentro de um `List`. Ele dá o
deslizar para apagar, e os círculos vermelhos do botão *Edit* quando há um `EditButton` na tela. O que
ele entrega é a parte importante:

```swift
ForEach(shown) { session in SessionRow(session: session) }
    .onDelete { offsets in
        model.plan.delete(at: offsets, in: shown)
    }
```

**`offsets` é um `IndexSet` de posições na coleção que o `ForEach` mostrou**, não em
`model.plan.sessions`. Na tela de curso esses são arrays diferentes: a tela mostra as sessões de um
curso, e o plano guarda todas. A seção 06 escreve o `delete(at:in:)` para traduzir um no outro pelo
id, e testa o que acontece se você pular a tradução.
