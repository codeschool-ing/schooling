---
title: Seis callbacks em dois pares e um par de pontas
version: 1
---

**O ciclo de vida são três perguntas que o sistema responde para cada activity**: ela existe,
alguém consegue vê-la, e ela é a que está na frente recebendo toques. Cada callback é o momento em
que uma resposta muda. `onCreate` e `onDestroy` delimitam a vida do objeto; `onStart` e `onStop`
delimitam o tempo em que ele está visível; `onResume` e `onPause` delimitam o tempo em que está na
frente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 225\" role=\"img\" data-fig=\"l02-states\" aria-label=\"O ciclo de vida como quatro caixas da esquerda para a direita: o objeto feito pelo sistema, CREATED, STARTED e RESUMED. onCreate, onStart e onResume levam para a frente. onPause e onStop levam de volta, e onDestroy leva de CREATED a DESTROYED. O Home para em CREATED.\"><defs><marker id=\"l02-states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"64\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"85.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new MainActivity()</text><text x=\"85.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">feito pelo sistema</text><rect x=\"200\" y=\"64\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"255.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CREATED</text><text x=\"255.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">existe, não visível</text><rect x=\"380\" y=\"64\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">STARTED</text><text x=\"435.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">visível</text><rect x=\"560\" y=\"64\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RESUMED</text><text x=\"615.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">na frente, recebe toques</text><line x1=\"150\" y1=\"78\" x2=\"198\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-phosphor)\"></line><text x=\"175.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">onCreate</text><line x1=\"310\" y1=\"78\" x2=\"378\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-phosphor)\"></line><text x=\"345.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">onStart</text><line x1=\"490\" y1=\"78\" x2=\"558\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-phosphor)\"></line><text x=\"525.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">onResume</text><line x1=\"560\" y1=\"102\" x2=\"492\" y2=\"102\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-amber)\"></line><text x=\"525.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onPause</text><line x1=\"380\" y1=\"102\" x2=\"312\" y2=\"102\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-amber)\"></line><text x=\"345.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onStop</text><rect x=\"200\" y=\"166\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"255\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DESTROYED</text><text x=\"255\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">acabou</text><line x1=\"255\" y1=\"114\" x2=\"255\" y2=\"164\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-amber)\"></line><text x=\"264\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onDestroy</text><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">para a frente, conforme a activity aparece</text><text x=\"400\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">para trás, conforme ela sai; o Home para em CREATED</text></svg>", "caption": "Cada callback é o momento em que uma resposta muda: o par de fora delimita a vida do objeto, o do meio a visibilidade, o de dentro estar na frente."}
```

A imagem errada mais comum é a de que os callbacks rodam uma vez cada, de cima para baixo, como uma
receita. Não rodam. Entre `onCreate` e `onDestroy` os pares do meio rodam tantas vezes quantas o
usuário sair e voltar, e uma activity passa a maior parte da vida dando voltas nos laços de dentro.

## Observando sem celular

Num celular, `adb logcat -s Lifecycle` mostra essas linhas de log enquanto acontecem. **Não
executado**: a máquina de gravação não tinha aparelho. Um teste consegue provocar as mesmas
transições no seu computador. O `ActivityScenario`, de `androidx.test:core`, abre uma activity no
Robolectric e a move entre estados sob comando, do jeito que o sistema faria:

```kotlin
// app/src/test/java/com/example/planner/LifecycleTest.kt
package com.example.planner

import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ActivityScenario
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.shadows.ShadowLog

@RunWith(RobolectricTestRunner::class)
class LifecycleTest {
    @Before
    fun logToConsole() {
        ShadowLog.stream = System.out
    }

    @Test
    fun homeAndBack() {
        val scenario = ActivityScenario.launch(MainActivity::class.java)
        println("-- the user presses Home")
        scenario.moveToState(Lifecycle.State.CREATED)
        println("-- the user comes back")
        scenario.moveToState(Lifecycle.State.RESUMED)
        println("-- the user presses Back")
        scenario.close()
    }

    @Test
    fun rotation() {
        val scenario = ActivityScenario.launch(MainActivity::class.java)
        println("-- the user turns the phone")
        scenario.recreate()
    }
}
```

`ShadowLog.stream = System.out` manda o que o `Log.d` escreve para a saída padrão do teste, e o
Gradle só mostra a saída padrão de um teste quando alguém pede. O arquivo de build do módulo pede, em
`testOptions`; é o arquivo da aula 1 com essas quatro linhas a mais:

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

O teste imprime muita coisa além das linhas do planner: o log do próprio Robolectric e o da
biblioteca de testes. O `grep` fica com a linha que nomeia cada teste e com as linhas marcadas
`Lifecycle`:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --rerun --tests "*LifecycleTest.homeAndBack" 2>&1 | grep -E "STANDARD_OUT|Lifecycle:|  --|^BUILD"
LifecycleTest > homeAndBack STANDARD_OUT
    D/Lifecycle: onCreate: instance 1 in this process, saved state: false
    D/Lifecycle: onStart
    D/Lifecycle: onResume
    -- the user presses Home
    D/Lifecycle: onPause
    D/Lifecycle: onStop
    -- the user comes back
    D/Lifecycle: onStart
    D/Lifecycle: onResume
    -- the user presses Back
    D/Lifecycle: onPause
    D/Lifecycle: onStop
    D/Lifecycle: onDestroy: finishing true, configuration change false
BUILD SUCCESSFUL in 18s
```

**O Home não é o fim de nada.** Apertá-lo pausa e para a activity, e o objeto fica. Num aparelho o
sistema também chama `onSaveInstanceState` nesse ponto, depois do `onStop`, porque pode precisar da
memória mais tarde e matar o processo; a documentação do Google diz isso para todo Android desde o 9.
O `moveToState` não simula essa chamada, e por isso ela falta acima; a rotação da seção 04 a mostra.
Voltar ao app roda `onStart` e `onResume` na mesma instância, e o `onCreate` não é chamado de novo.
O Voltar é diferente: ele **encerra** a activity, e o `onDestroy` diz `finishing true`. O usuário
disse que terminou com essa tela, e o objeto vai embora.

Essa diferença, o Home guarda e o Voltar encerra, tem uma exceção que vale conhecer. Segundo a documentação do Google sobre o ciclo de vida da activity, a partir do Android 12 uma activity de launcher não é encerrada pelo Voltar, e sim levada para o segundo plano,
como se o Home tivesse sido apertado. O `ActivityScenario.close()` encerra a activity em qualquer versão, que é o que o teste
acima mostra. **Não executado** num aparelho.
