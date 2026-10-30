---
title: Sheets, para uma tarefa que volta
version: 1
---

**Uma sheet é uma tela que sobe por cima da atual para uma tarefa que a pessoa termina ou abandona, e
depois some e deixa a pessoa onde estava.** Acrescentar uma sessão é o caso do planner: na tela de um
curso, a pessoa toca em *Add*, preenche uma data e uma duração, e salva ou cancela. Empilhar o
formulário o poria no histórico de voltar, onde ele não pertence. Nada nesta seção foi executado; ela
foi escrita a partir da documentação da Apple para `sheet(isPresented:onDismiss:content:)`,
`sheet(item:onDismiss:content:)` e `DismissAction`.

```swift
// CourseDetailView.swift
struct CourseDetailView: View {
    let courseID: String
    @Environment(PlannerModel.self) private var model
    @State private var adding = false

    var body: some View {
        List(model.plan.sessions(of: courseID)) { session in
            SessionRow(session: session)
        }
        .toolbar {
            Button("Add") { adding = true }
        }
        .sheet(isPresented: $adding) {
            SessionForm(courseID: courseID)
        }
    }
}
```

**`adding` é o único estado de que esta tela é dona**, o `@State` da aula 6 usado como deve: nada mais
precisa saber se o formulário está aberto. A sheet aparece enquanto ele é `true`, e o SwiftUI o volta
para `false` quando a sheet some, seja qual for o jeito.

O formulário se fecha com a ação `dismiss` do ambiente:

```swift
// SessionForm.swift
struct SessionForm: View {
    let courseID: String
    @Environment(\.dismiss) private var dismiss
    @Environment(PlannerModel.self) private var model

    var body: some View {
        NavigationStack {
            Form { /* lesson 10 */ }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { save(); dismiss() } }
                }
        }
    }

    private func save() { /* lesson 10 */ }
}
```

**A sheet tem o seu próprio `NavigationStack`**, e esse não é o aninhamento de que a seção 02 falou:
uma sheet é uma apresentação separada, e uma pilha dentro dela é o que dá ao formulário a sua própria
barra para *Cancel* e *Save*.

Quando uma sheet mostra um item, uma sessão a editar, o `sheet(item:)` recebe um valor `Identifiable`
opcional: a sheet aparece quando ele não é `nil` e recebe o valor, e ele volta a `nil` quando ela some.
Isso põe *qual* sessão no mesmo estado que decide *se*, o que é de novo um fato num lugar só.

Uma pessoa também pode puxar uma sheet para baixo. A documentação da Apple para o
`interactiveDismissDisabled(_:)` mostra como impedir isso enquanto um formulário tem mudanças não
salvas, para uma sessão meio digitada não se perder num deslizar sem querer; a aula 10 o usa.
