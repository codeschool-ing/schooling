---
title: Um valor que o Compose observa, e um que ele não observa
version: 1
---

**Um composable só mostra dados novos quando o Compose sabe que os dados mudaram.** A aula 3 disse
que um composable roda de novo quando algo que ele lê muda. A pergunta desta seção é o que esse
"algo" pode ser. Uma variável Kotlin comum não é: o Compose não consegue ver um `var` mudar. O que ele
vê é um **objeto de estado**, feito com `mutableStateOf` ou um dos seus irmãos, e cada leitura de um
deles dentro de um composable fica registrada, para que uma escrita encontre os composables que o
leram.

Três contadores mostram a diferença, cada um com um botão que soma 25 minutos a um número na tela.
Eles moram num arquivo de teste, porque são uma demonstração e não fazem parte do planner:

```kotlin
// app/src/test/java/com/example/planner/StateTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@Composable
fun PlainCounter() {
    var minutes = 0
    Column {
        Text("$minutes min")
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@Composable
fun UnrememberedCounter() {
    var minutes by mutableIntStateOf(0)
    Column {
        Text("$minutes min")
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@Composable
fun RememberedCounter() {
    var minutes by remember { mutableIntStateOf(0) }
    Column {
        Text("$minutes min")
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@RunWith(RobolectricTestRunner::class)
class StateTest {
    @get:Rule
    val rule = createComposeRule()

    private fun clickAndRead(name: String, content: @Composable () -> Unit) {
        rule.setContent(content)
        rule.onNodeWithText("Add").performClick()
        rule.waitForIdle()
        val shown = if (rule.onAllNodesWithText("25 min").fetchSemanticsNodes().isEmpty()) "0 min" else "25 min"
        println("$name after one click: $shown")
    }

    @Test fun plain() = clickAndRead("a plain var") { PlainCounter() }
    @Test fun unremembered() = clickAndRead("mutableIntStateOf without remember") { UnrememberedCounter() }
    @Test fun remembered() = clickAndRead("remember { mutableIntStateOf }") { RememberedCounter() }
}
```

`createComposeRule` vem do pacote `v2`. O do pacote acima dele está obsoleto nesta versão do Compose,
e o aviso do compilador dá o motivo: a regra `v2` enfileira as corrotinas de um teste em vez de rodá-las
na hora, como fazem as outras ferramentas de teste do Kotlin. É por isso que cada teste aqui chama
`waitForIdle` antes de ler a tela. Os testes imprimem o que veem, com o arquivo de build da aula 2:

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
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*StateTest" 2>&1 | grep -E "after one click|^BUILD"
    mutableIntStateOf without remember after one click: 0 min
    a plain var after one click: 0 min
    remember { mutableIntStateOf } after one click: 25 min
BUILD SUCCESSFUL in 13s
```

A ordem das três linhas é a ordem em que os testes calharam de rodar, que o Gradle não fixa. **Só um
contador andou, e ele precisou de duas coisas.**

- **O `var` comum nunca mostra 25.** O clique muda a variável; nada avisa o Compose, então nada roda
  de novo e o `Text` continua dizendo 0. O número na memória e o número na tela se separaram, que é o
  pior tipo de bug, porque o código que mudou o valor parece certo.
- **`mutableIntStateOf` sem `remember` também mostra 0, por outro motivo.** Desta vez a escrita é
  vista e o composable roda de novo. Rodar de novo significa rodar de novo a primeira linha,
  `mutableIntStateOf(0)`, que cria um objeto de estado **novo** valendo 0. O 25 foi escrito num objeto
  que a nova execução jogou fora.
- **`remember` guarda o objeto de estado entre as execuções**, e a contagem chega a 25.

`mutableIntStateOf` é o `mutableStateOf` especializado em `Int`, para que o número não seja
encaixotado num objeto a cada escrita; `mutableLongStateOf`, `mutableFloatStateOf` e
`mutableDoubleStateOf` existem pelo mesmo motivo. Todo o resto usa `mutableStateOf(valor)`. O `by`
transforma o objeto de estado numa propriedade, então `minutes += 25` lê e escreve o `value` dele.
