---
title: Testes de interface em Compose: encontrar, agir, conferir
version: 1
---

**Um teste de interface em Compose conversa com a tela do jeito que um serviço de acessibilidade
conversa**: encontra nós na árvore de semântica pelo que dizem ou por uma tag, age sobre eles, e
confere o que dizem depois. Nunca lê uma variável dentro do seu composable. É esse o ponto: se o
teste encontra "Turn on reminders" pelo texto, um leitor de tela também encontra, e a semântica da
aula 3 é aquilo em que os dois se apoiam.

A tela da semana mostra o total e uma linha por sessão, cada uma com uma caixa de seleção. Ela recebe
as sessões como parâmetro e avisa de um tique por uma lambda, então pode ser testada com a semana que
o teste quiser. O texto do total é um recurso de string:

```xml
<!-- app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Planner</string>
    <string name="welcome">No courses yet. Add the first one.</string>
    <string name="week_total">%1$d of %2$d minutes done this week</string>
</resources>
```

```kotlin
// app/src/main/java/com/example/planner/ui/WeekScreen.kt
package com.example.planner.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.example.planner.R
import com.example.planner.data.StudySession
import com.example.planner.data.weekTotal
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

@Composable
fun WeekScreen(
    sessions: List<StudySession>,
    courseNames: Map<String, String>,
    today: LocalDate,
    onToggle: (Long) -> Unit,
) {
    val total = weekTotal(sessions, today)
    Column(Modifier.padding(16.dp)) {
        Text(
            stringResource(R.string.week_total, total.done, total.planned),
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.testTag("total"),
        )
        for (s in sessions) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth().testTag("session-${s.id}"),
            ) {
                Checkbox(checked = s.done, onCheckedChange = { onToggle(s.id) })
                val day = s.date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.ENGLISH)
                Text("$day  ${courseNames[s.courseId]}  ${s.minutes} min")
            }
        }
    }
}
```

`Modifier.testTag` dá a um nó um nome que é só para testes e nunca aparece. O total e cada linha
ganham um, para que o teste encontre "a linha da sessão 2" sem depender do texto dela.

## O teste

```schooling-example
{"language": "kotlin", "file": "app/src/test/java/com/example/planner/ui/WeekScreenTest.kt", "parts": [{"code": "// app/src/test/java/com/example/planner/ui/WeekScreenTest.kt\npackage com.example.planner.ui\n\nimport androidx.compose.material3.MaterialTheme\nimport androidx.compose.runtime.mutableStateListOf\nimport androidx.compose.ui.test.assertIsOff\nimport androidx.compose.ui.test.assertIsOn\nimport androidx.compose.ui.test.assertTextEquals\nimport androidx.compose.ui.test.isToggleable\nimport androidx.compose.ui.test.junit4.createComposeRule\nimport androidx.compose.ui.test.onChildren\nimport androidx.compose.ui.test.onNodeWithTag\nimport androidx.compose.ui.test.performClick\nimport androidx.compose.ui.test.filter\nimport androidx.compose.ui.test.onFirst\nimport com.example.planner.data.StudySession\nimport java.time.LocalDate\nimport org.junit.Rule\nimport org.junit.Test\nimport org.junit.runner.RunWith\nimport org.robolectric.RobolectricTestRunner\n"}, {"code": "val MONDAY: LocalDate = LocalDate.of(2026, 10, 26)\nval COURSES = mapOf(\"kotlin\" to \"Kotlin\", \"android\" to \"Android Apps\", \"sql\" to \"SQL Databases\")\nfun sampleWeek() = listOf(\n    StudySession(1, \"kotlin\", MONDAY, 45, done = true),\n    StudySession(2, \"android\", MONDAY.plusDays(2), 90),\n    StudySession(3, \"sql\", MONDAY.plusDays(4), 25),\n)\n", "note": "A semana de sempre do planner, como valores de nível superior, para que o teste de captura da seção 05 desenhe a mesma."}, {"code": "@RunWith(RobolectricTestRunner::class)\nclass WeekScreenTest {\n    @get:Rule val rule = createComposeRule()\n", "note": "`createComposeRule()` dá ao teste um hospedeiro para composables e os localizadores que o percorrem. No Robolectric roda na JVM; a seção 06 roda o mesmo tipo de teste num aparelho."}, {"code": "    @Test fun tickingASessionMovesTheTotal() {\n        val sessions = mutableStateListOf(*sampleWeek().toTypedArray())\n        rule.setContent {\n            MaterialTheme {\n                WeekScreen(sessions, COURSES, MONDAY) { id ->\n                    val i = sessions.indexOfFirst { it.id == id }\n                    sessions[i] = sessions[i].copy(done = !sessions[i].done)\n                }\n            }\n        }", "note": "**Preparar.** As sessões vivem num `mutableStateListOf`, então um tique troca uma delas por uma `copy` e a tela se recompõe, como aconteceria com o `ViewModel` da aula 10 guardando a lista."}, {"code": "        rule.onNodeWithTag(\"total\").assertTextEquals(\"45 of 160 minutes done this week\")\n        val box = rule.onNodeWithTag(\"session-2\").onChildren().filter(isToggleable()).onFirst()\n        box.assertIsOff()\n        box.performClick()\n        box.assertIsOn()", "note": "**Conferir, agir, conferir.** Encontre o total pela tag e confira o texto. Depois encontre o filho alternável da linha 2, a caixa de seleção, confira que está desmarcada, clique e confira que está marcada."}, {"code": "        rule.onNodeWithTag(\"total\").assertTextEquals(\"135 of 160 minutes done this week\")\n    }\n}", "note": "E o total de novo: mais 90 minutos feitos."}]}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekScreenTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD|tests completed'
WeekScreenTest > tickingASessionMovesTheTotal PASSED
BUILD SUCCESSFUL in 17s
```

