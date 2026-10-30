---
title: Quente e frio
version: 1
---

Os flows da aula 16 eram frios: uma receita que roda uma vez por coletor, desde o começo, e não faz nada
enquanto ninguém coleta. Isso é certo para ler um registro. É errado para **o estado de uma tela**: o
total da semana existe esteja algo o desenhando ou não, uma tela que abre tarde deve ver o total atual e
não uma reprise de como se chegou a ele, e duas telas que o mostram devem ver o mesmo número, não rodar
dois produtores.

**Um flow quente existe independente dos coletores**: ele tem um valor atual ou um fluxo de eventos, os
coletores vêm e vão, e veem o que está acontecendo a partir do momento em que chegam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l17-hotcold\" aria-label=\"Dois painéis. À esquerda, um Flow frio: dois coletores, cada um com a própria execução do produtor, cada um recebendo 45, 30, 60 desde o começo. À direita, um StateFlow quente: um guardador com um valor atual, 75; um coletor que chega cedo vê toda mudança dali em diante, um coletor que chega tarde recebe 75 na hora e depois as mudanças seguintes, e o guardador existe com ou sem coletores.\"><defs><marker id=\"l17-hotcold-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-hotcold-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">Flow frio</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">StateFlow quente</text><rect x=\"30\" y=\"50\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"90\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">execução do produtor</text><text x=\"90\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45 30 60</text><path d=\"M152 75 L208 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-hotcold-ah-phosphor)\"></path><rect x=\"210\" y=\"50\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">coletor</text><rect x=\"30\" y=\"140\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"90\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">execução do produtor</text><text x=\"90\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45 30 60</text><path d=\"M152 165 L208 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-hotcold-ah-phosphor)\"></path><rect x=\"210\" y=\"140\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">coletor 2</text><text x=\"180\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma execução por coletor, desde o começo</text><rect x=\"420\" y=\"90\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"480\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">valor</text><text x=\"480\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--amber)\">75</text><path d=\"M542 105 L598 70\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-hotcold-ah-amber)\"></path><path d=\"M542 135 L598 170\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-hotcold-ah-amber)\"></path><rect x=\"600\" y=\"45\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"655\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cedo</text><text x=\"655\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">toda mudança</text><rect x=\"600\" y=\"145\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"655\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tarde</text><text x=\"655\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">75, depois mudanças</text><text x=\"540\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">um guardador, com ou sem coletores</text></svg>", "caption": "Um flow frio roda uma vez por coletor; um StateFlow guarda um valor atual que todo coletor divide."}
```

```kotlin
// src/main/kotlin/Hot.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val minutes = MutableStateFlow(0)
    minutes.value = 45
    minutes.value = 75
    println("current: ${minutes.value}")

    val watcher = launch {
        minutes.collect { println("watcher sees $it") }
    }
    delay(50)
    minutes.value = 135
    delay(50)
    minutes.value = 135
    delay(50)
    watcher.cancel()
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=HotKt
current: 75
watcher sees 75
watcher sees 135
```

O valor mudou duas vezes antes de alguém observar, e nada se perdeu com isso: **`minutes.value` sempre
guarda o valor atual**, legível a qualquer momento sem coletar. O observador chegou e recebeu 75 na hora,
o valor atual, não o histórico. Ele viu 135 quando foi definido, e não viu o segundo 135, porque o valor
não tinha mudado.

O observador precisou ser cancelado. **Coletar um flow quente nunca termina sozinho**, porque o flow não
tem fim: sempre há um valor atual e possivelmente outro vindo. É por isso que a aula 16 disse que uma
tela coleta numa corrotina própria, e para quando a tela vai embora.
