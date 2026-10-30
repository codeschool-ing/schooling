---
title: Modificadores próprios: uma cadeia com nome
version: 1
---

**Quando a mesma cadeia de modificadores aparece em três telas, ela merece um nome, e o SwiftUI dá
dois jeitos de dar esse nome.** O planner desenha um cartão em volta da `WeekView`, em volta do resumo
no topo da `CourseDetailView` e em volta de uma mensagem de lista vazia: o mesmo padding, o mesmo fundo
arredondado, a mesma fonte no título. Repetir a cadeia três vezes quer dizer três lugares para mudá-la,
e um que vai ser esquecido.

## Um `ViewModifier`

A documentação da Apple para o `ViewModifier` mostra o formato: um tipo com um método,
`body(content:)`, que recebe a view sendo modificada como `content` e devolve aquilo em que embrulhá-la.

```swift
// CardStyle.swift
import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
```

**A extensão é a parte que as pessoas usam.** A documentação a chama de abordagem comum e idiomática: o
`modifier(_:)` aplica o tipo, e um método com o nome do que ele faz deixa toda tela escrever
`WeekView().cardStyle()`. A ordem dentro de `body(content:)` segue as regras da seção 03: padding
primeiro, para o fundo ter espaço dentro.

## Ou uma extensão e mais nada

Quando a cadeia não precisa de estado próprio, uma extensão simples de `View` faz o mesmo trabalho com
um tipo a menos:

```swift
extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}
```

**Escolha o `ViewModifier` quando o modificador precisar de estado**, porque um `ViewModifier` é uma
struct cujo `body` pode declarar `@State` como o de uma view, que a aula 6 apresenta; a extensão simples
não tem onde guardar nada. Para o cartão do planner, qualquer um serve, e o curso usa o primeiro para
que a aula 11 possa acrescentar uma animação a ele.

Como `View`, um tipo que obedece a `ViewModifier` na própria declaração roda no main actor, diz a
documentação da Apple. Nada nesta seção foi executado para o curso; ela foi escrita a partir da
documentação da Apple para `ViewModifier` e `modifier(_:)`, lida em 30 de outubro de 2026.
