---
title: O ator principal
version: 1
---

Todo app tem uma thread que desenha a tela e recebe os toques, e nas plataformas da Apple, como no
Android, **a interface só pode ser tocada a partir dessa thread**. Mude um rótulo de qualquer outro
lugar e o resultado é indefinido: uma tela que pisca, ou uma quebra longe da linha que a causou. O
Swift modela essa thread como um ator, o **`MainActor`**, e tudo marcado com `@MainActor` fica isolado
nele exatamente como `minutes` ficava isolado no `WeekTotal`.

O SwiftUI e o UIKit marcam as views e os view controllers com `@MainActor`, então o compilador impede
você de atualizar a tela a partir de uma tarefa em segundo plano. Nenhum dos dois frameworks existe no
Linux, e esta aula não os roda. O que ela pode rodar é a regra em si, numa classe própria fazendo o
papel de uma tela:

```swift
// Screen.swift
@MainActor
final class WeekScreen {
    var title = "This week"
    func show() { print("screen: \(title)") }
}

func loadTitle() async -> String {
    try? await Task.sleep(for: .milliseconds(100))
    return "135 of 300 minutes"
}

func refreshFromAnywhere(_ screen: WeekScreen) async {
    let title = await loadTitle()
    screen.title = title
}
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Screen.swift -o screen
Screen.swift:15:12: error: main actor-isolated property 'title' can not be mutated from a nonisolated context
 2 | @MainActor
 3 | final class WeekScreen {
 4 |     var title = "This week"
   |         `- note: mutation of this property is only permitted within the actor
 5 |     func show() { print("screen: \(title)") }
 6 | }
   :
13 | func refreshFromAnywhere(_ screen: WeekScreen) async {
14 |     let title = await loadTitle()
15 |     screen.title = title
   |            |- error: main actor-isolated property 'title' can not be mutated from a nonisolated context
   |            `- note: consider declaring an isolated method on 'MainActor' to perform the mutation
16 | }
17 | 
```

O `refreshFromAnywhere` não está isolado em ator nenhum, o que o compilador chama de **nonisolated**,
então pode rodar em qualquer thread, e o título pertence ao ator principal. Recusado, com uma nota que
aponta o conserto: fazer a mudança em código isolado no ator principal.

```swift
// ScreenFixed.swift
@MainActor
final class WeekScreen {
    var title = "This week"
    func show() { print("screen: \(title)") }
}

func loadTitle() async -> String {
    try? await Task.sleep(for: .milliseconds(100))
    return "135 of 300 minutes"
}

@MainActor
func refresh(_ screen: WeekScreen) async {
    let title = await loadTitle()
    screen.title = title
    screen.show()
}

let screen = WeekScreen()
await refresh(screen)
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 ScreenFixed.swift -o screenfixed && ./screenfixed
screen: 135 of 300 minutes
```

**O `refresh` é `@MainActor`, então roda no ator principal e pode tocar a tela diretamente.** A parte
lenta, `loadTitle`, é nonisolated e roda onde o sistema a puser; no `await` o ator principal fica livre
para desenhar e responder a toques, e quando o título chega o `refresh` retoma no ator principal para
defini-lo. Esse é o formato de quase toda atualização de tela num app: carregar longe do ator
principal, e então definir nele.

O nível de cima de um programa também roda no ator principal, e por isso os dois erros da seção 03 o
mencionaram, e por isso `let screen = WeekScreen()` no nível de cima não precisou de `await`.

## Uma Task herda o seu ator, e uma tarefa destacada não

A aula 14 prometeu uma diferença entre `Task { … }` e `Task.detached { … }`. Aqui está ela, num
tratador de botão que roda no ator principal, como os tratadores rodam:

```swift
// Inherit.swift
@MainActor
final class WeekScreen {
    var title = "This week"
}

@MainActor
func buttonTapped(_ screen: WeekScreen) {
    Task {
        screen.title = "refreshing"
    }
    Task.detached {
        screen.title = "refreshing"
    }
}
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Inherit.swift -o inherit
Inherit.swift:13:16: error: main actor-isolated property 'title' can not be mutated from a nonisolated context
 2 | @MainActor
 3 | final class WeekScreen {
 4 |     var title = "This week"
   |         `- note: mutation of this property is only permitted within the actor
 5 | }
 6 | 
   :
11 |     }
12 |     Task.detached {
13 |         screen.title = "refreshing"
   |                |- error: main actor-isolated property 'title' can not be mutated from a nonisolated context
   |                `- note: consider declaring an isolated method on 'MainActor' to perform the mutation
14 |     }
15 | }
```

**Só a tarefa destacada é recusada.** Uma `Task` comum iniciada no ator principal roda no ator
principal, então o corpo dela pode definir o título como o próprio `buttonTapped` pode. Uma tarefa
destacada não herda nada e é nonisolated, então a mesma linha é uma mudança vinda de um contexto não
isolado. Essa herança é o que faz da `Task { … }` a ponte certa a partir de um tratador, e o motivo de
`Task.detached` raramente ser o que você quer.
