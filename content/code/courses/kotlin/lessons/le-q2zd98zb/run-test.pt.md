---
title: runTest e tempo virtual
version: 1
---

Uma função `@Test` é uma função comum, e uma função comum não chama uma suspensa. Um teste do `loadWeek`
da lição 14 precisa de uma corrotina em que rodar. **O `runTest`, do `kotlinx-coroutines-test`, é essa
corrotina**, feita para testes, e ele faz mais uma coisa: **o `delay` dentro dele não espera**.

```kotlin
// src/test/kotlin/VirtualTimeTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.hours
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest

class VirtualTimeTest {
    @Test
    fun loadWeekTakesNoRealTime() = runTest {
        assertEquals(listOf(45, 30, 60), loadWeek())
        assertEquals(300, currentTime)
    }

    @Test
    fun anHourPassesAtOnce() = runTest {
        delay(1.hours)
        assertEquals(3_600_000, currentTime)
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests VirtualTimeTest
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :compileKotlin UP-TO-DATE
> Task :compileJava NO-SOURCE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar UP-TO-DATE
> Task :processTestResources NO-SOURCE

> Task :compileTestKotlin
w: file:///home/ana/kt/planner/src/test/kotlin/VirtualTimeTest.kt:13:27 This declaration needs opt-in. Its usage should be marked with '@kotlinx.coroutines.ExperimentalCoroutinesApi' or '@OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)'
w: file:///home/ana/kt/planner/src/test/kotlin/VirtualTimeTest.kt:19:33 This declaration needs opt-in. Its usage should be marked with '@kotlinx.coroutines.ExperimentalCoroutinesApi' or '@OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)'

> Task :compileTestJava NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test

VirtualTimeTest > loadWeekTakesNoRealTime() PASSED

VirtualTimeTest > anHourPassesAtOnce() PASSED

[Incubating] Problems report is available at: file:///home/ana/kt/planner/build/reports/problems/problems-report.html

BUILD SUCCESSFUL in 2s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

Uma hora de `delay` passou, e a execução inteira levou os poucos segundos que o Gradle sempre leva.
**O `runTest` mantém um relógio próprio**, o `currentTime`, em milissegundos. Quando toda corrotina do
teste está esperando, ele pula o relógio para a próxima que vence, em vez de dormir. O `loadWeek` fez
`delay` de 300 milissegundos, então o relógio marcou 300; a hora marcou 3.600.000.

É por isso que um timeout, um retry com espera crescente ou um lembrete para amanhã podem ser testados.
Esperar de verdade faria uma bateria deles levar horas; pular os delays testaria outro programa. O tempo
virtual roda o mesmo programa, na mesma ordem, sem a espera.

As duas linhas `w:` são do compilador, e falam do `currentTime`: **o `kotlinx-coroutines-test` marca parte
da API como experimental**, quer dizer, a forma dela ainda pode mudar entre versões, e pede que o código
que a usa diga isso. Responda com uma anotação na classe e o import dela:

```kotlin
import kotlinx.coroutines.ExperimentalCoroutinesApi

@OptIn(ExperimentalCoroutinesApi::class)
class VirtualTimeTest {
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests VirtualTimeTest
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :compileKotlin UP-TO-DATE
> Task :compileJava NO-SOURCE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :compileTestKotlin
> Task :compileTestJava NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test

VirtualTimeTest > loadWeekTakesNoRealTime() PASSED

VirtualTimeTest > anHourPassesAtOnce() PASSED

BUILD SUCCESSFUL in 3s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

Os avisos pararam, e a linha `Problems report` também, que era o Gradle juntando os mesmos avisos numa
página. Os testes das próximas seções trazem a anotação desde o começo.

O `loadWeek` também imprimiu as duas linhas dele. Elas foram para a saída padrão do teste, que o Gradle
guarda no relatório em vez de imprimir, então o terminal mostra o resultado e não a conversa.
