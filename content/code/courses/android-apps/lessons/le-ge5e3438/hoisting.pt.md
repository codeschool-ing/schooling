---
title: Elevar o estado: quem é dono do valor
version: 1
---

**Elevar o estado (*state hoisting*) é tirá-lo de um composable e levá-lo para quem o chama, passando
o valor para baixo e uma função para mudá-lo.** Cada um dos contadores acima é dono do próprio
número, e nada de fora consegue lê-lo nem alterá-lo. O planner precisa do contrário: a tela de uma
sessão nova tem um seletor de minutos, e quem precisa saber o número é a tela, não o seletor, para
mostrá-lo, conferi-lo e um dia salvá-lo.

Então o seletor fica sem estado, o formato da aula 3, com mais um parâmetro, o evento:

```kotlin
// app/src/main/java/com/example/planner/ui/NewSession.kt
package com.example.planner.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.res.stringResource
import com.example.planner.R

@Composable
fun MinutesPicker(minutes: Int, onMinutesChange: (Int) -> Unit) {
    Row {
        TextButton(onClick = { onMinutesChange(minutes - 5) }, enabled = minutes > 5) {
            Text(stringResource(R.string.five_less))
        }
        Text(stringResource(R.string.minutes, minutes))
        TextButton(onClick = { onMinutesChange(minutes + 5) }) {
            Text(stringResource(R.string.five_more))
        }
    }
}

@Composable
fun NewSession() {
    var minutes by rememberSaveable { mutableIntStateOf(25) }
    Column {
        MinutesPicker(minutes, onMinutesChange = { minutes = it })
        Text(stringResource(R.string.planned, minutes))
    }
}
```

```xml
<!-- app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Planner</string>
    <string name="welcome">No courses yet. Add the first one.</string>
    <string name="add_25_minutes">Add 25 minutes</string>
    <string name="five_less">5 min less</string>
    <string name="five_more">5 min more</string>
    <string name="minutes">%1$d min</string>
    <string name="planned">Planned: %1$d min</string>
</resources>
```

O `MinutesPicker` não consegue mudar o número; ele só pode **pedir**, chamando `onMinutesChange` com o
número que gostaria. O `NewSession` é dono do estado, decide aceitar o pedido escrevendo-o, e o valor
novo volta para baixo na próxima recomposição. Aqui ele aceita tudo; uma versão posterior poderia
recusar mais de 240 minutos num único lugar, sem o seletor saber. Um teste aperta o botão duas vezes e
lê o que o dono mostra:

```kotlin
// app/src/test/java/com/example/planner/HoistingTest.kt
package com.example.planner

import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.example.planner.ui.NewSession
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class HoistingTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun theOwnerSeesWhatThePickerAskedFor() {
        rule.setContent { NewSession() }
        repeat(2) { rule.onNodeWithText("5 min more").performClick() }
        rule.onNodeWithText("Planned: 35 min").assertExists()
        println("the owner shows: Planned: 35 min")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*HoistingTest" 2>&1 | grep -E "owner shows|^BUILD"
    the owner shows: Planned: 35 min
BUILD SUCCESSFUL in 29s
```

**Eleve o estado até o composable mais baixo sob o qual estão todos os que o leem e o escrevem**, e
não mais alto. O `NewSession` é esse ponto para os minutos: o seletor os escreve e a linha de resumo
os lê. Elevar até a `MainActivity` funcionaria e faria todas as telas recomporem quando um seletor se
mexesse. Quando a aula 10 acrescentar um `ViewModel`, ele vira o dono dos dados da tela, e o próprio
`NewSession` fica sem estado, repassando os mesmos `minutes` e `onMinutesChange`.
