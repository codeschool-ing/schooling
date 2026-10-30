---
title: A sequence que é preguiçosa
version: 1
---

Uma corrente sobre uma lista é **ansiosa**: o `filter` percorre a lista inteira e monta uma nova,
depois o `map` percorre essa e monta outra. Uma **sequência** é preguiçosa: nada acontece até algo
pedir um resultado, e então cada item passa por todos os passos antes de o próximo item começar. As
duas dão a mesma resposta e fazem o trabalho em ordem diferente, e a ordem é toda a diferença.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l05-lazy\" aria-label=\"A mesma corrente, filter, depois map, depois first, sobre 45, 30, 60, 20. À esquerda, uma lista: o filter roda nos quatro itens e monta uma lista de três, o map roda nos três e monta outra lista, depois o first pega 90; sete chamadas de lambda. À direita, uma sequência: o 45 passa pelo filter, depois pelo map, e o first tem a resposta, 90; duas chamadas de lambda, e 30, 60 e 20 nunca são tocados.\"><defs><marker id=\"l05-lazy-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"180\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">lista: ansiosa, passo a passo</text><text x=\"540\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">sequência: preguiçosa, item a item</text><rect x=\"40\" y=\"44\" width=\"280\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">filter: 45  30  60  20</text><path d=\"M180 86 L180 104\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-lazy-ah-amber)\"></path><rect x=\"40\" y=\"106\" width=\"280\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">map: 45  30  60</text><path d=\"M180 148 L180 166\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-lazy-ah-amber)\"></path><rect x=\"40\" y=\"168\" width=\"280\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">first: 90</text><text x=\"180\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">7 chamadas, 2 listas montadas</text><rect x=\"400\" y=\"44\" width=\"280\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45: filter → map → first</text><text x=\"540\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o first tem a resposta: 90</text><rect x=\"400\" y=\"140\" width=\"280\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30  60  20</text><text x=\"540\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nunca tocados</text><text x=\"540\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">2 chamadas, nenhuma lista montada</text></svg>", "caption": "A mesma resposta, duas ordens de trabalho. Uma lista termina cada passo antes do seguinte; uma sequência termina cada item antes do seguinte, e para quando a resposta é conhecida."}
```

O jeito mais claro de ver a ordem é fazer cada passo dizer quando roda:

```kotlin
// Lazy.kt
fun main() {
    val minutes = listOf(45, 30, 60, 20)

    println("list:")
    val a = minutes
        .filter { println("  filter $it"); it >= 30 }
        .map { println("  map $it"); it * 2 }
        .first()
    println("first = $a")

    println("sequence:")
    val b = minutes.asSequence()
        .filter { println("  filter $it"); it >= 30 }
        .map { println("  map $it"); it * 2 }
        .first()
    println("first = $b")
}
```

```
ana@vm:~/kt/l05$ kotlinc Lazy.kt -include-runtime -d lazy.jar && java -jar lazy.jar
list:
  filter 45
  filter 30
  filter 60
  filter 20
  map 45
  map 30
  map 60
first = 90
sequence:
  filter 45
  map 45
first = 90
```

A lista filtrou os quatro itens, depois transformou os três que passaram, depois pegou o primeiro. **A
sequência filtrou um item, transformou-o e parou**, porque o `first()` já tinha a resposta. Duas
chamadas contra sete, e a diferença cresce com a lista.

## Nada acontece sem uma operação terminal

`filter` e `map` numa sequência devolvem outra sequência e não executam nada. Só uma operação
terminal, uma que devolve algo que não é sequência, faz o trabalho acontecer: `first`, `toList`,
`sum`, `count`, `forEach`. Uma corrente de sequência sem operação terminal não faz nada, e o
compilador não avisa.

## Sequências podem ser infinitas

Como nada é calculado até ser pedido, uma sequência descreve mais itens do que poderiam existir:

```kotlin
// Infinite.kt
fun main() {
    val doubling = generateSequence(15) { it * 2 }
    println(doubling.take(5).toList())
    println(doubling.first { it > 1000 })
}
```

```
ana@vm:~/kt/l05$ kotlinc Infinite.kt -include-runtime -d infinite.jar && java -jar infinite.jar
[15, 30, 60, 120, 240]
1920
```

`generateSequence(15) { it * 2 }` é 15, 30, 60, e assim por diante sem fim. `take(5)` e
`first { … }` pedem uma parte finita dela, e só essa parte é calculada.

## Quando usar uma

**Uma lista é o padrão, e uma sequência é para uma corrente longa sobre uma coleção grande, ou uma
fonte sem fim.** Para algumas dezenas de itens, as listas intermediárias custam menos que a maquinaria
da sequência, e uma lista é mais fácil de depurar, porque cada passo pode ser impresso inteiro. O
`Flow` da aula 16 é a mesma ideia estendida a valores que chegam ao longo do tempo, e ele é frio, a
palavra da aula 16 para preguiçoso.
