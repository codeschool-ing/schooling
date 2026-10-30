---
title: Form e Section, e a tela que eles fazem
version: 1
---

**O `SessionForm` é a única tela do planner onde alguém digita, e o SwiftUI tem um contêiner feito para
isso.** O `Form` agrupa controles de entrada de dados, e a documentação da Apple para ele diz o que ele
faz com eles: no iOS um formulário aparece como uma lista agrupada, linhas em grupos arredondados com um
título sobre cada um, e o mesmo código no macOS vira pilhas verticais alinhadas. Você descreve os campos
e a plataforma decide como uma tela de ajustes fica nela. Nada nesta seção foi executado para o curso:
não há Mac na gravação dele, e o código foi escrito a partir da documentação da Apple para `Form`,
`Section`, `Picker`, `DatePicker` e `TextField` como estava em 30 de outubro de 2026.

## A tela

O formulário precisa dos cursos para escolher e de algo para chamar quando uma sessão estiver pronta.
Ele guarda um `SessionDraft`, o tipo da seção 04, como estado, e é na aula 6 que o `@State` e o `$` de
`$draft.minutesText` foram explicados:

```swift
// SessionForm.swift
import SwiftUI
import PlannerCore

struct SessionForm: View {
    let courses: [Course]
    let onAdd: (StudySession) -> Void

    @State private var draft = SessionDraft(date: .now)
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Course") {
                Picker("Course", selection: $draft.courseID) {
                    Text("Choose one").tag(String?.none)
                    ForEach(courses) { course in
                        Text(course.title).tag(Optional(course.id))
                    }
                }
            }
            Section("When and how long") {
                DatePicker("Day", selection: $draft.date, displayedComponents: .date)
                TextField("Minutes", text: $draft.minutesText)
            }
        }
        .navigationTitle("New session")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    if let session = draft.session(id: UUID().uuidString, calendar: calendar) {
                        onAdd(session)
                        dismiss()
                    }
                }
            }
        }
    }
}
```

**Cada `Section` é um grupo na tela, e a string dela é o título sobre ele.** Duas seções aqui, porque
uma pessoa lê o formulário como duas perguntas: qual curso, e quando e por quanto tempo.

Três detalhes carregam mais do que parecem:

- **A seleção do picker é `String?`, então toda tag é `String?` também.** `Text("Choose one")` tem a
  tag `nil`, que é o "nenhum curso ainda" do rascunho, e cada curso tem a tag `Optional(course.id)`. A
  documentação da Apple para o `Picker` pede que o tipo de cada tag bata com o da seleção. A
  documentação atual de `tag(_:includeOptional:)` acrescenta que um `.tag(course.id)` simples grava a
  versão opcional também, então ele bateria do mesmo jeito; escrever `Optional` diz o tipo em voz alta,
  onde quem lê consegue ver.
- **`displayedComponents: .date`** mostra o dia e esconde a hora. O picker ainda se liga a um `Date`
  inteiro; a seção 05 trata de transformá-lo no dia que o planner guarda.
- **O botão Add chama `draft.session(…)` e só age se voltar uma sessão.** O formulário não toma nenhuma
  decisão própria sobre o que é válido. É por isso que a seção 04 pôde testar cada regra sem tela, e por
  isso que as mesmas regras valem no Android e no React Native.

`@Environment(\.calendar)` é o calendário dos ajustes do telefone, o que a pessoa vê no picker. O
`dismiss` fecha a sheet em que o formulário é apresentado, que a aula 9 abriu. O `id` é um `UUID` novo,
porque o id de uma sessão tem de ser único e não significar nada, pelos motivos que a aula 8 deu.
