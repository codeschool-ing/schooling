---
title: Três jeitos de o estado dar errado
version: 1
---

**A maioria dos bugs de `@State` é um de três, e cada um parece o SwiftUI ignorando você.** Nenhum é.
Cada um decorre dos dois fatos da seção 03: a struct é refeita a cada atualização do pai, e o
armazenamento é guardado pelo SwiftUI e inicializado uma vez. Nada aqui foi executado para o curso; o
comportamento descrito é o que a documentação da Apple para o `State` dá.

## O valor inicial que nunca atualiza

```swift
struct WeekView: View {
    @State private var plan: Plan
    init(plan: Plan) { _plan = State(initialValue: plan) }
    var body: some View {
        let total = plan.weekTotal(today: "2026-10-21")
        Text("\(total.done) of \(total.planned) minutes")
    }
}
```

O pai passa um plano e, mais tarde, passa outro. A struct nova roda o inicializador com o plano novo,
e **o SwiftUI mantém o armazenamento que já tinha**, porque a view continua na tela e o estado dela
sobrevive. O texto mostra os números do plano antigo. A correção não é fazer desta view a dona: se o
pai é o dono do plano, a filha recebe `let plan: Plan` para lê-lo, ou `@Binding var plan: Plan` para
mudá-lo. O `@State` é para estado que nasce com a view e pertence a ela, como se uma seção está
aberta ou o que foi digitado num campo antes de ser salvo.

## Dois donos de um fato

Um pai com `@State var plan` e uma filha com o seu próprio `@State var plan`, inicializado a partir do
do pai, têm dois planos. As mudanças da filha ficam na filha. O sintoma é uma tela que mostra uma
mudança, e uma tela atrás dela que não a tem quando você volta. A pergunta a fazer a todo `@State` é
**quem mais precisa deste valor**; se a resposta for alguém, o estado pertence a um nível acima, e os
outros recebem um binding ou um valor simples.

## Uma classe em `@State`

```swift
final class Draft { var minutes = 30 }

struct SessionForm: View {
    @State private var draft = Draft()
    var body: some View {
        Stepper("\(draft.minutes) minutes", value: Binding(get: { draft.minutes }, set: { draft.minutes = $0 }))
    }
}
```

O stepper escreve `draft.minutes`, e o número na tela não se mexe. O `@State` observa o seu valor, e o
valor é uma referência para o objeto; mudar uma propriedade do objeto deixa a referência igual, então
nada avisa o SwiftUI para rodar o `body` de novo. **Guarde tipos de valor em `@State`,** uma
`struct Draft`, e o mesmo código funciona. Uma classe que o SwiftUI consegue observar é o
`@Observable` da aula 7.

Os três têm a mesma cura: decidir qual view é dona do valor, dar-lhe `@State` ali, e dar a todos os
outros um valor para ler ou um binding para escrever.
