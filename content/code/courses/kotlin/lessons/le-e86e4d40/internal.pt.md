---
title: internal é visível dentro de um módulo
version: 1
---

A tabela da lição 7 deu ao `internal` uma linha e uma promessa: **visível em todo lugar do mesmo módulo,
e em nenhum outro**. Com um módulo ele se comportou como `public`. Com dois ele traça uma linha, e o
`Week.percent()` fica atrás dela: o `summary()` o usa, um teste no `core` pode verificá-lo, e o `app`
não pode chamá-lo.

Um teste dentro do `core` pode:

```kotlin
// core/src/test/kotlin/WeekTest.kt
package studyplan.core

import kotlin.test.Test
import kotlin.test.assertEquals

class WeekTest {
    @Test
    fun percentOfTheGoal() {
        val week = Week(goal = 300)
        week.add(Session("kotlin", 45))
        week.add(Session("android-apps", 30))
        assertEquals(25, week.percent())
    }
}
```

```
ana@vm:~/kt/studyplan$ ./gradlew -q :core:test && echo tests passed
tests passed
```

Com `-q` um teste que passa não imprime nada, então o `&& echo` avisa: o `echo` só roda se o Gradle
terminou com sucesso. Agora a mesma chamada a partir do `app`, acrescentada como última linha do `main`:

```kotlin
    println(week.percent())
```

```
ana@vm:~/kt/studyplan$ ./gradlew -q :app:run 2>&1 | head -3
e: file:///home/ana/kt/studyplan/app/src/main/kotlin/Main.kt:12:18 Cannot access 'fun percent(): Int': it is internal in 'studyplan.core.Week'.

FAILURE: Build failed with an exception.
```

**O compilador recusou, nomeando a declaração e o motivo: ela é `internal` ao `core`.** Tire a linha de
novo. O `internal` é como um módulo guarda a liberdade de mudar algo. O `percent()` pode virar um
`Double`, ou levar o arredondamento em conta, e só o código no `core` precisa concordar; `public` o
teria tornado uma promessa a todo módulo que um dia depender do `core`.
