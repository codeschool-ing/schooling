---
title: O protocolo App, e o programa que nunca retorna
version: 1
---

**Um app SwiftUI é um valor que descreve o app, e o SwiftUI é o programa que o roda.** É o contrário
do `week` da aula 1, em que o `main.swift` rodava da primeira à última linha e o processo terminava.
O ponto de entrada de um app descreve o que deve estar na tela, entrega essa descrição ao sistema, e o
sistema mantém o processo vivo, desenhando, reagindo e perguntando de novo, até a pessoa ou o iOS
encerrá-lo.

Este é o ponto de entrada do planner, o arquivo que a aula 1 seção 06 mostrou primeiro. Nada nesta
seção foi executado para o curso; ela foi escrita a partir da documentação da Apple para o `App`,
lida em 30 de outubro de 2026:

```swift
// PlannerApp.swift
import SwiftUI
import PlannerCore

@main
struct PlannerApp: App {
    var body: some Scene {
        WindowGroup {
            CourseListView()
        }
    }
}
```

Três coisas nele carregam o peso.

**`@main` marca o único ponto de entrada do programa.** A documentação da Apple diz que o protocolo
`App` fornece um `main()` padrão que o sistema chama para abrir o app, e que um programa pode ter
exatamente um ponto de entrada entre todos os seus arquivos. No pacote da aula 1, o `week` tinha um
`main.swift` no lugar; um target pode ter um ou outro, nunca os dois.

**`struct PlannerApp: App` é um tipo de valor.** Ele não guarda janela nem tela. O SwiftUI o cria, lê
o `body` dele, e pode ler esse `body` de novo; a aula 3 trata de por que um `body` roda mais de uma vez
e por que isso é barato.

**`var body: some Scene` é uma propriedade computada que devolve cenas, não views.** Uma cena é o
nível de baixo, e a seção 03 trata dela. `some Scene` quer dizer "um tipo específico que obedece a
`Scene`, que o compilador conhece e você não precisa escrever"; a aula 3 seção 03 desmonta o `some`.

## Onde fica o estado que é do app inteiro

Um `App` pode guardar estado que todas as cenas compartilham, porque ele é criado uma vez para a vida
do processo. A documentação da Apple mostra um modelo criado no `App` e entregue às cenas pelo
ambiente. O planner faz exatamente isso a partir da aula 7, quando o plano passa para um modelo
`@Observable`; até lá, o plano é criado mais abaixo, na primeira tela.

## Main actor, por padrão

A documentação da Apple acrescenta uma frase que importa para a aula 15 do curso `swift`: um tipo que
obedece a `App` na própria declaração herda o isolamento `@MainActor` do protocolo. **Toda
propriedade e todo método de `PlannerApp` rodam no main actor**, o que desenha a tela, a não ser que
você diga o contrário. Quase todo código de interface quer exatamente isso. A aula 12 é onde o
planner tem trabalho que não deve acontecer ali, e o tira de lá.
