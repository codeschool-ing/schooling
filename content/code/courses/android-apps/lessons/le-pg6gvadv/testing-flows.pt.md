---
title: Testando um ViewModel que roda corrotinas
version: 1
---

**O `viewModelScope` roda em `Dispatchers.Main`, e um teste comum na JVM não tem thread principal.**
Chame `onAdd` num teste do estilo da aula 10 e ele falha antes de começar, porque não há looper do
Android por trás de `Main`. A resposta da biblioteca de testes de corrotinas é trocar `Main` por um
dispatcher de teste durante o teste, que é o que `Dispatchers.setMain` faz. A aula 18 de `kotlin`
apresentou o `runTest` e o tempo virtual; aqui é a mesma maquinaria apontada para um ViewModel.

```kotlin
// app/src/test/java/com/example/planner/ui/WeekViewModelTest.kt
package com.example.planner.ui

import androidx.lifecycle.SavedStateHandle
import com.example.planner.data.InMemorySessionStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.time.LocalDate

@OptIn(ExperimentalCoroutinesApi::class)
class WeekViewModelTest {
    private val main = UnconfinedTestDispatcher()
    private val monday = LocalDate.of(2026, 10, 26)

    @Before fun mainIsATestDispatcher() = Dispatchers.setMain(main)
    @After fun mainIsRestored() = Dispatchers.resetMain()

    @Test fun withNobodyCollectingTheStateStaysLoading() = runTest(main) {
        val vm = WeekViewModel(InMemorySessionStore(), SavedStateHandle())
        vm.onDraftChange("45")
        vm.onAdd(monday)
        assertTrue(vm.state.value.loading)
    }

    @Test fun withACollectorTheStateFollowsTheStore() = runTest(main) {
        val vm = WeekViewModel(InMemorySessionStore(), SavedStateHandle())
        backgroundScope.launch { vm.state.collect {} }
        vm.onDraftChange("45")
        vm.onAdd(monday)
        assertEquals(45, vm.state.value.totalMinutes)
        assertEquals("", vm.state.value.draftMinutes)
    }

    @Test fun addingSendsOneEvent() = runTest(main) {
        val vm = WeekViewModel(InMemorySessionStore(), SavedStateHandle())
        vm.onDraftChange("45")
        vm.onAdd(monday)
        assertEquals(WeekEvent.Added(45), vm.events.first())
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekViewModelTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-z]"
WeekViewModelTest > withACollectorTheStateFollowsTheStore PASSED
WeekViewModelTest > withNobodyCollectingTheStateStaysLoading PASSED
WeekViewModelTest > addingSendsOneEvent PASSED
BUILD SUCCESSFUL in 2s
30 actionable tasks: 1 executed, 29 up-to-date
```

O primeiro teste é o que surpreende. **Ninguém coleta `state`, então o `WhileSubscribed` nunca inicia
a origem**, e `state.value` fica no valor inicial por mais sessões que sejam adicionadas. É o
`stateIn` funcionando como a seção 03 descreveu, e é por isso que o segundo teste começa um coletor
no `backgroundScope` antes: um escopo que o `runTest` cancela sozinho quando o teste termina, então o
coletor não deixa o teste esperando.

O `UnconfinedTestDispatcher` roda cada corrotina imediatamente, até a primeira suspensão de verdade, o
que mantém estes testes em linha reta: o `onAdd` volta depois de o store ter sido escrito. O
`CancelTest` da seção 02 usou um `StandardTestDispatcher`, que não roda nada até o teste avançar o
relógio, porque ali o ponto era parar no meio.

O terceiro teste lê um evento com `first()`, que coleta até o primeiro elemento e para. O channel
tinha guardado o evento desde que o `onAdd` o enviou, sem ninguém ouvindo, que é a propriedade em que
a seção 06 se apoiou.

A execução inteira, as quatro classes de teste desta aula, seis testes ao todo:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E '^BUILD'
BUILD SUCCESSFUL in 17s
ana@vm:~/planner$ grep -ho "testsuite name=\"[a-zA-Z.]*\" tests=\"[0-9]*\" skipped=\"[0-9]*\" failures=\"[0-9]*\"" app/build/test-results/testDebugUnitTest/*.xml
testsuite name="com.example.planner.SnackbarTest" tests="1" skipped="0" failures="0"
testsuite name="com.example.planner.SubscriptionTest" tests="1" skipped="0" failures="0"
testsuite name="com.example.planner.ui.CancelTest" tests="1" skipped="0" failures="0"
testsuite name="com.example.planner.ui.WeekViewModelTest" tests="3" skipped="0" failures="0"
```
