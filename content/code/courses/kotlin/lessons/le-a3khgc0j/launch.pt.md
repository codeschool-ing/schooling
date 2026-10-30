---
title: launch, e corrotinas que rodam lado a lado
version: 1
---

O `runBlocking` inicia uma corrotina. **O `launch` inicia outra dentro dela, e retorna na hora**, sem
esperar a nova corrotina terminar. Duas corrotinas então se revezam na mesma thread, cada uma rodando
até suspender.

```kotlin
// src/main/kotlin/Launch.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val reminder = launch {
        repeat(3) { i ->
            println("reminder ${i + 1}: study Kotlin")
            delay(100)
        }
    }
    println("planner open")
    delay(150)
    println("still in main, reminder active: ${reminder.isActive}")
    reminder.join()
    println("reminder finished: ${reminder.isCompleted}")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=LaunchKt
planner open
reminder 1: study Kotlin
reminder 2: study Kotlin
still in main, reminder active: true
reminder 3: study Kotlin
reminder finished: true
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l14-interleave\" aria-label=\"Uma linha do tempo de 0 a 300 milissegundos com duas linhas que dividem uma thread. A corrotina main imprime planner open em 0, suspende em delay(150), imprime still in main em 150, depois espera no join. A corrotina reminder imprime reminder 1 em 0, reminder 2 em 100 e reminder 3 em 200, suspendendo em delay(100) entre elas. Sempre que uma está suspensa, a thread roda a outra.\"><defs><marker id=\"l14-interleave-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"60\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">main</text><text x=\"60\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">reminder</text><path d=\"M120 190 L680 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"120.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 ms</text><text x=\"306.66666666666663\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100 ms</text><text x=\"400.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150 ms</text><text x=\"493.3333333333333\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200 ms</text><text x=\"680.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300 ms</text><rect x=\"120.0\" y=\"55\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"400.0\" y=\"55\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"444.0\" y=\"62\" width=\"236.0\" height=\"16\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"562.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">join()</text><rect x=\"164.0\" y=\"62\" width=\"232.0\" height=\"16\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"280.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">delay(150)</text><rect x=\"120.0\" y=\"125\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"306.66666666666663\" y=\"125\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"493.3333333333333\" y=\"125\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"164.0\" y=\"132\" width=\"138.66666666666663\" height=\"16\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"233.33333333333331\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">delay(100)</text><rect x=\"350.66666666666663\" y=\"132\" width=\"138.66666666666663\" height=\"16\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"420.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">delay(100)</text><text x=\"400\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper)\">uma thread: roda quem não está suspenso</text></svg>", "caption": "Duas corrotinas numa thread: cada uma roda até suspender num delay, e a outra pega a thread."}
```

Leia a saída junto com o código. O `launch` retornou antes de o bloco dele imprimir qualquer coisa,
então `planner open` veio primeiro. Depois o `main` suspendeu em `delay(150)`, o lembrete rodou até o
próprio `delay`, o delay do `main` terminou entre a segunda e a terceira linha do lembrete, e **em cada
`delay` a thread foi para a corrotina que estava pronta**. Nenhuma segunda thread entrou: o
entrelaçamento são os pontos de suspensão se revezando.

## O `Job`

O `launch` devolve um `Job`, um controle da corrotina que ele iniciou. `isActive` e `isCompleted` dizem
onde ela está; **o `join()` suspende até ela terminar**, que é como o `main` esperou o terceiro
lembrete antes de imprimir a última linha. O `cancel()` a para, e a aula 15 é sobre o que acontece
então.

## O `runBlocking` espera os filhos

Tire o `join()`, e a última linha é impressa antes do terceiro lembrete, mas o programa ainda imprime o
terceiro lembrete antes de terminar. **O `runBlocking` não retorna até toda corrotina iniciada dentro
dele ter terminado.** Essa regra, de que uma corrotina espera as corrotinas que iniciou, é a
concorrência estruturada, e a aula 15 é construída sobre ela.
