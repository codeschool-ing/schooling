---
title: O relatório do próprio compilador sobre estabilidade
version: 1
---

**O compilador do Compose consegue escrever o que decidiu sobre cada classe e cada composable**, e
ler esse relatório substitui o palpite. Duas configurações no arquivo de build do módulo o ligam, e
uma terceira, usada abaixo, deixa você corrigir o compilador sobre uma classe que ele não enxerga por
dentro. É o arquivo de build da aula 2 com o bloco `composeCompiler` acrescentado:

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

composeCompiler {
    reportsDestination = layout.buildDirectory.dir("compose_compiler")
    metricsDestination = layout.buildDirectory.dir("compose_compiler")
    stabilityConfigurationFiles.add(rootProject.layout.projectDirectory.file("stability.conf"))
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

A terceira linha nomeia um arquivo na raiz do projeto. Ele começa sem nada além de um comentário:

```conf
// stability.conf
// Classes the Compose compiler should treat as stable, one per line.
```

O relatório é escrito enquanto o compilador Kotlin roda, então o build precisa compilar, e o `clean`
garante isso:

```
ana@vm:~/planner$ ./gradlew --console=plain clean compileDebugKotlin 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 4s
ana@vm:~/planner$ cat app/build/compose_compiler/app-classes.txt
unstable class com.example.planner.MainActivity {
  <runtime stability> = Unstable
}
unstable class com.example.planner.data.StudySession {
  stable val id: Long
  stable val courseId: String
  unstable val date: LocalDate
  stable val minutes: Int
  stable val done: Boolean
  <runtime stability> = Unstable
}
```

**`StudySession` é instável, e o relatório diz qual campo causou isso**: `date`, um `LocalDate`. O
compilador consegue provar que um `val` com um `Long` ou uma `String` nunca muda, porque conhece esses
tipos. `LocalDate` é uma classe Java de `java.time`, compilada sem o compilador do Compose, e o
compilador não consegue olhar dentro dela, então supõe o pior. `MainActivity` também é instável, o que
não importa: nada passa uma activity a um composable.

O relatório de composables mostra a mesma decisão do outro lado, para o teste da seção 03:

```
ana@vm:~/planner$ ./gradlew --console=plain compileDebugUnitTestKotlin 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 7s
ana@vm:~/planner$ grep -A3 -E "fun com.example.planner.(SessionCount|DraftMinutes)" app/build/compose_compiler/app-composables.txt
restartable skippable scheme("[androidx.compose.ui.UiComposable]") fun com.example.planner.SessionCount(
  sessions: List<StudySession>
  stable name: String
)
restartable skippable scheme("[androidx.compose.ui.UiComposable]") fun com.example.planner.DraftMinutes(
  unstable draft: Draft
  stable name: String
)
```

`unstable draft: Draft` é o motivo de o rascunho ter sido comparado por identidade e rodado toda vez.
`sessions` não traz palavra nenhuma, o que o relatório usa quando a estabilidade fica para o tempo de
execução, em vez de decidida pelo compilador; a seção 03 mediu no que isso deu, uma comparação por
valor. E o arquivo de métricas do módulo diz que o strong skipping está ligado:

```
ana@vm:~/planner$ grep -A5 featureFlags app/build/compose_compiler/debug/app-module.json
  "featureFlags": {
    "StrongSkipping": true,
    "IntrinsicRemember": true,
    "OptimizeNonSkippingGroups": true,
    "PausableComposition": true
  }
```

## Contando ao compilador o que ele não vê

`LocalDate` é imutável: a documentação do Java para `java.time` chama todas as suas classes de
imutáveis e seguras entre threads. O compilador não tem como saber, e o arquivo de estabilidade é
onde você conta a ele. Uma linha:

```conf
// stability.conf
// Classes the Compose compiler should treat as stable, one per line.
java.time.LocalDate
```

```
ana@vm:~/planner$ ./gradlew --console=plain clean compileDebugKotlin 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 3s
ana@vm:~/planner$ grep -A7 StudySession app/build/compose_compiler/app-classes.txt
stable class com.example.planner.data.StudySession {
  stable val id: Long
  stable val courseId: String
  stable val date: LocalDate
  stable val minutes: Int
  stable val done: Boolean
  <runtime stability> = Stable
}
```

**`StudySession` agora é estável, e todo composable que recebe uma a compara por valor.** É uma
promessa que você faz ao compilador, não um fato que ele confere: liste aqui uma classe que muda
depois de criada, e o Compose vai pular composables que deveriam ter rodado, mostrando dados velhos.
Só classes cuja documentação garante imutabilidade pertencem a este arquivo.