Um teste, e ele cobre o que um estudante faz nesta tela: o total diz 45 de 160 antes, a caixa da
sessão de quarta está desmarcada, um toque a marca, e o total diz 135 de 160 depois, porque 90
minutos passaram de planejados a feitos. **Nada no teste sabe como o `WeekScreen` guarda ou calcula
qualquer coisa**; renomeie uma variável, divida o composable em dois, leve o total para um
`ViewModel` como a aula 10 faria, e o teste continua passando enquanto a tela se comportar.

## A regra que este curso usou, e a que a substitui

Todo teste de Compose anterior neste curso criou a regra com `createComposeRule()` de
`androidx.compose.ui.test.junit4`, e o teste acima também. Na versão do Compose que este curso fixa,
essa função está descontinuada, e o compilador avisa, num aviso fácil de passar batido porque o build
continua dando certo:

```
ana@vm:~/planner$ ./gradlew --console=plain compileDebugUnitTestKotlin --rerun 2>&1 | grep '^w: .*WeekScreenTest'
w: file:///home/ana/planner/app/src/test/java/com/example/planner/ui/WeekScreenTest.kt:33:26 'fun createComposeRule(effectContext: CoroutineContext = ...): ComposeContentTestRule' is deprecated. Use `androidx.compose.ui.test.junit4.v2.createComposeRule` instead. The v2 APIs use StandardTestDispatcher instead of UnconfinedTestDispatcher, which aligns with standard coroutine behavior by queuing tasks rather than executing them immediately. Tests relying on immediate execution may require explicit synchronization. Please refer to the migration guide for more details.
ana@vm:~/planner$ sed -i 's/junit4.createComposeRule/junit4.v2.createComposeRule/' app/src/test/java/com/example/planner/ui/WeekScreenTest.kt
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekScreenTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD|tests completed'
WeekScreenTest > tickingASessionMovesTheTotal PASSED
BUILD SUCCESSFUL in 16s
```

**O aviso é a explicação inteira**, e vale ler até o fim. A regra antiga roda as corrotinas lançadas
pela composição num `UnconfinedTestDispatcher`, que as executa na hora; a regra `v2` usa um
`StandardTestDispatcher`, que as enfileira e as roda quando o teste deixa o tempo andar, como o
`runTest` faz na aula 18 do curso `kotlin`. Um teste que contava com algo acontecendo na hora pode
então precisar de uma espera explícita, como `rule.waitForIdle()`. Este teste não precisou: trocar o
import foi a migração inteira, e ele passou sem mudança. As seções 05 e 06 usam a `v2` desde o
começo.

## Quando um localizador não encontra nada

A falha mais comum num teste de Compose é um localizador que não casa com nenhum nó, ou com mais de
um. Duas ferramentas dizem por quê. `rule.onRoot().printToLog("week")` escreve a árvore de semântica
inteira no log, com o texto, o papel e a tag de cada nó. E `useUnmergedTree = true` num localizador
olha dentro dos nós que o Compose juntou: uma `Row` com uma `Checkbox` e um `Text` pode aparecer como
um nó só com os dois textos, e o `AskTwiceTest` da aula 20 leu o texto da árvore juntada do mesmo
jeito.
