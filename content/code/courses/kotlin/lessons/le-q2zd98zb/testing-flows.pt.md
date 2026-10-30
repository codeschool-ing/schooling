---
title: Testando flows
version: 1
---

Um flow frio que termina é o caso fácil: colete-o numa lista e compare a lista. Aqui está uma função
para o total acumulado do planejador, escrita em `src/main`, e um teste dela:

```kotlin
// src/main/kotlin/Totals.kt
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.runningFold

fun runningTotals(sessions: Flow<Int>): Flow<Int> =
    sessions.runningFold(0) { total, m -> total + m }.drop(1)
```

Um `StateFlow` nunca termina, então `toList()` nele nunca retornaria. O teste o coleta em segundo plano,
numa lista que ele consegue ler, e deixa de se importar quando o teste acaba:

```kotlin
// src/test/kotlin/FlowTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class FlowTest {
    @Test
    fun totalsRunAlong() = runTest {
        assertEquals(listOf(45, 75, 135), runningTotals(flowOf(45, 30, 60)).toList())
    }

    @Test
    fun theScreenSeesEveryState() = runTest {
        val model = WeekModel(this) { listOf(45, 30) }
        val seen = mutableListOf<WeekUi>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
            model.state.toList(seen)
        }
        model.refresh()
        advanceUntilIdle()
        model.add(60)
        assertEquals(
            listOf(WeekUi.Loading, WeekUi.Loaded(listOf(45, 30)), WeekUi.Loaded(listOf(45, 30, 60))),
            seen,
        )
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests FlowTest
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :processResources NO-SOURCE
> Task :processTestResources NO-SOURCE
> Task :compileKotlin
> Task :compileJava NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar
> Task :compileTestKotlin
> Task :compileTestJava NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test

FlowTest > totalsRunAlong() PASSED

FlowTest > theScreenSeesEveryState() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 4 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

Duas peças fazem o segundo teste funcionar:

- **O `backgroundScope`** é um escopo que o `runTest` cancela quando o corpo do teste termina. Um coletor
  lançado em `this` deixaria o teste esperando para sempre por um flow sem fim; um lançado aqui é parado
  por você.
- **O `UnconfinedTestDispatcher(testScheduler)`** roda o coletor no instante em que um valor é definido,
  em vez de pô-lo na fila. No dispatcher de fila da seção 06, um valor definido e substituído antes da vez
  do coletor seria pulado, que é a conflação da lição 17, e o teste estaria verificando o agendador em
  vez do modelo.

O `seen` guarda exatamente três estados, embora o `refresh` defina `Loading` num estado que já era
`Loading`. **O teste pegou uma propriedade do `StateFlow` que ninguém escreveu nele**: um valor igual não é
emitido duas vezes, então a tela não é chamada a redesenhar o que já mostra.

Essa é a forma que o `android-apps` usa para o guardador de estado de cada tela: dê a ele uma fonte,
colete o estado numa lista, aja, e compare a lista.
