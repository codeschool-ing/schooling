---
title: As asserções que o kotlin.test oferece
version: 1
---

O `assertEquals` é a maior parte do que um teste precisa. O resto do `kotlin.test` cobre os casos em que
igualdade é a pergunta errada:

| asserção | passa quando |
|---|---|
| `assertEquals(expected, actual)` | os dois são iguais, pelo `==` |
| `assertTrue(condition)` / `assertFalse(condition)` | a condição é `true` / `false` |
| `assertNull(x)` / `assertNotNull(x)` | `x` é `null` / não é, e o `assertNotNull` o devolve como não nulo |
| `assertIs<T>(x)` | `x` é um `T`, e o devolve com smart cast para `T` |
| `assertFailsWith<E> { … }` | o bloco lança um `E`, e devolve a exceção |
| `assertContains(collection, element)` | o elemento está na coleção |

As duas últimas devolvem algo, e é isso que as torna úteis: um teste pode seguir verificando a mensagem
da exceção, ou uma propriedade do subtipo. O `WeekTotal` da lição 17 recusa minutos que não sejam
positivos, e um teste pode cobrar isso dele:

```kotlin
// src/test/kotlin/WeekTotalTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs

class WeekTotalTest {
    @Test
    fun addsUp() {
        val week = WeekTotal()
        week.add(45)
        week.add(30)
        assertEquals(75, week.minutes.value)
    }

    @Test
    fun refusesZero() {
        val e = assertFailsWith<IllegalArgumentException> { WeekTotal().add(0) }
        assertEquals("minutes must be positive: 0", e.message)
    }

    @Test
    fun loadedCarriesItsSessions() {
        val state: WeekUi = WeekUi.Loaded(listOf(45, 30))
        val loaded = assertIs<WeekUi.Loaded>(state)
        assertEquals(2, loaded.sessions.size)
    }
}
```

O `--tests` roda uma classe, ou um teste, em vez de todos:

```
ana@vm:~/kt/planner$ ./gradlew test --tests WeekTotalTest
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

WeekTotalTest > addsUp() PASSED

WeekTotalTest > refusesZero() PASSED

WeekTotalTest > loadedCarriesItsSessions() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

**O `refusesZero` testa uma falha, e passa porque a falha aconteceu.** Uma recusa é comportamento como
qualquer outro, e no dia em que alguém remover o `require`, é este teste que avisa. O `assertIs` devolveu
`state` com o tipo `WeekUi.Loaded`, então `loaded.sessions` compilou sem cast, o mesmo smart cast que o
`is` da lição 9 dava.

O `assertEquals` compara com `==`, e é por isso que as data classes da lição 8 deixam os testes curtos:
dois valores `Loaded` com a mesma lista são iguais, e um teste pode escrever o estado esperado inteiro
numa linha.
