---
title: Alinhamento: quais bordas, e quais linhas de base, se alinham
version: 1
---

**O `alignment` de uma stack alinha os filhos ao longo do eixo em que ela não empilha.** Um `VStack`
alinha na horizontal (`.leading`, `.center`, `.trailing`) e um `HStack` na vertical (`.top`,
`.center`, `.bottom`, e dois que importam para texto, `.firstTextBaseline` e `.lastTextBaseline`). O
padrão é `.center` para os dois.

A linha de curso do planner, da seção 03, mostra por que as linhas de base existem. À esquerda, um
título na fonte de cabeçalho sobre uma legenda; à direita, os minutos na fonte do corpo.
Centralizados, os minutos ficam a meio caminho entre as duas linhas da esquerda, sem bater com
nenhuma. **Alinhados pela primeira linha de base do texto, os minutos ficam na mesma linha do
título**, que é o que o olho de quem lê espera:

```swift
HStack(alignment: .firstTextBaseline) {
    VStack(alignment: .leading) {
        Text(course.title).font(.headline)
        Text("this week").font(.caption)
    }
    Spacer()
    Text("\(minutes) min")
}
```

Uma linha de base é a linha em que as letras se apoiam, então alinhar linhas de base alinha textos de
tamanhos diferentes como a imprensa faz. Alinhar por `.top` alinharia os topos das duas caixas, e uma
fonte maior tem mais espaço acima das letras, então as palavras não ficariam exatamente na mesma
linha.

## Alinhamento dentro de um frame e dentro de um ZStack

`frame(width:height:alignment:)` e `ZStack(alignment:)` recebem um `Alignment`, que nomeia os dois
eixos de uma vez: `.topLeading`, `.bottomTrailing`, `.center` e assim por diante. Num frame ele diz
onde fica um filho menor; num `ZStack` ele diz como as camadas se alinham, então um selo num
`ZStack(alignment: .topTrailing)` fica no canto superior direito do ícone embaixo dele.

## Alinhando entre contêineres

Às vezes duas views em stacks diferentes precisam dividir uma linha, como os dois-pontos de uma coluna
de rótulos. A resposta do SwiftUI é uma guia de alinhamento personalizada, um tipo que obedece a
`AlignmentID`, aplicada com `.alignmentGuide(_:computeValue:)`. Ela é citada para você reconhecê-la; o
planner nunca precisa de uma, e nada aqui constrói uma.

Nada nesta seção foi executado para o curso. Ela foi escrita a partir da documentação da Apple para
`HStack`, `VerticalAlignment`, `Alignment` e `alignmentGuide(_:computeValue:)`, lida em 30 de outubro
de 2026.
