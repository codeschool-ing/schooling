---
title: Trocando uma ligação num teste
version: 1
---

**O motivo de pôr o store e o relógio em módulos é poder tirá-los de novo num teste.** Um teste com
Hilt roda a activity de verdade, a tela de verdade e o ViewModel de verdade, com um grafo em que você
trocou as partes que quer controlar. Aqui o store vem com duas sessões, e o relógio parado ao meio-dia
de quarta-feira, 28 de outubro de 2026:

```kotlin
// app/src/test/java/com/example/planner/WeekHiltTest.kt
package com.example.planner

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import com.example.planner.data.InMemorySessionStore
import com.example.planner.data.SessionStore
import com.example.planner.data.StudySession
import com.example.planner.di.ClockModule
import com.example.planner.di.StoreModule
import dagger.hilt.android.testing.BindValue
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import dagger.hilt.android.testing.HiltTestApplication
import dagger.hilt.android.testing.UninstallModules
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@HiltAndroidTest
@UninstallModules(StoreModule::class, ClockModule::class)
@RunWith(RobolectricTestRunner::class)
@Config(application = HiltTestApplication::class)
class WeekHiltTest {
    @get:Rule(order = 0) val hilt = HiltAndroidRule(this)
    @get:Rule(order = 1) val compose = createAndroidComposeRule<MainActivity>()

    @BindValue @JvmField
    val store: SessionStore = InMemorySessionStore().apply {
        runBlocking {
            add(StudySession(101, "kotlin", LocalDate.of(2026, 10, 26), 50, done = true))
            add(StudySession(102, "sql", LocalDate.of(2026, 10, 27), 90))
        }
    }

    @BindValue @JvmField
    val clock: Clock = Clock.fixed(Instant.parse("2026-10-28T15:00:00Z"), ZoneId.of("America/Sao_Paulo"))

    @Test fun theScreenUsesTheStoreAndTheClockItWasGiven() {
        compose.onNodeWithText("140 min this week, 1 of 2 done").assertExists()
        compose.onNodeWithText("Minutes").performTextInput("25")
        compose.onNodeWithText("Add").performClick()
        compose.onNodeWithText("2026-10-28 · 25 min").assertExists()
        compose.onNodeWithText("165 min this week, 1 of 3 done").assertExists()
        println("sessions in the store: ${runBlocking { store.sessions().first().map { it.minutes } }}")
    }
}
```

Cada anotação tem uma função:

| | o que faz |
|---|---|
| `@HiltAndroidTest` | o Hilt gera um grafo só para esta classe de teste |
| `@UninstallModules(StoreModule::class, ClockModule::class)` | tira desse grafo as respostas do app para o store e o relógio |
| `@BindValue` | põe este campo no grafo como a resposta para o tipo declarado |
| `@Config(application = HiltTestApplication::class)` | o Robolectric inicia a aplicação de teste do Hilt no lugar do `PlannerApp` |
| `Rule(order = 0)` no `HiltAndroidRule` | monta o grafo antes de a regra do Compose iniciar a activity que precisa dele |

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-z]"
    sessions in the store: [50, 90, 25]
WeekHiltTest > theScreenUsesTheStoreAndTheClockItWasGiven PASSED
BUILD SUCCESSFUL in 35s
40 actionable tasks: 16 executed, 24 up-to-date
```

**A tela mostrou sessões que o app nunca adicionou e uma data que o computador não tinha.** O
ViewModel era o de verdade, construído pelo Hilt, e recebeu o store falso e o relógio parado sem uma
linha dele mudar: 50 e 90 minutos já na semana, depois 25 com data de 28, porque era o que o relógio
dizia. É todo o argumento a favor da injeção num teste só. A aula 16 usa o mesmo movimento para trocar
a rede por uma falsa.

**Não executado**: os testes instrumentados do Hilt, o mesmo arquivo em `androidTest` com um test
runner próprio que inicia o `HiltTestApplication` num aparelho, como descreve o guia de testes do Hilt
do Google. Eles precisam de um aparelho ou emulador; a versão da seção 07 roda o mesmo grafo no
Robolectric.
