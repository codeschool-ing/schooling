---
title: Os composables que não deveriam: trabalho feito enquanto se descreve
version: 1
---

**Um composable não deve fazer nada além de descrever a tela.** Nada de escrever numa lista, salvar
num arquivo, chamar a rede ou incrementar um contador que outra coisa lê. O motivo é o fato da seção
06: a função roda tantas vezes quantas o Compose precisar, e não é você quem decide quantas. Trabalho
posto no corpo de um composable se repete toda vez, e trabalho que deve acontecer uma vez acontece
várias.

Este teste mostra a forma do bug. `WeekTotal` mostra os minutos da semana e também faz algo que não
deveria: registra numa lista que o total foi mostrado, o tipo de linha que alguém escreve para contar
visualizações de tela. O teste muda os minutos três vezes, como um usuário acrescentando três sessões
faria:

```kotlin
// app/src/test/java/com/example/planner/RunsTest.kt
package com.example.planner

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.v2.createComposeRule
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

val opened = mutableListOf<String>()

@Composable
fun WeekTotal(minutes: Int) {
    opened += "week total shown"
    Text("$minutes min this week")
}

@RunWith(RobolectricTestRunner::class)
class RunsTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun aComposableRunsMoreThanOnce() {
        var minutes by mutableIntStateOf(0)
        rule.setContent { WeekTotal(minutes) }
        for (added in listOf(25, 45, 50)) {
            minutes += added
            rule.waitForIdle()
        }
        println("the screen says: $minutes min this week")
        println("the list says: $opened")
    }
}
```

`mutableIntStateOf` é um valor que o Compose observa, assunto da aula 4; `waitForIdle` deixa o
Compose terminar de reagir antes da próxima mudança. O teste imprime o último estado da tela e a
lista. Ele precisa do arquivo de build da aula 2, que mostra as linhas impressas por um teste:

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
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*RunsTest" 2>&1 | grep -E "STANDARD_OUT|the (screen|list)|^BUILD"
RunsTest > aComposableRunsMoreThanOnce STANDARD_OUT
    the screen says: 120 min this week
    the list says: [week total shown, week total shown, week total shown, week total shown]
BUILD SUCCESSFUL in 19s
```

**Uma tela, quatro entradas.** O total estava certo a cada vez, 120 no fim, porque descrever a tela de
novo com dados novos é exatamente para o que o Compose serve. A lista está errada, porque acrescentar
a ela não descreve nada: cada execução da função acrescentou mais uma linha. Um contador de
visualizações escrito assim contaria cada tecla que mudasse um número naquela tela.

## Três regras, e para onde o trabalho vai

A documentação do Compose do Google diz o que um composable pode supor, e cada regra é um jeito de a
linha acima dar errado:

- **Ele pode rodar com muita frequência**, até uma vez por quadro durante uma animação. Qualquer coisa
  lenta no corpo faz a tela engasgar.
- **Ele pode rodar em qualquer ordem, ou nem rodar.** O Compose pode pular um composable cujas
  entradas não mudaram, aula 5, e não promete que irmãos rodem na ordem em que foram escritos.
- **O resultado dele deve depender só das entradas.** Chamado duas vezes com os mesmos parâmetros, ele
  deve descrever a mesma tela e não mudar mais nada.

O trabalho não some; ele muda de lugar. Algo que deve acontecer **uma vez quando uma tela aparece**,
como carregar os dados dela, vai num `LaunchedEffect`, que o Compose roda uma vez e cancela quando o
composable sai; a aula 11 o usa. Algo que acontece **porque o usuário fez alguma coisa** vai num
tratador de evento, `onClick`, que roda quando ele aperta e não quando a tela é desenhada. E o
trabalho que nem é sobre a tela vai para fora do composable, no `ViewModel` da aula 10. O corpo de um
composable é para descrever, e descrever não tem efeitos colaterais.
