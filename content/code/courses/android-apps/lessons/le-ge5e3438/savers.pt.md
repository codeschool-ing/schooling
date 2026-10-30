---
title: O que cabe num Bundle, e um Saver para o que não cabe
version: 1
---

**O `rememberSaveable` só salva o que um `Bundle` consegue guardar**: números, strings, booleanos,
arrays e listas desses, e objetos que implementam `Parcelable` ou `Serializable`. Um rascunho do
planner, o curso e os minutos que alguém está no meio de preencher, é uma data class, e uma data class
não é nada disso. O Compose só descobre quando tenta salvá-la.

Um teste consegue fazê-lo tentar. O `StateRestorationTester`, da biblioteca de testes do Compose, roda
um composable, salva o estado dele do jeito que uma activity faria antes de ser destruída, e o
restaura numa composição nova, sem activity nenhuma:

```kotlin
// app/src/test/java/com/example/planner/SaverTest.kt
package com.example.planner

import androidx.compose.material3.Text
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.test.junit4.StateRestorationTester
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

data class Draft(val courseId: String, val minutes: Int)

@RunWith(RobolectricTestRunner::class)
class SaverTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun aDraftSurvivesASaveAndRestore() {
        val tester = StateRestorationTester(rule)
        tester.setContent {
            val draft = rememberSaveable { mutableStateOf(Draft("kotlin", 45)) }
            Text(draft.value.toString())
        }
        tester.emulateSavedInstanceStateRestore()
        rule.onNodeWithText("Draft(courseId=kotlin, minutes=45)").assertExists()
    }
}
```

O teste falha, e a mensagem está no relatório do teste:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*SaverTest" 2>&1 | grep -E "FAILED|Exception|tests completed|^BUILD"
SaverTest > aDraftSurvivesASaveAndRestore FAILED
    java.lang.IllegalArgumentException at SaverTest.kt:25
> Task :app:testDebugUnitTest FAILED
BUILD FAILED in 25s
ana@vm:~/planner$ grep -o "message=\"[^\"]*\"" app/build/test-results/testDebugUnitTest/TEST-com.example.planner.SaverTest.xml
message="java.lang.IllegalArgumentException: MutableState containing Draft(courseId=kotlin, minutes=45) cannot be saved using the current SaveableStateRegistry. The default implementation only supports types which can be stored inside the Bundle. Please consider implementing a custom Saver for this class and pass it as a stateSaver parameter to rememberSaveable()."
```

**A mensagem é exata: o tipo não cabe num `Bundle`, e a cura é um `Saver`.** Um `Saver` são duas
funções: uma transforma o valor em algo que um `Bundle` guarda, a outra transforma isso de volta no
valor. O `listSaver` monta um a partir de uma lista, que é o caminho mais curto para uma classe
pequena:

```kotlin
// app/src/test/java/com/example/planner/SaverTest.kt
package com.example.planner

import androidx.compose.material3.Text
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.test.junit4.StateRestorationTester
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

data class Draft(val courseId: String, val minutes: Int)

val DraftSaver = listSaver<Draft, Any>(
    save = { listOf(it.courseId, it.minutes) },
    restore = { Draft(it[0] as String, it[1] as Int) },
)

@RunWith(RobolectricTestRunner::class)
class SaverTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun aDraftSurvivesASaveAndRestore() {
        val tester = StateRestorationTester(rule)
        tester.setContent {
            val draft = rememberSaveable(saver = DraftSaver) { Draft("kotlin", 45) }
            Text(draft.toString())
        }
        tester.emulateSavedInstanceStateRestore()
        rule.onNodeWithText("Draft(courseId=kotlin, minutes=45)").assertExists()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*SaverTest" 2>&1 | grep -E "FAILED|tests completed|^BUILD"
BUILD SUCCESSFUL in 39s
```

O `save` devolve uma lista com uma `String` e um `Int`, que um `Bundle` guarda; o `restore` recebe essa
lista de volta e reconstrói o rascunho. O `mapSaver` faz o mesmo com entradas nomeadas, o que se lê
melhor a partir de dois ou três campos. O rascunho agora é guardado diretamente, e não dentro de um
`mutableStateOf`, porque o teste só o lê; um rascunho que a tela edita seria
`rememberSaveable(stateSaver = DraftSaver) { mutableStateOf(…) }`, o parâmetro que a mensagem de erro
citou.

## Os outros dois caminhos, e um tamanho para não passar

**`@Parcelize`** gera uma implementação de `Parcelable` para uma data class, e aí o `rememberSaveable`
a aceita sem `Saver` nenhum. Ele precisa do plugin `kotlin-parcelize` do Gradle, que o catálogo deste
curso não traz; a documentação do Google o mostra, e ele não foi executado aqui.

**Mantenha pequeno, seja qual for o caminho.** A seção 05 da aula 2 deu o número do Google: estado
salvo abaixo de 50 kB, porque o `Bundle` passa de um processo para outro. Um rascunho de dois campos
tem poucos bytes. Uma lista de todas as sessões que o estudante já registrou não é um rascunho, e
pertence ao banco de dados da aula 15.
