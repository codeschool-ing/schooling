---
title: Um estado para uma tela
version: 1
---

**É mais fácil raciocinar sobre o estado de uma tela quando ele é um valor só.** A tela da semana do
planner mostra uma lista de sessões, um total, quantas estão feitas e um campo de texto onde o
estudante digita os minutos da próxima sessão. Quatro coisas, e o jeito tentador de guardá-las são
quatro variáveis, cada uma alterada pelo pedaço de código que chegou primeiro. Aí o total é
recalculado num lugar e esquecido em outro, e a tela mostra 90 minutos ao lado de uma lista que
soma 135.

A alternativa é uma classe imutável que descreve tudo o que a tela desenha, e um único lugar que cria
as novas. Esse lugar é o **ViewModel**. A aula 17 de `kotlin` escreveu a mesma forma sem classe base,
como `WeekModel`; aqui ela estende `androidx.lifecycle.ViewModel`, e a seção 04 diz o que a classe
base compra.

O ViewModel e a função que o liga ao Compose vêm de duas bibliotecas `androidx.lifecycle`, então o
arquivo de build do módulo ganha duas linhas, e uma terceira para as ferramentas de teste de
corrotinas que a seção 07 usa. O bloco `testOptions` também ganha um `testLogging`, que imprime o nome
de cada teste e tudo o que ele imprimir, e que as próximas seções leem:

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

O modelo do planner é o mesmo em toda aula que precisa dele:

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

E o estado da tela, com a classe que é dona dele:

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/ui/WeekViewModel.kt", "parts": [{"code": "package com.example.planner.ui\n\nimport androidx.lifecycle.SavedStateHandle\nimport androidx.lifecycle.ViewModel\nimport com.example.planner.data.StudySession\nimport kotlinx.coroutines.flow.MutableStateFlow\nimport kotlinx.coroutines.flow.StateFlow\nimport kotlinx.coroutines.flow.asStateFlow\nimport kotlinx.coroutines.flow.update\nimport java.time.LocalDate"}, {"code": "data class WeekUiState(\n    val sessions: List<StudySession> = emptyList(),\n    val draftMinutes: String = \"\",\n) {\n    val totalMinutes: Int get() = sessions.sumOf { it.minutes }\n    val doneCount: Int get() = sessions.count { it.done }\n    val canAdd: Boolean get() = draftMinutes.toIntOrNull() in 5..240\n}", "note": "Tudo o que a tela desenha, num valor imutável. O total, a contagem e se o botão está habilitado são calculados do resto, então não podem discordar dele."}, {"code": "class WeekViewModel(private val saved: SavedStateHandle) : ViewModel() {\n    private val _state = MutableStateFlow(WeekUiState(draftMinutes = saved[DRAFT] ?: \"\"))\n    val state: StateFlow<WeekUiState> = _state.asStateFlow()\n    private var nextId = 1L", "note": "Um `MutableStateFlow` privado e um `StateFlow` público só de leitura: só esta classe pode mudar o estado. O `SavedStateHandle` é o assunto da seção 05."}, {"code": "    fun onDraftChange(text: String) {\n        saved[DRAFT] = text\n        _state.update { it.copy(draftMinutes = text) }\n    }", "note": "Cada mudança é uma função com o nome do que o estudante fez, e cada uma cria um estado novo com `copy`."}, {"code": "    fun onAdd(date: LocalDate) {\n        val minutes = _state.value.draftMinutes.toIntOrNull() ?: return\n        if (minutes !in 5..240) return\n        val session = StudySession(nextId++, \"android\", date, minutes)\n        saved[DRAFT] = \"\"\n        _state.update { it.copy(sessions = it.sessions + session, draftMinutes = \"\") }\n    }", "note": "A data é um parâmetro, e não uma chamada ao relógio, para que um teste possa passar 26 de outubro de 2026 e ter sempre a mesma resposta."}, {"code": "    fun onToggleDone(id: Long) = _state.update { s ->\n        s.copy(sessions = s.sessions.map { if (it.id == id) it.copy(done = !it.done) else it })\n    }\n\n    private companion object {\n        const val DRAFT = \"draft\"\n    }\n}", "note": "Marcar uma sessão como feita troca um elemento da lista, e tudo o que é calculado da lista acompanha."}]}
```

**`draftMinutes` é uma `String`, não um `Int`.** É o que o estudante digitou até agora, e `"4"` a
caminho de `"45"` é um estado legítimo de um campo de texto que ainda não é uma duração válida. A
conversão acontece uma vez, em `canAdd` e em `onAdd`, e o campo nunca briga com o teclado.

Repare no que a classe não contém: nenhum `Context`, nenhuma `Activity`, nenhum composable, nada de
`android.view`. É Kotlin puro sobre um `StateFlow`, e é por isso que a seção 07 consegue testá-la
sem Android nenhum. A seção 06 diz por que mantê-la assim é uma regra, e não um gosto.

A lista em si fica aqui só nesta aula. **Sessões pertencem a um banco de dados**, que é a aula 15, e
um ViewModel que as guarda na memória as perde no instante em que o processo termina; a seção 05 é
exatamente sobre essa perda.
