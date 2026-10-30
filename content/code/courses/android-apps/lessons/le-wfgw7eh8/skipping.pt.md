---
title: Pular, e os argumentos que o Compose compara
version: 1
---

**Quando o pai de um composable roda de novo, o Compose compara cada argumento com o que ele recebeu
da última vez, e pula a chamada se nenhum mudou.** É nessa comparação que se ganha ou se perde a
maior parte do custo da recomposição, e **como** o Compose compara um argumento depende da
**estabilidade** do tipo dele: se o Compose pode confiar que um objeto que era igual antes continua
igual.

A sessão de estudo ganha um arquivo próprio, o mesmo modelo que toda aula deste curso usa:

```kotlin
// app/src/main/java/com/example/planner/data/StudySession.kt
package com.example.planner.data

import java.time.LocalDate

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)
```

O teste dá a uma tela três filhos. A cada vez que a tela roda, ele passa argumentos a eles de três jeitos diferentes: a mesma lista que ela lembrou, uma lista nova com o mesmo conteúdo, e um `Draft` novo,
uma classe pequena com um `var` dentro:

```kotlin
// app/src/test/java/com/example/planner/SkippingTest.kt
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
import com.example.planner.data.StudySession
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

val week = listOf(
    StudySession(1, "kotlin", LocalDate.of(2026, 10, 26), 45),
    StudySession(2, "sql", LocalDate.of(2026, 10, 27), 50),
)

@Composable
fun SessionCount(sessions: List<StudySession>, name: String) {
    SideEffect { count(name) }
    Text("${sessions.size} sessions")
}

class Draft(var minutes: Int)

@Composable
fun DraftMinutes(draft: Draft, name: String) {
    SideEffect { count(name) }
    Text("${draft.minutes} min planned")
}

@Composable
fun SkippingScreen() {
    var minutes by remember { mutableIntStateOf(0) }
    SideEffect { count("SkippingScreen") }
    val kept = remember { week.filter { it.minutes > 0 } }
    Column {
        Text("$minutes min")
        SessionCount(kept, "same list")
        SessionCount(week.filter { it.minutes > 0 }, "new list each time")
        DraftMinutes(Draft(25), "new draft each time")
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@RunWith(RobolectricTestRunner::class)
class SkippingTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun equalArgumentsAreSkipped() {
        rule.setContent { SkippingScreen() }
        repeat(3) {
            rule.onNodeWithText("Add").performClick()
            rule.waitForIdle()
        }
        println("after 3 clicks: $runs")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*SkippingTest" 2>&1 | grep -E "after 3|^BUILD"
    after 3 clicks: {SkippingScreen=4, same list=1, new list each time=1, new draft each time=4}
BUILD SUCCESSFUL in 27s
```

A tela rodou quatro vezes; os três filhos não a acompanharam todos.

- **A mesma lista, `kept`, foi pulada todas as vezes.** É exatamente o objeto passado da última vez.
- **A lista nova também foi pulada**, embora seja um objeto diferente a cada execução. O Compose a
  comparou com a antiga por **valor**, `equals`, e duas listas com sessões iguais são iguais.
- **O `Draft` novo rodou todas as vezes.** `Draft` tem um `var`, então o conteúdo pode mudar depois
  de comparado; o Compose chama uma classe assim de **instável** e a compara por **identidade**,
  `===`. Um objeto novo nunca é idêntico ao antigo, então a chamada sempre roda.

## Strong skipping, que mudou a regra em 2024

Guias mais antigos dizem que um composable com parâmetro instável nunca é pulado, e no Compose
anterior ao Kotlin 2.0.20 isso era verdade. O compilador do Compose agora liga o **strong skipping**
por padrão: todo composable pode ser pulado, argumentos instáveis são comparados por identidade e os
estáveis por `equals`. A seção 04 mostra o compilador dizendo isso no próprio relatório, em
`featureFlags`.

O que o strong skipping não muda é a lição do `Draft`: um objeto reconstruído a cada execução anula o
pulo, por menor que seja. A correção é parar de reconstruí-lo, com `remember`, ou tornar o tipo
estável, que é a seção 04.
