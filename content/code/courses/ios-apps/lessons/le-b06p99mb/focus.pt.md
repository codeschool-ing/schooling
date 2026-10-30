---
title: O foco, e para onde ele vai quando algo está errado
version: 1
---

**O foco é o controle em que o teclado está digitando, e o SwiftUI deixa o app tanto lê-lo quanto
movê-lo.** O property wrapper é o `@FocusState`, e a documentação da Apple para ele descreve as duas
direções: quando o foco entra numa view marcada com `focused(_:equals:)`, o estado assume o valor dessa
view, e mudar o estado pelo código move o foco para a view correspondente. Pô-lo em `nil` tira o foco de
todos os campos, o que também fecha o teclado. Nada aqui foi executado; está escrito a partir dessa
documentação, lida em 30 de outubro de 2026.

## Um botão desativado não diz a ninguém por quê

O jeito óbvio de barrar uma sessão ruim é `.disabled(!draft.problems.isEmpty)` no botão Add. Funciona,
e falha com a pessoa diante dele: um botão acinzentado diz *não* e nunca diz *porque*. Alguém que digitou
`1.5` não vê nada de errado na tela e um botão que não responde.

O planner faz o contrário. **O Add está sempre ativo; tocá-lo com problemas os mostra, e leva o foco ao
primeiro campo que precisa de atenção.** O rascunho já sabe todos os problemas (seção 04), então a tela
só tem de decidir para onde apontar.

```swift
// SessionForm.swift, with focus
import SwiftUI
import PlannerCore

struct SessionForm: View {
    enum Field: Hashable { case minutes }

    let courses: [Course]
    let onAdd: (StudySession) -> Void

    @State private var draft = SessionDraft(date: .now)
    @State private var showProblems = false
    @FocusState private var focused: Field?
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
                if showProblems && draft.problems.contains(.noCourse) {
                    Text("Choose the course this session is for.")
                        .foregroundStyle(.red)
                }
            }
            Section("When and how long") {
                DatePicker("Day", selection: $draft.date, displayedComponents: .date)
                TextField("Minutes", text: $draft.minutesText)
                    .keyboardType(.numberPad)
                    .focused($focused, equals: .minutes)
                if showProblems, let message = minutesMessage {
                    Text(message).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("New session")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", action: add)
            }
        }
    }

    private var minutesMessage: LocalizedStringKey? {
        for problem in draft.problems {
            switch problem {
            case .noMinutes: return "Enter how many minutes."
            case .minutesNotWhole: return "Minutes are a whole number, like 45."
            case .minutesOutOfRange: return "Between 5 and 480 minutes."
            case .noCourse: continue
            }
        }
        return nil
    }

    private func add() {
        if let session = draft.session(id: UUID().uuidString, calendar: calendar) {
            onAdd(session)
            dismiss()
        } else {
            showProblems = true
            if minutesMessage != nil { focused = .minutes }
        }
    }
}
```

**`Field` é um enum mesmo com um caso só**, porque o próximo campo que o formulário ganhar é um segundo
caso e não um segundo `Bool`. A documentação da Apple para o `FocusState` aceita tanto um valor opcional
quanto um `Bool`, e o opcional é o que cresce.

O `showProblems` começa `false` para que um formulário aberto há um instante não esteja já gritando
"digite os minutos" para alguém que nem teve a chance. As mensagens aparecem depois do primeiro toque em
Add e então acompanham a digitação: corrija os minutos e a linha embaixo deles some na tecla seguinte,
porque o `minutesMessage` é calculado a partir do rascunho toda vez que o body roda, como a aula 3
explicou.

## A mensagem é uma frase, na língua da pessoa

O rascunho devolve valores e a tela os transforma em palavras. O `minutesMessage` devolve uma
`LocalizedStringKey`, que é o que um literal de string vira quando esse é o tipo pedido, e o `Text`
procura uma chave no catálogo de strings do app, como o literal embaixo do picker também faz. Então uma
tradução para o português no catálogo chega a um telefone em português sem mudar este código. **Se ele
devolvesse uma `String`, o `Text` mostraria o inglês como está**: a documentação da Apple para o `Text`
diz que uma variável de string é mostrada literalmente e só uma chave é localizada.

**Vermelho não é a mensagem inteira.** Uma pessoa que não distingue o vermelho da cor do texto ainda lê
a frase, e é por isso que há uma. A aula 19 acrescenta o que o VoiceOver diz quando a mensagem aparece,
coisa que esta versão ainda não trata.

## Um foco que segue a ordem do formulário

O `focused = .minutes` só move o foco quando os minutos estão errados. Um curso faltando ganha a sua
mensagem e nenhum foco, porque não se digita num picker e não há teclado a trazer. Com mais campos de
texto a regra se generaliza para "focar o primeiro campo, na ordem da tela, cujo problema está na
lista", que é um laço pelos casos de `Field` na ordem em que o formulário os mostra.
