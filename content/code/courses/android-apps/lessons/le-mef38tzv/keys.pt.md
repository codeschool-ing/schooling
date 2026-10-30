---
title: Chaves, para o estado acompanhar o item e não a posição
version: 1
---

**Sem chave, uma `LazyColumn` conhece as linhas pela posição**: linha 0, linha 1, linha 2. Tudo o que
uma linha lembra, uma rolagem dentro dela, um campo de texto meio digitado, se está aberta, pertence
à "linha 0". Insira uma sessão no topo e toda sessão desce uma posição, enquanto todo valor lembrado
fica onde estava, agora preso a outra sessão.

Para ver isso, o planner precisa de um modelo e de uma linha que lembre alguma coisa. O modelo é o do
planner, escrito como toda aula que precisa dele o escreve, com uma função que monta a mesma lista de sessões toda vez que é
chamada:

```kotlin
// app/src/main/java/com/example/planner/data/StudySession.kt
package com.example.planner.data

import java.time.LocalDate

data class Course(val id: String, val name: String)

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)

val courses = listOf(Course("kotlin", "Kotlin"), Course("android", "Android Apps"), Course("sql", "SQL Databases"))

fun courseName(id: String) = courses.first { it.id == id }.name

// Three sessions a day from `start`, the same list every time it is called.
fun sessionsFrom(start: LocalDate, count: Int, firstId: Long = 1): List<StudySession> =
    (0 until count).map { i ->
        StudySession(
            id = firstId + i,
            courseId = courses[i % courses.size].id,
            date = start.plusDays(i / 3L),
            minutes = listOf(25, 45, 50, 90)[i % 4],
        )
    }
```

A linha mostra o curso e os minutos, e um toque abre uma segunda linha com o id e a data da sessão.
Se ela está aberta é estado que a linha guarda com `remember`, que a aula 4 apresentou:

```kotlin
// app/src/main/java/com/example/planner/ui/SessionItem.kt
package com.example.planner.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.planner.data.StudySession
import com.example.planner.data.courseName

@Composable
fun SessionItem(session: StudySession, modifier: Modifier = Modifier) {
    var open by remember { mutableStateOf(false) }
    Column(
        modifier
            .fillMaxWidth()
            .clickable { open = !open }
            .padding(horizontal = 16.dp, vertical = 12.dp),
    ) {
        Text("${courseName(session.courseId)} · ${session.minutes} min", style = MaterialTheme.typography.titleMedium)
        if (open) {
            Text("Session ${session.id}, ${session.date}", style = MaterialTheme.typography.bodySmall)
        }
    }
}
```

O teste monta uma lista de três sessões, abre a primeira, insere uma sessão nova acima dela e
pergunta de qual sessão são os detalhes que aparecem agora. Faz isso duas vezes, uma sem chaves e
outra com `key = { it.id }`:

```kotlin
// app/src/test/java/com/example/planner/KeysTest.kt
package com.example.planner

import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.example.planner.data.StudySession
import com.example.planner.data.sessionsFrom
import com.example.planner.ui.SessionItem
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class KeysTest {
    @get:Rule val rule = createComposeRule()
    private val monday = LocalDate.of(2026, 10, 26)

    private fun openAfterInsert(useKeys: Boolean): String {
        val sessions = mutableStateListOf(*sessionsFrom(monday, 3, firstId = 10).toTypedArray())
        rule.setContent {
            LazyColumn {
                if (useKeys) items(sessions, key = { it.id }) { SessionItem(it) }
                else items(sessions) { SessionItem(it) }
            }
        }
        rule.onNodeWithText("Kotlin · 25 min").performClick()
        rule.runOnIdle { sessions.add(0, StudySession(9, "sql", monday, 50)) }
        val open = rule.onNodeWithText("Session", substring = true).fetchSemanticsNode()
        return open.config[SemanticsProperties.Text].joinToString()
    }

    @Test fun withoutKeys() = println("without keys, the open details say: " + openAfterInsert(false))

    @Test fun withKeys() = println("with keys, the open details say: " + openAfterInsert(true))
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.KeysTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 28s
ana@vm:~/planner$ grep -h -e 'keys, the' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.KeysTest.xml | sed 's/.*CDATA\[//'
without keys, the open details say: SQL Databases · 50 min, Session 9, 2026-10-26
with keys, the open details say: Kotlin · 25 min, Session 10, 2026-10-26
```

**Sem chaves, os detalhes abertos na sessão de Kotlin agora aparecem embaixo de SQL Databases**, a
sessão 9, em que ninguém tocou. O estado aberto ficou na posição 0, e a sessão 9 entrou nela. Com o
id como chave, o estado acompanhou a sessão 10 até a posição 1, onde ele pertence.

O defeito é silencioso como os piores defeitos. Nada quebra, a tela parece razoável, e um estudante
que abriu uma sessão vê outra aberta depois que a lista se atualiza pela rede. **Dê a toda chamada de
`items` uma chave que seja a identidade do item**, que no planner é o `id` da sessão, nunca a posição
e nunca algo que possa mudar, como o título.

Duas regras vêm com as chaves. Elas precisam ser únicas dentro da lista, e uma repetida lança erro em
tempo de execução. E no Android precisam ser de um tipo que caiba num `Bundle`, para a posição de
rolagem da lista sobreviver à restauração do processo, que a aula 4 explica; `Long`, `Int` e `String`
servem.
