---
title: O que faz um composable rodar de novo
version: 1
---

**Um composable roda de novo quando um objeto de estado que ele leu na última execução é escrito.**
Não quando o pai roda, não quando qualquer coisa muda na tela: quando um valor que ele de fato leu
ganha um valor novo. O Compose registra cada leitura de um objeto de estado feita no corpo de um
composable, associada àquele composable; uma escrita então encontra exatamente os composables que o
leram, e só esses rodam de novo. Isso é a **recomposição**, e a aula 3 prometeu medi-la.

Para medir, cada composable abaixo registra que rodou, com `SideEffect`. A aula 3 disse que o corpo
de um composable não deve fazer trabalho, e o `SideEffect` é a exceção autorizada: o Compose roda o
bloco dele uma vez depois que cada composição do composable que o contém é aplicada, que é
exatamente a contagem que se quer.

```kotlin
// app/src/test/java/com/example/planner/RecompositionTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

val runs = mutableMapOf<String, Int>()

fun count(name: String) {
    runs[name] = (runs[name] ?: 0) + 1
}

@Composable
fun WeekScreen() {
    var minutes by remember { mutableIntStateOf(0) }
    SideEffect { count("WeekScreen") }
    Column {
        Title("This week")
        Total(minutes)
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@Composable
fun Title(text: String) {
    SideEffect { count("Title") }
    Text(text)
}

@Composable
fun Total(minutes: Int) {
    SideEffect { count("Total") }
    Text("$minutes min")
}

@RunWith(RobolectricTestRunner::class)
class RecompositionTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun onlyWhatReadTheValueRunsAgain() {
        rule.setContent { WeekScreen() }
        repeat(3) {
            rule.onNodeWithText("Add").performClick()
            rule.waitForIdle()
        }
        println("after 3 clicks: $runs")
    }
}
```

`WeekScreen` é dono dos minutos e desenha três coisas: um título que nunca muda, o total e o botão. O
teste aperta o botão três vezes e imprime quantas vezes cada composable rodou. Ele usa o arquivo de
build da aula 2, para ver o que os testes imprimem:

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
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*RecompositionTest" 2>&1 | grep -E "after 3|^BUILD"
    after 3 clicks: {WeekScreen=4, Title=1, Total=4}
BUILD SUCCESSFUL in 26s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 195\" role=\"img\" data-fig=\"l05-scopes\" aria-label=\"WeekScreen desenhado como uma caixa que lê minutes e rodou 4 vezes. Dentro dela, três caixas: Title com o mesmo argumento, pulado e rodado uma vez; Total com um argumento novo a cada vez, rodado 4 vezes; e Button, que escreve minutes, com uma seta subindo até WeekScreen.\"><defs><marker id=\"l05-scopes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"680\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WeekScreen</text><text x=\"130\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lê minutes, então rodou 4 vezes</text><rect x=\"40\" y=\"80\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"140.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Title(\"This week\")</text><text x=\"140.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mesmo argumento: pulado, rodou 1 vez</text><rect x=\"270\" y=\"80\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Total(minutes)</text><text x=\"370.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">argumento novo: rodou 4 vezes</text><rect x=\"500\" y=\"80\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Button(onClick)</text><text x=\"590.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escreve minutes</text><line x1=\"590\" y1=\"80\" x2=\"590\" y2=\"62\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l05-scopes-ah-amber)\"></line></svg>", "caption": "Três cliques: a escrita roda o composable que leu o valor, e as chamadas que ele faz só rodam onde o argumento mudou."}
```

**`Title` rodou uma vez; os dois que tocaram nos minutos rodaram quatro**, a primeira composição e
três recomposições. `WeekScreen` lê `minutes` quando o passa a `Total`, então uma escrita em
`minutes` roda `WeekScreen` de novo. Rodar `WeekScreen` de novo chama `Title("This week")` e
`Total(25)`, e aqui aparece a segunda regra: **o Compose pula uma chamada cujos argumentos são iguais
aos da última vez.** `Title` recebeu a mesma string e foi pulado; `Total` recebeu um número novo e
rodou.

## Ler mais tarde, para rodar menos

`WeekScreen` rodou quatro vezes só porque leu os minutos ele mesmo, para repassá-los. Passe uma
**lambda que os lê**, `Total(minutesProvider = { minutes })`, e a leitura acontece dentro de `Total`
quando ele chama a lambda. Aí uma escrita em `minutes` roda só `Total`, e `WeekScreen` fica em um. O
teste da seção 05 é montado assim. Vale a pena para um valor que muda a cada quadro, como o
deslocamento de uma rolagem; para um clique não compensa o código menos legível, e a seção 07 diz
como saber a diferença.
