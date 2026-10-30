---
title: A ordem importa, porque cada embrulho só vê o que está dentro dele
version: 1
---

**`.padding().background(.yellow)` e `.background(.yellow).padding()` desenham coisas diferentes.** O
primeiro pinta amarelo atrás do texto com padding, então o amarelo passa das palavras por todos os
lados. O segundo pinta amarelo atrás só do texto, e depois acrescenta espaço vazio em volta do amarelo.
As palavras são as mesmas e a tela não é.

```swift
VStack(spacing: 24) {
    Text("50 min")
        .padding()
        .background(.yellow)

    Text("50 min")
        .background(.yellow)
        .padding()
}
```

O motivo é o embrulho da seção 02, lido de dentro para fora. Um fundo tem exatamente o tamanho da view
que embrulha. **Na primeira cadeia ele embrulha o padding**, então é tão grande quanto o texto mais o
padding. **Na segunda ele embrulha o texto**, então é tão grande quanto o texto, e o padding de fora
acrescenta um espaço que nada pinta. A seção 08 passa as mesmas duas cadeias por um modelo em Swift
puro e imprime o tamanho que cada camada informa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l05-order\" aria-label=\"Duas cadeias lado a lado, cada uma desenhada como caixas aninhadas. À esquerda, texto, depois padding, depois fundo: a caixa do fundo, em âmbar, é a de fora, 80 por 52, e o padding e o texto ficam dentro dela. À direita, texto, depois fundo, depois padding: a caixa de fora é o padding, 80 por 52, sem pintura; a caixa âmbar do fundo dentro dela tem só 48 por 20, o tamanho do texto.\"><defs><marker id=\"l05-order-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l05-order-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l05-order-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l05-order-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"50\" width=\"290\" height=\"150\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"100\" y=\"90\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"185\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">50 min</text><text x=\"185\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fora: 80 por 52</text><rect x=\"390\" y=\"50\" width=\"290\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"450\" y=\"90\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"535\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">50 min</text><text x=\"535\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fora: 80 por 52</text><text x=\"185\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.padding().background(.yellow)</text><text x=\"535\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.background(.yellow).padding()</text><text x=\"185\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fundo: 80 por 52</text><text x=\"185\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">padding dentro</text><text x=\"535\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">padding: nada pintado</text><text x=\"535\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fundo: 48 por 20</text></svg>", "caption": "As mesmas três peças em duas ordens. O fundo tem o tamanho do que embrulha, então a ordem decide quanto amarelo existe."}
```

## Três ordens que vale saber de cor

| cadeia | o que você ganha |
|---|---|
| `.padding()` e depois `.background(…)` | uma caixa colorida com espaço em volta do conteúdo |
| `.background(…)` e depois `.clipShape(…)` | o fundo cortado na forma também, cantos arredondados e tudo |
| `.frame(width: 200)` e depois `.background(…)` | a cor preenche o frame inteiro de 200 pontos |
| `.background(…)` e depois `.frame(width: 200)` | a cor abraça o conteúdo, que fica centralizado num frame de 200 pontos sem cor |

**Uma área de toque segue a mesma regra.** Um `.onTapGesture` posto antes do `.padding()` responde só
no conteúdo; posto depois, responde na área com padding também. Um botão de rótulo pequeno com o
padding fora do gesto é o clássico "toquei e não aconteceu nada".

Nada nesta seção foi executado para o curso. As listagens foram escritas a partir da documentação da
Apple para `padding(_:_:)`, `background(_:ignoresSafeAreaEdges:)` e `frame(width:height:alignment:)`,
lida em 30 de outubro de 2026, e nenhuma captura de tela aparece, porque nenhuma foi tirada.
