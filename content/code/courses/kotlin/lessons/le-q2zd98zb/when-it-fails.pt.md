---
title: Lendo um teste que falha
version: 1
---

Um teste que nunca falhou não foi visto funcionando. Aqui está um que falha, escrito com um deslize que
qualquer um comete, num arquivo próprio:

```kotlin
// src/test/kotlin/SummaryTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals

class SummaryTest {
    @Test
    fun threeSessions() {
        assertEquals("3 sessions, 135 mins", describe(WeekUi.Loaded(listOf(45, 30, 60))))
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests SummaryTest
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

> Task :test FAILED

SummaryTest > threeSessions() FAILED
    org.opentest4j.AssertionFailedError: expected: <3 sessions, 135 mins> but was: <3 sessions, 135 min>

1 test completed, 1 failed

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':test'.
> There were failing tests. See the report at: file:///home/ana/kt/planner/build/reports/tests/test/index.html

* Try:
> Run with --scan to get full insights from a Build Scan (powered by Develocity).

BUILD FAILED in 2s
4 actionable tasks: 2 executed, 2 up-to-date
```

Leia de cima para baixo. **A linha abaixo do nome do teste é o diagnóstico inteiro**: o que se esperava,
e o que o código produziu. Tudo de `FAILURE:` para baixo é o Gradle dizendo que a tarefa `test` falhou, e
o relatório que ele cita traz a mesma informação como página web, útil quando as falhas são dezenas.

As duas strings diferem por um `s`. **A pergunta que uma falha faz é qual lado está errado**, e nem sempre
é o código. Aqui o código diz `min`, como toda captura desde a lição 17, e o teste foi digitado de
memória. Troque a string esperada por `"3 sessions, 135 min"` e rode de novo:

```
ana@vm:~/kt/planner$ ./gradlew test --tests SummaryTest
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

SummaryTest > threeSessions() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

O caso oposto é aquele para o qual os testes existem: o valor esperado estava certo, o código mudou, e a
falha é a primeira notícia que alguém tem disso. Nos dois casos, **um teste vermelho se conserta
decidindo, não editando o lado que o deixa verde**.
