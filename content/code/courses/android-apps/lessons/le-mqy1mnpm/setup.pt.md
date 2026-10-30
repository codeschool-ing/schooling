---
title: O Hilt no build, na aplicação e na activity
version: 1
---

**O Hilt precisa de quatro coisas antes de poder construir qualquer coisa: dois plugins, um
`Application` que diga "o grafo começa aqui", o manifesto nomeando esse `Application`, e uma activity
que diga "injete em mim".** Cada uma é uma linha ou duas, e esquecer qualquer uma produz uma mensagem
que a nomeia.

O arquivo de build do módulo aplica os plugins do KSP e do Hilt, cujas versões o catálogo da aula 1 já fixa. Ele acrescenta o runtime do Hilt, o compilador dele para o KSP, o `hiltViewModel()` do Hilt
para Compose, e a biblioteca de testes com o mesmo compilador para os testes:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
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
    implementation(libs.hilt.android)
    implementation(libs.hilt.lifecycle.viewmodel.compose)
    ksp(libs.hilt.compiler)
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
    testImplementation(libs.hilt.android.testing)
    kspTest(libs.hilt.compiler)
}
```

`ksp(libs.hilt.compiler)` é a linha que faz o trabalho. O **KSP**, o Kotlin Symbol Processor, roda o
compilador do Hilt sobre as suas anotações durante o build, e o compilador escreve código Java que
passa a fazer parte do app; a seção 05 abre um pouco dele. O `kspTest` o roda de novo sobre os fontes
de teste, que têm anotações próprias na seção 07.

A classe de aplicação é uma anotação numa classe vazia:

```kotlin
// app/src/main/java/com/example/planner/PlannerApp.kt
package com.example.planner

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class PlannerApp : Application()
```

e o manifesto a nomeia em `android:name`, para que o Android crie esta classe quando o processo
começa, antes de qualquer activity:

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:name=".PlannerApp"
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

O `@HiltAndroidApp` faz o Hilt gerar o **componente singleton**, o objeto que guarda tudo o que vive
tanto quanto o app. A activity é marcada com `@AndroidEntryPoint`, o que deixa o Hilt dar a ela, e
aos ViewModels que as telas dela pedem, o que precisam:

```kotlin
// app/src/main/java/com/example/planner/MainActivity.kt
package com.example.planner

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import com.example.planner.ui.WeekRoute
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                WeekRoute()
            }
        }
    }
}
```

O modelo é o da aula 10, e o store o da aula 11, com duas anotações e sem `object Stores`:

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

```kotlin
// app/src/main/java/com/example/planner/data/SessionStore.kt
package com.example.planner.data

import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

interface SessionStore {
    fun sessions(): Flow<List<StudySession>>
    suspend fun add(session: StudySession)
    suspend fun toggleDone(id: Long)
}

@Singleton
class InMemorySessionStore @Inject constructor() : SessionStore {
    private val all = MutableStateFlow<List<StudySession>>(emptyList())

    override fun sessions(): Flow<List<StudySession>> = all

    override suspend fun add(session: StudySession) = all.update { it + session }

    override suspend fun toggleDone(id: Long) = all.update { list ->
        list.map { if (it.id == id) it.copy(done = !it.done) else it }
    }
}
```

**`@Inject constructor()` diz ao Hilt como construir a classe, e `@Singleton` quantas construir.** Um
por app é o que o planner precisa: toda tela que pede o store tem de ver as mesmas sessões. Sem
`@Singleton`, cada pedido ganharia um store novo e vazio, que é o bug que o contêiner escrito à mão da
seção 02 também podia cometer, agora visível como uma anotação.
