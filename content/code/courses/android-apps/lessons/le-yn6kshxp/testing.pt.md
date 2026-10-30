---
title: Testando um ViewModel sem Android nenhum
version: 1
---

**Um ViewModel que não guarda nenhum objeto do Android pode ser testado como Kotlin puro**, e esse é
o teste mais barato que este app vai ter. Sem Robolectric, sem tela, sem activity: construa, chame as
funções como a tela chamaria e leia `state.value`. Os quatro abaixo, build incluído, levaram três
segundos:

```kotlin
// app/src/test/java/com/example/planner/ui/WeekViewModelTest.kt
package com.example.planner.ui

import androidx.lifecycle.SavedStateHandle
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import java.time.LocalDate

class WeekViewModelTest {
    private val monday = LocalDate.of(2026, 10, 26)

    @Test fun aValidDraftBecomesASessionAndTheDraftEmpties() {
        val vm = WeekViewModel(SavedStateHandle())
        vm.onDraftChange("45")
        vm.onAdd(monday)
        assertEquals(45, vm.state.value.totalMinutes)
        assertEquals("", vm.state.value.draftMinutes)
    }

    @Test fun aDraftOutOfRangeAddsNothing() {
        val vm = WeekViewModel(SavedStateHandle())
        vm.onDraftChange("300")
        assertFalse(vm.state.value.canAdd)
        vm.onAdd(monday)
        assertEquals(0, vm.state.value.sessions.size)
    }

    @Test fun togglingMarksOneSessionAndTheCountFollows() {
        val vm = WeekViewModel(SavedStateHandle())
        for (m in listOf("25", "50", "90")) { vm.onDraftChange(m); vm.onAdd(monday) }
        vm.onToggleDone(2)
        assertEquals(1, vm.state.value.doneCount)
        assertEquals(165, vm.state.value.totalMinutes)
    }

    @Test fun theDraftIsReadBackFromTheHandle() {
        val vm = WeekViewModel(SavedStateHandle(mapOf("draft" to "50")))
        assertEquals("50", vm.state.value.draftMinutes)
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekViewModelTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    (before|after|same)"
WeekViewModelTest > theDraftIsReadBackFromTheHandle PASSED
WeekViewModelTest > togglingMarksOneSessionAndTheCountFollows PASSED
WeekViewModelTest > aDraftOutOfRangeAddsNothing PASSED
WeekViewModelTest > aValidDraftBecomesASessionAndTheDraftEmpties PASSED
BUILD SUCCESSFUL in 3s
30 actionable tasks: 1 executed, 29 up-to-date
```

O último teste é a restauração da seção 05 numa linha: um `SavedStateHandle` construído de um mapa é
o que a fábrica padrão constrói a partir de um `Bundle`. **Passar o handle de fora, em vez de deixar o
ViewModel procurá-lo, é o que torna essa linha possível**, e é a mesma lição de passar a data para o
`onAdd`: o que uma classe busca sozinha, um teste não consegue substituir.

## Qual teste para qual pergunta

Esta aula escreveu três tipos, e eles respondem a perguntas diferentes:

| teste | onde roda | o que pode dizer |
|---|---|---|
| `WeekViewModelTest` | a JVM, nada mais | as regras: o que o estado vira depois de cada evento |
| `WeekScreenShotTest` | Robolectric e Roborazzi | o desenho: como é um estado na tela |
| `RecreateTest`, `ProcessDeathTest` | Robolectric, a activity inteira | a ligação: que tela, ViewModel e ciclo de vida estão conectados |

**A maioria dos testes pertence à primeira linha**, porque é a mais rápida e falha por um motivo só.
A terceira linha é a mais lenta e pega o que as outras duas não veem, um ViewModel criado a cada
composição, por exemplo, ou um handle em que ninguém escreve. A aula 21 volta às proporções.
