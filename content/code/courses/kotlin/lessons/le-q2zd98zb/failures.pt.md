---
title: Testando o que dá errado
version: 1
---

A aula 17 tomou uma decisão sobre falhas: **um arquivo que falta é um estado que a tela desenha, e um bug
não é**. O `refresh` pega `IOException` e nada mais. As duas metades são comportamento, e as duas podem
ser testadas, porque o modelo recebe a fonte em vez de procurar uma:

```kotlin
// src/test/kotlin/FailureTest.kt
import java.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class FailureTest {
    @Test
    fun aMissingFileIsAState() = runTest {
        val model = WeekModel(this) { throw IOException("week.txt is missing") }
        model.refresh()
        advanceUntilIdle()
        assertEquals(WeekUi.Failed("week.txt is missing"), model.state.value)
    }

    @Test
    fun aBugIsNotAState() {
        val e = assertFailsWith<IllegalStateException> {
            runTest {
                WeekModel(this) { error("a bug in the source") }.refresh()
            }
        }
        assertEquals("a bug in the source", e.message)
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests FailureTest
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

FailureTest > aBugIsNotAState() PASSED

FailureTest > aMissingFileIsAState() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

O primeiro teste é o caminho triste da tela, sem sistema de arquivos envolvido: a fonte lança a exceção
que um arquivo faltando lançaria, e o estado diz isso. **O segundo é o que protege a decisão.** O
`error(…)` lança `IllegalStateException`, que o `refresh` não pega, então a corrotina lançada falha, a
falha chega ao escopo do teste como a aula 15 descreveu, e o `runTest` a relança quando termina. O
`assertFailsWith` em volta do `runTest` transforma isso num teste que passa.

Alguém arrumando o código depois vai ter vontade de escrever `catch (e: Exception)` no `refresh`, para
"nada quebrar". Essa mudança engoliria cancelamento e bugs do mesmo jeito, e é este teste que falha quando
alguém a faz.

O `runTest` relançar também é uma proteção em todos os outros testes. **Uma exceção numa corrotina que o
teste lançou faz o teste falhar**, mesmo quando as asserções dele passaram, então uma falha em trabalho de
fundo não passa despercebida numa bateria verde.
