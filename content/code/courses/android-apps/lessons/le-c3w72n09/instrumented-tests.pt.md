---
title: Testes instrumentados, e a execução que precisa de um aparelho
version: 1
---

**Um teste instrumentado é empacotado num segundo APK, instalado num celular ou num emulador ao lado
do app, e roda lá.** Ele testa o sistema de verdade: a renderização real, as caixas de diálogo reais,
o agendamento real do `WorkManager`, tudo o que o Robolectric só imita. O preço é um aparelho, e
minutos de instalação e abertura a cada execução.

O build precisa de dois acréscimos: o executor que roda os testes no aparelho, e a biblioteca de
testes do Compose para o conjunto de fontes `androidTest`. Este é o arquivo de build inteiro, com as
duas linhas de `androidTest` e o `testInstrumentationRunner` acrescentados:

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
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
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
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)

    androidTestImplementation(platform(libs.compose.bom))
    androidTestImplementation(libs.compose.ui.test.junit4)
}
```

E o teste, em `app/src/androidTest`. É o mesmo tipo de teste de Compose da seção 04, sem
`@RunWith(RobolectricTestRunner::class)`: num aparelho, quem o roda é o `AndroidJUnitRunner`, e o
framework é o do próprio celular.

```kotlin
// app/src/androidTest/java/com/example/planner/ui/WeekScreenDeviceTest.kt
package com.example.planner.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import com.example.planner.data.StudySession
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test

class WeekScreenDeviceTest {
    @get:Rule val rule = createComposeRule()

    @Test fun showsTheTotal() {
        val monday = LocalDate.of(2026, 10, 26)
        val sessions = listOf(StudySession(1, "kotlin", monday, 45, done = true))
        rule.setContent {
            MaterialTheme { WeekScreen(sessions, mapOf("kotlin" to "Kotlin"), monday) {} }
        }
        rule.onNodeWithTag("total").assertTextEquals("45 of 45 minutes done this week")
    }
}
```

## Rodando aqui

```
ana@vm:~/planner$ ./gradlew --console=plain connectedDebugAndroidTest 2>&1 | grep -E -A2 'What went wrong|^BUILD' | grep -v '^--'
* What went wrong:
Execution failed for task ':app:connectedDebugAndroidTest' (registered by plugin 'com.android.internal.application').
> com.android.builder.testing.api.DeviceException: No connected devices!
BUILD FAILED in 2s
68 actionable tasks: 1 executed, 67 up-to-date
ana@vm:~/planner$ adb devices
List of devices attached
```

**Esta é a resposta real da máquina de gravação**, e a única execução instrumentada deste curso: o
Gradle compilou o app e o APK de teste, depois procurou um aparelho e não encontrou nenhum. O
`adb devices` confirma que a lista está vazia, pelo motivo que a seção 02 da aula 1 deu.

**Não executado**, portanto: o teste em si. Num computador com um emulador aberto ou um celular ligado
pelo USB com a depuração ativada, a documentação do Google diz que `./gradlew connectedDebugAndroidTest`
instala os dois APKs, roda todos os testes de `androidTest` em cada aparelho conectado e escreve um
relatório em `app/build/reports/androidTests/connected/`. O Android Studio roda os mesmos testes pelo
ícone na margem ao lado de cada um.

## Onde os testes instrumentados valem o custo

Guarde-os para o que só um aparelho mostra: que a notificação aparece mesmo na gaveta, que a caixa de
permissão devolve o que a aula 20 espera, que uma tela rola suave num celular lento, que uma migração
da aula 15 funciona no SQLite que o celular traz. O Google também oferece aparelhos gerenciados,
emuladores que o Gradle liga e desliga para a própria execução de testes, e fazendas remotas de
aparelhos que rodam os mesmos testes em dezenas de modelos. Os dois precisam ou de um computador que
rode um emulador ou de uma conta num serviço, e nenhum foi usado aqui.
