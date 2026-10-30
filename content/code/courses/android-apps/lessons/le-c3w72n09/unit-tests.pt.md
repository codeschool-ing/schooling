---
title: Testes de unidade, e uma falha que vale ler
version: 1
---

**Um teste de unidade roda um pedaço de código com entradas que você escolheu e compara o resultado
com o que você esperava.** O total da semana do planner é o primeiro pedaço que merece isso: ele
decide quais sessões contam como "esta semana", e um erro ali é invisível em qualquer dia menos
naquele em que importa.

Parta do projeto da aula 1. O arquivo de build é o da aula 1 com um bloco `testLogging` a mais, para
que a saída dos testes apareça como aqui:

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

## O código, com um erro dentro

Eis o modelo do planner e a sua semana, escritos do jeito que muito código é escrito da primeira vez:
com uma semana que começa no domingo, porque é o que o calendário de muitos celulares mostra.

```kotlin
// app/src/main/java/com/example/planner/data/Week.kt
package com.example.planner.data

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)

data class WeekTotal(val planned: Int, val done: Int, val sessions: Int)

/** Monday to Sunday of the week that contains [day]. */
fun weekOf(day: LocalDate): ClosedRange<LocalDate> {
    val start = day.with(TemporalAdjusters.previousOrSame(DayOfWeek.SUNDAY))
    return start..start.plusDays(6)
}

fun weekTotal(sessions: List<StudySession>, day: LocalDate): WeekTotal {
    val week = weekOf(day)
    val inWeek = sessions.filter { it.date in week }
    return WeekTotal(
        planned = inWeek.sumOf { it.minutes },
        done = inWeek.filter { it.done }.sumOf { it.minutes },
        sessions = inWeek.size,
    )
}
```

E os testes. Eles dizem o que o planner promete: uma semana vai de segunda a domingo, um domingo
pertence à semana que termina nele, e o total conta só as sessões daquela semana. Os dados são a
semana de sempre do planner, começando na segunda-feira 26 de outubro de 2026, com uma sessão na
segunda seguinte:

```kotlin
// app/src/test/java/com/example/planner/data/WeekTest.kt
package com.example.planner.data

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

class WeekTest {
    private val monday = LocalDate.of(2026, 10, 26)
    private val sessions = listOf(
        StudySession(1, "kotlin", monday, 45, done = true),
        StudySession(2, "android", monday.plusDays(2), 90),
        StudySession(3, "sql", monday.plusDays(6), 25, done = true),
        StudySession(4, "kotlin", monday.plusDays(7), 50),
    )

    @Test fun aWeekRunsMondayToSunday() {
        assertEquals(monday..monday.plusDays(6), weekOf(monday.plusDays(3)))
    }

    @Test fun sundayBelongsToTheWeekThatEndsOnIt() {
        assertEquals(monday..monday.plusDays(6), weekOf(monday.plusDays(6)))
    }

    @Test fun theTotalCountsOnlyThisWeek() {
        assertEquals(WeekTotal(planned = 160, done = 70, sessions = 3), weekTotal(sessions, monday.plusDays(6)))
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD|tests completed'
> Task :app:testDebugUnitTest FAILED
WeekTest > sundayBelongsToTheWeekThatEndsOnIt FAILED
    java.lang.AssertionError at WeekTest.kt:22
WeekTest > theTotalCountsOnlyThisWeek FAILED
    java.lang.AssertionError at WeekTest.kt:26
WeekTest > aWeekRunsMondayToSunday FAILED
    java.lang.AssertionError at WeekTest.kt:18
3 tests completed, 3 failed
BUILD FAILED in 8s
ana@vm:~/planner$ grep -ho 'message="[^"]*"' app/build/test-results/testDebugUnitTest/*.xml
message="java.lang.AssertionError: expected:&lt;2026-10-26..2026-11-01&gt; but was:&lt;2026-11-01..2026-11-07&gt;"
message="java.lang.AssertionError: expected:&lt;WeekTotal(planned=160, done=70, sessions=3)&gt; but was:&lt;WeekTotal(planned=75, done=25, sessions=2)&gt;"
message="java.lang.AssertionError: expected:&lt;2026-10-26..2026-11-01&gt; but was:&lt;2026-10-25..2026-10-31&gt;"
```

**Leia um teste que falhou pela mensagem, não pelo nome.** O resumo do Gradle diz que três testes
falharam e em que linhas; os arquivos de resultado guardam o que cada um esperava e o que recebeu, e o
segundo comando lista essas mensagens. O teste da quinta-feira é o bug numa linha: esperava
`2026-10-26..2026-11-01` e recebeu `2026-10-25..2026-10-31`, uma semana de domingo a sábado. O teste
do domingo é pior: perguntado sobre o domingo, 1º de novembro, o código o pôs no *começo* da semana
seguinte, `2026-11-01..2026-11-07`. E o total, perguntado naquele domingo, contou a semana errada
inteira: 75 minutos em 2 sessões, a do domingo e a da segunda seguinte, em vez de 160 em 3.

## A correção

```kotlin
// app/src/main/java/com/example/planner/data/Week.kt
package com.example.planner.data

import java.time.DayOfWeek
import java.time.LocalDate

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)

data class WeekTotal(val planned: Int, val done: Int, val sessions: Int)

/** Monday to Sunday of the week that contains [day]. */
fun weekOf(day: LocalDate): ClosedRange<LocalDate> {
    val monday = day.with(DayOfWeek.MONDAY)
    return monday..monday.plusDays(6)
}

fun weekTotal(sessions: List<StudySession>, day: LocalDate): WeekTotal {
    val week = weekOf(day)
    val inWeek = sessions.filter { it.date in week }
    return WeekTotal(
        planned = inWeek.sumOf { it.minutes },
        done = inWeek.filter { it.done }.sumOf { it.minutes },
        sessions = inWeek.size,
    )
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD|tests completed'
WeekTest > sundayBelongsToTheWeekThatEndsOnIt PASSED
WeekTest > theTotalCountsOnlyThisWeek PASSED
WeekTest > aWeekRunsMondayToSunday PASSED
BUILD SUCCESSFUL in 3s
```

`with(DayOfWeek.MONDAY)` leva uma data para a segunda-feira da própria semana, contada de segunda a
domingo, e os três testes passam. **Repare qual teste foi mais barato de escrever e qual importou
mais.** O primeiro compara o intervalo em si, então pega um começo errado em qualquer dia da semana.
O terceiro só pegou porque os dados tinham uma sessão num domingo: uma semana de sessões de terça a
sexta soma o mesmo total de qualquer jeito, e teria passado nas duas versões. As datas de um teste são
escolhidas para ficar nas bordas, não digitadas ao acaso.
