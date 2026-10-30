---
title: Um build com dois módulos
version: 1
---

O planejador é um projeto com tudo dentro: o modelo da semana, os experimentos com corrotinas, os
testes. Programas de verdade se dividem. **Um módulo é um projeto dentro de um build, com fontes e
dependências próprias**, e módulos dependem uns dos outros como um projeto depende de uma biblioteca. A
primeira divisão de costume põe as regras num módulo e o programa em outro, para as regras poderem ser
testadas, e mais tarde reusadas por um segundo programa, sem o primeiro.

Um build novo, `~/kt/studyplan`, tem dois módulos: `core`, que sabe o que é uma semana de estudo, e
`app`, que roda. Ele começa com uma cópia do wrapper e do catálogo do planejador, que são o diretório
`gradle` e os dois scripts `gradlew`:

```
ana@vm:~/kt/studyplan$ cp -r ../planner/gradle ../planner/gradlew ../planner/gradlew.bat .
ana@vm:~/kt/studyplan$ find . -type f | sort
./gradle/libs.versions.toml
./gradle/wrapper/gradle-wrapper.jar
./gradle/wrapper/gradle-wrapper.properties
./gradlew
./gradlew.bat
```

```kotlin
// settings.gradle.kts
rootProject.name = "studyplan"

dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}

include("core", "app")
```

O `include` nomeia os módulos, cada um um diretório com um script de build próprio. Os repositórios vêm
para cá, declarados uma vez para todos os módulos. O `build.gradle.kts` da raiz tem um trabalho só:

```kotlin
// build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm) apply false
}
```

O `apply false` carrega o plugin do Kotlin, na versão do catálogo, sem aplicá-lo à raiz, que não tem
código. **Cada módulo então o aplica sem versão**, e todos recebem a mesma.

```kotlin
// core/build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm)
}

dependencies {
    testImplementation(kotlin("test"))
}

kotlin {
    jvmToolchain(21)
}

tasks.test {
    useJUnitPlatform()
}
```

```kotlin
// core/src/main/kotlin/Week.kt
package studyplan.core

data class Session(val course: String, val minutes: Int)

class Week(private val goal: Int) {
    private val sessions = mutableListOf<Session>()

    fun add(s: Session) {
        require(s.minutes > 0) { "minutes must be positive: ${s.minutes}" }
        sessions += s
    }

    val total: Int get() = sessions.sumOf { it.minutes }

    fun summary(): String = "${sessions.size} sessions, $total of $goal min (${percent()}%)"

    internal fun percent(): Int = total * 100 / goal
}
```

**O `package studyplan.core` põe as declarações do arquivo num espaço de nomes.** O planejador nunca
precisou de um, sendo um programa só; dois módulos que um dia vão ter, cada um, um `Week` precisam. O
módulo `app` depende do `core` com `project(":core")`:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm)
    application
}

dependencies {
    implementation(project(":core"))
}

kotlin {
    jvmToolchain(21)
}

application {
    mainClass = "studyplan.app.MainKt"
}
```

```kotlin
// app/src/main/kotlin/Main.kt
package studyplan.app

import studyplan.core.Session
import studyplan.core.Week

fun main() {
    val week = Week(goal = 300)
    week.add(Session("kotlin", 45))
    week.add(Session("android-apps", 30))
    println(week.summary())
}
```

```
ana@vm:~/kt/studyplan$ ./gradlew :app:run
> Task :app:checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :core:checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :core:processResources NO-SOURCE
> Task :app:processResources NO-SOURCE
> Task :core:compileKotlin
> Task :core:compileJava NO-SOURCE
> Task :core:classes UP-TO-DATE
> Task :core:jar
> Task :app:compileKotlin
> Task :app:compileJava NO-SOURCE
> Task :app:classes UP-TO-DATE

> Task :app:run
2 sessions, 75 of 300 min (25%)

BUILD SUCCESSFUL in 5s
4 actionable tasks: 4 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l19-modules\" aria-label=\"O build studyplan. Em cima, a raiz: o settings.gradle.kts inclui core e app, e o gradle/libs.versions.toml guarda as versões dos dois. Embaixo, dois módulos lado a lado. O core guarda Session, Week e Week.percent(), que é internal. O app guarda Main.kt e depende do core por implementation(project(&quot;:core&quot;)). O app pode chamar Week e summary(); a linha do app até percent() está riscada, porque o internal para na borda do módulo.\"><defs><marker id=\"l19-modules-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-modules-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l19-modules-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"170\" y=\"14\" width=\"380\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o build: studyplan</text><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">settings.gradle.kts  include(\"core\", \"app\")</text><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">gradle/libs.versions.toml</text><path d=\"M300 76 L190 112\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M420 76 L530 112\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"114\" width=\"280\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">módulo core</text><text x=\"180\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Session, Week, summary()</text><rect x=\"70\" y=\"184\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"180\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">internal fun percent()</text><rect x=\"420\" y=\"114\" width=\"260\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">módulo app</text><text x=\"550\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Main.kt</text><text x=\"550\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">implementation(project(\":core\"))</text><path d=\"M418 162 L322 162\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-modules-ah-phosphor)\"></path><text x=\"370\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">chama</text><path d=\"M418 210 L292 210\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M347 202 L363 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M363 202 L347 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"355\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">recusado</text></svg>", "caption": "Dois módulos num build: o app depende do core e enxerga o que o core torna público, não o que ele guarda como internal."}
```

O `:app:run` é a tarefa `run` do módulo `app`; o caminho com dois-pontos nomeia um módulo como um
caminho com barras nomeia um diretório. O Gradle construiu o `core` primeiro, porque o `app` depende
dele, sem que ninguém mandasse. O `mainClass` ganhou o pacote, `studyplan.app.MainKt`, porque um `main` de
topo num arquivo com pacote mora numa classe com o nome do pacote e do arquivo.
