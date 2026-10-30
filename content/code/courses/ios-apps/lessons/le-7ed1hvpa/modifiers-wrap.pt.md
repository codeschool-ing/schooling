---
title: Um modificador devolve uma view nova que embrulha a antiga
version: 1
---

**Um modificador não muda a view em que é chamado. Ele devolve uma view nova com a antiga dentro.** A
documentação da Apple para `View` diz isso com todas as letras: os modificadores funcionam embrulhando
a instância de view em que você os chama numa outra view com as características indicadas. Então
`Text("50 min").padding()` não é um texto com padding ajustado; é uma view de padding cujo conteúdo é
um texto.

Parece um detalhe, e é a chave de todo o resto desta aula, porque cada embrulho é um **participante do
layout** por direito próprio. A aula 4 seção 04 já encontrou um: um frame é uma view nova em volta da
antiga, com o seu próprio tamanho. O padding é outro, um fundo é outro, e a cadeia

```swift
Text("50 min")
    .padding()
    .background(.yellow)
    .frame(maxWidth: .infinity, alignment: .trailing)
```

são quatro views, aninhadas como caixas: um frame, segurando um fundo, segurando um padding,
segurando um texto. **Leia uma cadeia de cima para baixo para saber o que está dentro do quê**: o
primeiro modificador é o embrulho mais de dentro e o último, o mais de fora.

## Por que o SwiftUI é feito assim

Como uma view é um valor, como disse a aula 3 seção 02, não há nada em que ajustar uma propriedade. Um
modificador precisa produzir um valor novo, e o valor novo mais barato que muda uma coisa é uma struct
pequena que guarda a view antiga e essa coisa. O tipo do resultado registra a cadeia inteira, e é assim
que o SwiftUI compara a próxima descrição com esta, do mesmo jeito que a aula 3 seção 07 mostrou para
um `if`.

**Duas consequências decorrem disso, e elas são as duas próximas seções.** A ordem da cadeia muda o
resultado, porque cada embrulho só vê o que está dentro dele (seção 03). E dois modificadores que
parecem iguais podem ser embrulhos diferentes, com layouts diferentes (seção 04).

Nada nesta seção foi executado para o curso. A seção 08 constrói os mesmos embrulhos em Swift puro,
imprime os tipos deles, e roda.
