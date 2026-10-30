---
title: Operadores: map, filter, take e onEach
version: 1
---

Um flow tem os operadores das coleções da lição 5, com os mesmos nomes e as mesmas lambdas. **Cada
operador devolve um flow novo e não roda nada**; a corrente descreve o que vai acontecer com cada valor,
e o `collect` no fim faz acontecer, um valor por vez pela corrente inteira.

```kotlin
// src/main/kotlin/FlowOps.kt
import kotlinx.coroutines.flow.asFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    listOf(45, 20, 60, 30, 90).asFlow()
        .onEach { println("  saw $it") }
        .filter { it >= 30 }
        .map { "$it min" }
        .take(2)
        .collect { println(it) }
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowOpsKt
  saw 45
45 min
  saw 20
  saw 60
60 min
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l16-pipeline\" aria-label=\"Um pipeline de flow desenhado da esquerda para a direita: a fonte 45, 20, 60, 30, 90, depois onEach, filter it &gt;= 30, map para texto, take(2) e collect. Cada valor passa por todos os passos antes de o próximo começar. O 45 chega ao collect. O 20 para no filter. O 60 chega ao collect, o take tem os dois valores e cancela a fonte, então 30 e 90 nunca são emitidos.\"><defs><marker id=\"l16-pipeline-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l16-pipeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"14\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">asFlow()</text><rect x=\"132\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"182\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">onEach</text><path d=\"M116 58 L130 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><rect x=\"250\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">filter ≥ 30</text><path d=\"M234 58 L248 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><rect x=\"368\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"418\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">map</text><path d=\"M352 58 L366 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><rect x=\"486\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"536\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">take(2)</text><path d=\"M470 58 L484 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><rect x=\"604\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"654\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">collect</text><path d=\"M588 58 L602 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><text x=\"40\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">45</text><path d=\"M70 104 L654 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-phosphor)\"></path><text x=\"40\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><path d=\"M70 132 L300 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><text x=\"40\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">60</text><path d=\"M70 160 L654 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-phosphor)\"></path><text x=\"40\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">30  90</text><text x=\"600\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">impresso</text><text x=\"370\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">parado pelo filtro</text><text x=\"600\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">segundo valor: fonte cancelada</text><text x=\"250\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">nunca emitidos</text></svg>", "caption": "Um valor por vez pela corrente inteira; o take(2) cancela a fonte quando tem os dois."}
```

O `asFlow()` transforma uma lista num flow. Siga os valores: o 45 passou por todos os passos e foi
impresso; o 20 foi visto e barrado pelo filtro; o 60 passou e era o segundo valor que o `take(2)` queria.
**Então o flow parou**: 30 e 90 nem foram vistos. O `take` cancela o produtor quando tem a quantidade
dele, usando o cancelamento da lição 15, então um flow que lê um arquivo grande para de lê-lo.

O `onEach` roda um efeito colateral e passa o valor adiante sem mudança, a versão de flow do `also` da
lição 6. Posto primeiro, ele mostra exatamente quais valores o produtor emitiu.

## Os operadores rodam as lambdas como código suspenso

As lambdas de `map`, `filter` e `onEach` num flow podem suspender: `map { loadDetails(it) }` chama uma
função suspensa para cada valor. **Essa é a diferença para uma sequência**, e é o que deixa um pipeline
de flow ler de um arquivo, chamar um servidor ou esperar entre passos sem mudar de forma.

O `transform` é o operador geral por baixo da maioria deles: a lambda dele recebe cada valor e pode
emitir nenhum, um ou vários valores adiante. O `map` é um `transform` que emite uma vez, e o `filter`
um que emite zero ou uma vez.
