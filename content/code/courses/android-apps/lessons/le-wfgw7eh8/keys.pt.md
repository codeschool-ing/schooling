---
title: Chaves, para o estado lembrado acompanhar o item
version: 1
---

**Num laço, o Compose identifica cada chamada pela posição, a menos que você dê uma chave.** A aula 4
disse que o `remember` guarda um valor no nó do composable que o chamou. Dentro de um `for`, os nós são
casados com as chamadas pela ordem: a primeira chamada da próxima execução recebe o primeiro nó da
última, seja qual for o item que ela desenha agora. Insira um item no topo e cada nó depois dele recebe
um item diferente, com o estado lembrado do item antigo ainda dentro.

`SessionLine` lembra o rótulo com que foi desenhada pela primeira vez, o que torna o descasamento
visível. O teste desenha duas sessões, insere uma sessão de domingo antes delas e lê a tela, uma vez
com chamadas simples e outra com cada chamada envolvida em `key`:

```kotlin
// app/src/test/java/com/example/planner/KeyTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@Composable
fun SessionLine(label: String) {
    val firstSeen by remember { mutableStateOf(label) }
    Text("$label (remembered: $firstSeen)")
}

@RunWith(RobolectricTestRunner::class)
class KeyTest {
    @get:Rule
    val rule = createComposeRule()

    private fun lines() = rule.onAllNodesWithText("remembered", substring = true)
        .fetchSemanticsNodes().map { it.config[androidx.compose.ui.semantics.SemanticsProperties.Text].joinToString() }

    @Test
    fun withoutKeys() {
        val sessions = mutableStateListOf("Mon 45 min", "Tue 50 min")
        rule.setContent { Column { for (s in sessions) SessionLine(s) } }
        rule.runOnIdle { sessions.add(0, "Sun 25 min") }
        rule.waitForIdle()
        println("without key: ${lines()}")
    }

    @Test
    fun withKeys() {
        val sessions = mutableStateListOf("Mon 45 min", "Tue 50 min")
        rule.setContent { Column { for (s in sessions) key(s) { SessionLine(s) } } }
        rule.runOnIdle { sessions.add(0, "Sun 25 min") }
        rule.waitForIdle()
        println("with key:    ${lines()}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*KeyTest" 2>&1 | grep -E "key:|^BUILD"
    without key: [Sun 25 min (remembered: Mon 45 min), Mon 45 min (remembered: Tue 50 min), Tue 50 min (remembered: Tue 50 min)]
    with key:    [Sun 25 min (remembered: Sun 25 min), Mon 45 min (remembered: Mon 45 min), Tue 50 min (remembered: Tue 50 min)]
BUILD SUCCESSFUL in 13s
```

**Sem chaves, cada linha guarda o valor lembrado da linha que estava no lugar dela.** A linha de
domingo tem o valor de segunda, a de segunda tem o de terça, e o nó de terça é um nó novo no fim. Os
rótulos estão certos porque são argumentos; o que está errado é tudo o que as linhas *lembraram*, que
numa tela de verdade é se a linha estava expandida, um texto digitado pela metade nela, ou uma
animação em andamento. Com `key(s)`, o Compose casa os nós pela chave em vez da posição, as duas
linhas antigas ficam com os próprios nós, e só a de domingo é nova.

Uma chave precisa ser **estável e única**: o mesmo item dá a mesma chave em toda execução, e dois
itens nunca compartilham uma. As sessões do planner têm um `id` exatamente para isso, e a aula 8 o
passa à `LazyColumn`, cujos `items` aceitam uma `key` pelo mesmo motivo. O rótulo é a chave aqui só
porque os itens do teste são strings; duas sessões com o mesmo dia e os mesmos minutos colidiriam.
