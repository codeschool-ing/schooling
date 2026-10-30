---
title: '@Bindable: um binding para o modelo de outra view'
version: 1
---

**Um controle precisa de um `Binding`, e uma referência simples para um objeto observável não consegue
fazer um.** O `TextField` quer `Binding<String>`, o `Toggle` quer `Binding<Bool>`. A aula 6 fez
bindings com `$` numa propriedade `@State` ou `@Binding`; uma view que guarda o modelo como
`let model` não tem `$model` para usar. O `@Bindable` é o wrapper que acrescenta um. Nada nesta seção
foi executado; ela foi escrita a partir da documentação da Apple para o `Bindable`.

A tela da semana do planner deixa a pessoa mudar o `today`, para ver outra semana:

```swift
// WeekView.swift
import SwiftUI
import PlannerCore

struct WeekView: View {
    @Bindable var model: PlannerModel

    var body: some View {
        let week = model.week
        Form {
            TextField("Any day of the week", text: $model.today)
            LabeledContent("Monday", value: week.monday)
            LabeledContent("Planned", value: "\(week.planned) min")
            LabeledContent("Done", value: "\(week.done) min")
        }
        .navigationTitle("This week")
    }
}
```

**O `@Bindable` não é dono nem observa.** Ele guarda a mesma referência que a `let` guardaria, e
acrescenta o valor projetado: `$model.today` é um `Binding<String>` que lê e escreve o `today` do
modelo. Observar continua sendo do Observation, pelo `body` lendo `model.week`. Digitar no campo
escreve `today`, e a primeira cena da seção 03 é o que acontece depois: toda view que leu `today`
desenha de novo.

Uma tela de verdade não deixaria uma pessoa digitar um dia como texto e confiar nele; a aula 10 troca
este campo por um `DatePicker` e confere o que volta antes de chegar ao `mondayOf`, que para o programa
diante de uma string que não é um dia.

**Quando uma view só precisa de um binding por um momento**, dentro do `body`, ela pode fazer um ali em
vez de mudar a propriedade:

```swift
var body: some View {
    @Bindable var model = model
    TextField("Any day of the week", text: $model.today)
}
```

A documentação da Apple mostra essa forma para um modelo que a view leu do ambiente, que é o assunto
da seção 06.
