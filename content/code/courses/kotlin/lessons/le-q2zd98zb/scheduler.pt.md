---
title: O agendador do teste decide quando as corrotinas rodam
version: 1
---

O `WeekModel` da aula 17 lança o trabalho num escopo que recebe. Num teste esse escopo é o próprio
teste: o `runTest` entrega `this`, e toda corrotina lançada nele roda no **agendador do teste**, que não
roda nada até o teste deixar. É esse o ponto. O teste pode olhar o estado entre quaisquer dois passos do
trabalho, no momento em que uma tela de verdade o teria desenhado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l18-scheduler\" aria-label=\"Um relógio virtual de 0 a 200 milissegundos. Em 0, o refresh põe na fila o trabalho lançado e o estado é Loading. O advanceTimeBy(199) roda o trabalho, que começa o delay de 200 da fonte, e move o relógio para 199; o estado ainda é Loading. O advanceUntilIdle move o relógio para 200, onde a fonte retorna e o estado vira Loaded. Nenhum tempo real passa.\"><defs><marker id=\"l18-scheduler-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-scheduler-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l18-scheduler-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">o relógio do teste, em milissegundos virtuais</text><path d=\"M60 120 L660 120\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60 114 L60 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M630 114 L630 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M660 114 L660 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><text x=\"624\" y=\"142\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">199</text><text x=\"666\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><rect x=\"30\" y=\"46\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">refresh()</text><text x=\"115\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">trabalho na fila: Loading</text><path d=\"M115 96 L115 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"250\" y=\"46\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"365\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">advanceTimeBy(199)</text><text x=\"365\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fonte começa delay(200): Loading</text><path d=\"M480 71 L630 71 L630 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-scheduler-ah-wire)\"></path><rect x=\"470\" y=\"168\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">advanceUntilIdle()</text><text x=\"585\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fonte retorna: Loaded</text><path d=\"M660 166 L660 124\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-scheduler-ah-amber)\"></path><text x=\"60\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nenhum tempo real passa</text></svg>", "caption": "O teste move o relógio: o trabalho espera na fila até o teste rodá-lo, e o delay acaba quando o teste diz."}
```

```kotlin
// src/test/kotlin/SchedulerTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class SchedulerTest {
    @Test
    fun launchWaitsItsTurn() = runTest {
        val model = WeekModel(this) { listOf(45, 30) }
        model.refresh()
        assertEquals(WeekUi.Loading, model.state.value)
        runCurrent()
        assertEquals(WeekUi.Loaded(listOf(45, 30)), model.state.value)
    }

    @Test
    fun timeMovesWhenTheTestSays() = runTest {
        val model = WeekModel(this) {
            delay(200)
            listOf(45, 30)
        }
        model.refresh()
        advanceTimeBy(199)
        assertEquals(WeekUi.Loading, model.state.value)
        advanceUntilIdle()
        assertEquals(WeekUi.Loaded(listOf(45, 30)), model.state.value)
        assertEquals(200, currentTime)
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests SchedulerTest
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :compileKotlin UP-TO-DATE
> Task :compileJava NO-SOURCE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :compileTestKotlin
> Task :compileTestJava NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test

SchedulerTest > timeMovesWhenTheTestSays() PASSED

SchedulerTest > launchWaitsItsTurn() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

No primeiro teste a fonte responde na hora, e o estado ainda era `Loading` depois do `refresh()`. **O
`launch` pôs o trabalho na fila e retornou; nada o rodou até o `runCurrent()`**, que roda toda tarefa
vencida no instante atual. O segundo teste move o relógio à mão: aos 199 milissegundos a fonte ainda
está esperando, e o `advanceUntilIdle()` roda tudo o que falta, o que terminou em 200.

| chamada | roda |
|---|---|
| `runCurrent()` | o que vence agora, sem mover o relógio |
| `advanceTimeBy(ms)` | o que vence antes de `agora + ms`, e move o relógio até lá |
| `advanceUntilIdle()` | tudo, movendo o relógio o quanto for preciso |

As três estão entre as chamadas experimentais da seção 05, então a classe traz o mesmo `@OptIn`.
