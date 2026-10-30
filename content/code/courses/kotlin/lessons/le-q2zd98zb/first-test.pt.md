---
title: Um primeiro teste, rodado pelo Gradle
version: 1
---

Todo programa até aqui foi verificado rodando-o e lendo o que imprimia. Isso funciona uma vez. Deixa de
funcionar no dia em que uma mudança num arquivo quebra algo três arquivos adiante, e ninguém roda o
programa que teria mostrado. **Um teste é uma verificação escrita como código**, guardada ao lado do
programa e rodada pelo build toda vez, então quem lê é a máquina.

A biblioteca `kotlin.test`, do próprio Kotlin, fornece as asserções, e o JUnit as roda; o Gradle liga os
dois. O build do planejador ganha duas dependências de teste e um bloco `tasks.test`. Aqui está o arquivo
inteiro:

```kotlin
// build.gradle.kts
import org.gradle.api.tasks.testing.logging.TestExceptionFormat

plugins {
    kotlin("jvm") version "2.4.21"
    application
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0")
    testImplementation(kotlin("test"))
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.11.0")
}

kotlin {
    jvmToolchain(21)
}

application {
    mainClass = providers.gradleProperty("main").orElse("HelloKt")
}

tasks.test {
    useJUnitPlatform()
    testLogging {
        events("passed", "failed")
        exceptionFormat = TestExceptionFormat.FULL
        showStackTraces = false
    }
}
```

| linha | o que faz |
|---|---|
| `testImplementation(kotlin("test"))` | o `kotlin.test`, na mesma versão do plugin do Kotlin, só para o código de teste |
| `kotlinx-coroutines-test` | o `runTest` e o tempo virtual, para as seções 05 a 08 |
| `useJUnitPlatform()` | roda os testes com o JUnit 5; o plugin do Kotlin escolhe a partir disso o adaptador do `kotlin.test` que combina |
| `testLogging` | imprime o nome e o resultado de cada teste, e a mensagem de uma falha sem o stack trace |

O `testImplementation` mantém as bibliotecas de teste fora do programa: elas estão no classpath quando os
testes compilam e rodam, e ausentes do que o `./gradlew run` inicia. Sem o `testLogging`, o Gradle não
imprime nada sobre testes que passam, o que é silencioso mas não diz nada a quem está começando.

Os testes moram em `src/test/kotlin`, ao lado de `src/main/kotlin`, e enxergam tudo dele que não for
`private`. O primeiro verifica o `describe` da lição 17:

```kotlin
// src/test/kotlin/DescribeTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals

class DescribeTest {
    @Test
    fun loadedWeekIsCounted() {
        assertEquals("2 sessions, 75 min", describe(WeekUi.Loaded(listOf(45, 30))))
    }

    @Test
    fun loadingSaysSo() {
        assertEquals("loading…", describe(WeekUi.Loading))
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :processResources NO-SOURCE
> Task :processTestResources NO-SOURCE
> Task :compileKotlin
> Task :compileJava NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar
> Task :compileTestKotlin
> Task :compileTestJava NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test

DescribeTest > loadedWeekIsCounted() PASSED

DescribeTest > loadingSaysSo() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 4 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

**Um teste é uma função marcada com `@Test` dentro de uma classe**, e passa se retornar sem lançar
exceção. O `assertEquals(expected, actual)` lança quando os dois diferem, e o valor esperado vem
primeiro. Os nomes dizem o que está sendo afirmado, porque um nome é o que o Gradle imprime quando o
teste falha.
