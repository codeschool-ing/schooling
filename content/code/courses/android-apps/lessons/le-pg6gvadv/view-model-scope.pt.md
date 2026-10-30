---
title: Um escopo que termina com a tela
version: 1
---

**Toda corrotina que um ViewModel inicia deve terminar quando o ViewModel termina.** A aula 15 de
`kotlin` tornou a regra geral: nenhuma corrotina sobrevive ao trabalho a que pertence. No Android o
trabalho é uma tela, o estado da tela vive no ViewModel dela, e então o escopo pertence ao ViewModel.
Esse escopo é o `viewModelScope`, e a classe base o cancela em `onCleared()`, o momento que a seção
04 da aula 10 descreveu: a activity destruída de vez, e não por uma rotação.

A imagem errada é um `GlobalScope.launch` num tratador de clique, ou um escopo criado na activity. O
primeiro roda até terminar o que quer que aconteça com a tela; o segundo é cancelado a cada rotação,
no meio de uma escrita. O `viewModelScope` não faz nenhuma das duas coisas, porque vive exatamente
tanto quanto o ViewModel.

## De onde vêm agora as sessões do planner

A aula 10 guardava as sessões numa lista dentro do ViewModel. Agora elas vêm de um **store** que as
expõe como um `Flow` e escreve com funções `suspend`. A aula 15 o transforma num banco Room e a aula
16 num repositório; para esta aula uma versão em memória basta, e o que importa é a forma:

```kotlin
// app/src/main/java/com/example/planner/data/SessionStore.kt
package com.example.planner.data

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update

interface SessionStore {
    fun sessions(): Flow<List<StudySession>>
    suspend fun add(session: StudySession)
    suspend fun toggleDone(id: Long)
}

class InMemorySessionStore : SessionStore {
    private val all = MutableStateFlow<List<StudySession>>(emptyList())

    /** How many collectors are listening right now; section 04 prints it. */
    val subscribers: StateFlow<Int> get() = all.subscriptionCount

    override fun sessions(): Flow<List<StudySession>> = all

    override suspend fun add(session: StudySession) = all.update { it + session }

    override suspend fun toggleDone(id: Long) = all.update { list ->
        list.map { if (it.id == id) it.copy(done = !it.done) else it }
    }
}

/** The one store the app uses until lesson 12 lets Hilt make it. */
object Stores {
    val sessions = InMemorySessionStore()
}
```

O mesmo arquivo de build da aula 10, com as bibliotecas de lifecycle e as ferramentas de teste de
corrotinas:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.roborazzi)
}

android {
    namespace = "com.example.planner"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example.planner"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.testLogging {
                events("passed", "failed")
                showStandardStreams = true
            }
        }
    }
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.lifecycle.viewmodel.compose)
    implementation(libs.lifecycle.runtime.compose)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
    testImplementation(libs.coroutines.test)
}
```

O modelo é o da aula 10, sem mudanças:

```kotlin
// app/src/main/java/com/example/planner/data/Model.kt
package com.example.planner.data

import java.time.LocalDate

data class Course(val id: String, val name: String)

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)
```

## Uma escrita cancelada junto com a tela

O ViewModel escreve por `viewModelScope.launch`. Para ver o que o escopo compra, este teste dá a um
ViewModel um store que leva dez segundos para escrever, começa uma escrita e depois descarta o
ViewModel do jeito que uma activity encerrada faz, pelo `ViewModelStore` dele. O store diz se a
escrita terminou:

```kotlin
// app/src/test/java/com/example/planner/ui/CancelTest.kt
package com.example.planner.ui

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.example.planner.data.InMemorySessionStore
import com.example.planner.data.SessionStore
import com.example.planner.data.StudySession
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import java.time.LocalDate

@OptIn(ExperimentalCoroutinesApi::class)
class CancelTest {
    private val dispatcher = StandardTestDispatcher()

    @Before fun mainIsATestDispatcher() = Dispatchers.setMain(dispatcher)
    @After fun mainIsRestored() = Dispatchers.resetMain()

    private class SlowStore(private val inner: SessionStore = InMemorySessionStore()) : SessionStore by inner {
        override suspend fun add(session: StudySession) {
            try {
                delay(10_000)
                inner.add(session)
                println("write completed")
            } catch (e: CancellationException) {
                println("write cancelled")
                throw e
            }
        }
    }

    @Test fun clearingTheViewModelCancelsItsWrite() = runTest(dispatcher) {
        val store = ViewModelStore()
        val factory = viewModelFactory { initializer { WeekViewModel(SlowStore(), SavedStateHandle()) } }
        val vm = ViewModelProvider.create(store, factory)[WeekViewModel::class]
        vm.onDraftChange("45")
        vm.onAdd(LocalDate.of(2026, 10, 26))
        advanceTimeBy(1_000)
        println("one second in, clearing the ViewModel")
        store.clear()
        advanceTimeBy(20_000)
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*CancelTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-z]"
    one second in, clearing the ViewModel
    write cancelled
CancelTest > clearingTheViewModelCancelsItsWrite PASSED
BUILD SUCCESSFUL in 4s
30 actionable tasks: 11 executed, 19 up-to-date
```

**A escrita nunca terminou, e ninguém precisou lembrar de pará-la.** Limpar o store chamou
`onCleared()`, que cancelou o `viewModelScope`, que cancelou a corrotina no meio do `delay`; a
`CancellationException` passou pelo `catch` do store e foi relançada, como a aula 15 de `kotlin` diz
que deve ser. O `advanceTimeBy` é o assunto da seção 07: os dez segundos do teste passam em tempo
nenhum.

Cancelar uma escrita no banco pela metade às vezes é exatamente o errado. Uma escrita que o estudante
espera que sobreviva à tela, uma sessão para a qual ele apertou **Add** e depois saiu, pertence a um
trabalho que sobrevive ao ViewModel, e a aula 18 a entrega ao WorkManager.
