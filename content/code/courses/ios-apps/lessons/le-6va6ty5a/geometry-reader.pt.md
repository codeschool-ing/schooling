---
title: GeometryReader, e os jeitos mais novos de dimensionar pelo contêiner
version: 1
---

**O `GeometryReader` é a única view que entrega a você a própria proposta.** O conteúdo dele é um
closure que recebe um `GeometryProxy`, de onde você lê o tamanho que foi oferecido ao reader, e você
monta views a partir desse número. A documentação da Apple para o `GeometryReader` acrescenta a metade
que surpreende: ele devolve um tamanho preferido flexível ao pai, o que na prática quer dizer que **ele
ocupa todo o espaço oferecido**, seja do que for que o conteúdo precise.

```swift
GeometryReader { proxy in
    let done = Double(total.done) / Double(max(total.planned, 1))
    Capsule()
        .fill(.tint)
        .frame(width: proxy.size.width * done)
}
.frame(height: 8)
```

Isso é uma barra de progresso para a `WeekView`: uma cápsula tão larga quanto a fração da semana já
feita. **O `.frame(height: 8)` de fora não é enfeite.** Sem ele o reader ocuparia toda a altura que o
`VStack` em volta oferecesse, e a barra empurraria todo o resto para fora da tela.

## Por que ele é o último recurso

Um `GeometryReader` quebra os três passos da seção 02 num sentido: o conteúdo dele não decide nada
sobre o tamanho do reader, então um conteúdo que quer ser pequeno não consegue deixar o reader
pequeno. É fácil acabar com uma tela cheia de readers brigando por espaço, e ele é a view a que a
maioria das respostas na internet recorre primeiro.

Três ferramentas mais novas cobrem quase tudo para o que ele era usado, e cada uma mantém as regras
normais:

| necessidade | ferramenta | desde |
|---|---|---|
| um tamanho que é uma fração da tela ou da área de rolagem | `containerRelativeFrame(_:alignment:)` | iOS 17 |
| mostrar o maior de vários layouts que couber | `ViewThatFits` | iOS 16 |
| um arranjo que nenhuma stack oferece | um tipo que obedece a `Layout` | iOS 16 |

O `containerRelativeFrame` dimensiona uma view em relação ao contêiner mais próximo, que a
documentação da Apple lista como a janela ou a tela, uma pilha de navegação, uma aba, ou uma área de
rolagem. O `ViewThatFits` tenta os filhos em ordem e mostra o primeiro cujo tamanho ideal cabe na
proposta, então uma linha pode recuar de "título, barra e minutos" para "título e minutos" num
telefone estreito. E um `Layout` próprio implementa os dois métodos que a seção 08 modela em Swift
puro: `sizeThatFits`, o segundo passo, e `placeSubviews`, o terceiro.

Nada nesta seção foi executado para o curso; ela foi escrita a partir da documentação da Apple para
`GeometryReader`, `containerRelativeFrame(_:alignment:)`, `ViewThatFits` e `Layout`, lida em 30 de
outubro de 2026. A aritmética da barra de progresso, fração feita vezes largura, é a única parte sem
SwiftUI, e o `max(total.planned, 1)` está ali para que uma semana sem nada planejado divida por um em
vez de zero.
