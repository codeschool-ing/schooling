---
title: Sequências preguiçosas
version: 1
---

O `map` e o `filter` montam um array novo inteiro a cada chamada. Em geral é isso que você quer. É
desperdício quando você só precisa do primeiro resultado que serve, ou quando a coleção é muito grande
ou não tem fim. **O `.lazy` inverte a cadeia: nada roda até que um valor seja pedido, e então só o
quanto esse valor precisa.**

```swift
// Lazy.swift
let sessions = [45, 30, 60, 20, 50]
let eager = sessions
    .map { minutes -> Int in
        print("eager map \(minutes)")
        return minutes * 60
    }
    .first { $0 > 3000 }
print(eager ?? 0)
let lazy = sessions.lazy
    .map { minutes -> Int in
        print("lazy map \(minutes)")
        return minutes * 60
    }
    .first { $0 > 3000 }
print(lazy ?? 0)
```

```
ana@vm:~/sw/l04$ swift Lazy.swift
eager map 45
eager map 30
eager map 60
eager map 20
eager map 50
3600
lazy map 45
lazy map 30
lazy map 60
3600
```

As duas cadeias acham a primeira sessão com mais de 3.000 segundos, que é a de 60 minutos, com 3.600.
A cadeia ansiosa converteu **as cinco** sessões para segundos e depois procurou no resultado. A cadeia
preguiçosa converteu 45, olhou, converteu 30, olhou, converteu 60 e parou: **três** chamadas, porque o
`first` já tinha a resposta. O `print` dentro de cada closure é o que torna a diferença visível; numa
lista de cinco não custa nada, e numa lista de um milhão lida de um arquivo é a maior parte do
trabalho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l04-lazy\" aria-label=\"Duas linhas de cinco sessões, de 45, 30, 60, 20 e 50 minutos. Linha de cima, ansiosa: as cinco são convertidas para segundos, e depois o first acha 3600. Linha de baixo, preguiçosa: 45 é convertida e conferida, depois 30, depois 60, que passa, e as duas restantes nunca são convertidas.\"><text x=\"60\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">ansiosa</text><text x=\"60\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">preguiçosa</text><rect x=\"130\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">45 × 60</text><rect x=\"130\" y=\"140\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">45 × 60</text><rect x=\"225\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">30 × 60</text><rect x=\"225\" y=\"140\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">30 × 60</text><rect x=\"320\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">60 × 60</text><rect x=\"320\" y=\"140\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">60 × 60</text><rect x=\"415\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"455\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">20 × 60</text><rect x=\"415\" y=\"140\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"455\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><rect x=\"510\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">50 × 60</text><rect x=\"510\" y=\"140\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"550\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">50</text><text x=\"640\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">first { $0 &gt; 3000 }</text><text x=\"355\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">primeiro acerto</text><text x=\"560\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca convertidas</text></svg>", "caption": "A ansiosa converte tudo e depois procura; a preguiçosa converte uma por vez e para no primeiro acerto."}
```

As closures aqui escrevem o tipo do resultado, `minutes -> Int in`. O Swift o teria inferido pelo
`return`; ele está escrito para que cada passo da cadeia diga o que produz.

## Uma sequência sem fim

A preguiça também permite descrever uma sequência que nunca acaba e pegar só o que você precisa:

```swift
// Endless.swift
let goals = (1...).lazy
    .map { week in 300 + 15 * (week - 1) }
    .prefix(4)
print(Array(goals))
```

```
ana@vm:~/sw/l04$ swift Endless.swift
[300, 315, 330, 345]
```

`1...` é um intervalo sem limite superior. Ansioso, o `map` tentaria montar um array infinito e nunca
retornaria. Preguiçoso, é uma descrição, e o `prefix(4)` pega quatro valores dela: uma meta que sobe
15 minutos por semana nas quatro primeiras semanas. O `Array(…)` é o momento em que os valores são
calculados de fato.

**Use `lazy` quando você para cedo ou a entrada é grande**, e deixe de fora no resto: para um array
curto usado inteiro, ele só acrescenta um passo e um tipo menos óbvio. O `some Sequence` da aula 9 é
a ferramenta para esconder esse tipo quando uma função devolve um.
