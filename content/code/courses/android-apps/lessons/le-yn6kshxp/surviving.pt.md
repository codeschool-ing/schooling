---
title: O que um ViewModel sobrevive
version: 1
---

**Girar o celular destrói a activity e constrói uma nova**, e a aula 2 viu isso acontecer:
`onDestroy`, depois um `onCreate` novo num objeto diferente. Tudo o que estiver na activity, ou num
`remember` simples de um composable, vai junto com o objeto antigo. A aula 4 guardou valores pequenos
através disso com `rememberSaveable`. O estado de uma tela inteira, com uma lista dentro, precisa de
um dono que não seja destruído de jeito nenhum, e é isso que a classe base ViewModel compra.

O mecanismo é um **`ViewModelStore`**: um mapa de uma chave para um ViewModel, que pertence à
activity mas é mantido através de uma mudança de configuração. Quando a activity antiga é destruída
*porque* a configuração mudou, o Android passa o store dela para a nova, e `viewModel()` encontra a
instância existente sob a mesma chave em vez de criar outra. Quando a activity é destruída de vez, o
store chama `onCleared()` em cada ViewModel e se esvazia.

## Vendo acontecer

Este teste abre o planner, digita 45 no campo, aperta **Add** e depois recria a activity do jeito que
uma rotação faz. Antes e depois, ele imprime a identidade da activity e do ViewModel que encontra:

```kotlin
// app/src/test/java/com/example/planner/RecreateTest.kt
package com.example.planner

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.lifecycle.ViewModelProvider
import com.example.planner.ui.WeekViewModel
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class RecreateTest {
    @get:Rule val rule = createAndroidComposeRule<MainActivity>()

    @Test fun theViewModelOutlivesTheActivity() {
        rule.onNodeWithText("Minutes").performTextInput("45")
        rule.onNodeWithText("Add").performClick()
        println("before: ${identities()}")
        rule.activityRule.scenario.recreate()
        println("after:  ${identities()}")
        rule.onNodeWithText("45 min this week, 0 of 1 done").assertExists()
    }

    private fun identities(): String {
        var text = ""
        rule.activityRule.scenario.onActivity { activity ->
            val viewModel = ViewModelProvider(activity)[WeekViewModel::class.java]
            text = "activity@%08x viewModel@%08x".format(
                System.identityHashCode(activity), System.identityHashCode(viewModel),
            )
        }
        return text
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*RecreateTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    (before|after|same)"
    before: activity@0fbb03f2 viewModel@173d8810
    after:  activity@56be6485 viewModel@173d8810
RecreateTest > theViewModelOutlivesTheActivity PASSED
BUILD SUCCESSFUL in 21s
30 actionable tasks: 1 executed, 29 up-to-date
```

**Duas activities diferentes, um ViewModel.** Os números são identity hash codes, diferentes a cada
execução; o que importa é qual deles mudou. A activity depois de `recreate()` é um objeto novo, e o
ViewModel que ela encontra é o mesmo, ainda com a sessão, então a tela que ela compõe do zero diz 45
minutos. `ViewModelProvider(activity)[WeekViewModel::class.java]` é a forma longa do que
`viewModel()` faz dentro de `WeekRoute`: o mesmo store, a mesma chave.

## O que sobrevive a quê

Um ViewModel sobrevive a uma mudança de configuração. Ele não sobrevive ao processo, e a diferença
importa porque o Android mata os processos de apps em segundo plano sempre que precisa de memória:

| onde o valor mora | rotação, modo escuro, um idioma novo | o processo morto em segundo plano | o estudante tira o app dos recentes |
|---|---|---|---|
| um campo da activity, ou `remember` | perdido | perdido | perdido |
| `rememberSaveable` (aula 4) | mantido | mantido | perdido |
| um ViewModel | mantido | **perdido** | perdido |
| `SavedStateHandle` num ViewModel (seção 05) | mantido | mantido | perdido |
| um banco de dados (aula 15) | mantido | mantido | mantido |

A terceira linha é a que as pessoas erram. **Um ViewModel não é armazenamento**; é um dono que por
acaso sobrevive ao jeito mais comum de uma activity morrer. A seção 05 mostra o caso do processo, e o
que o planner faz a respeito.
