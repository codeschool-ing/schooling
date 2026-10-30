---
title: Por que uma lista longa não é uma Column longa
version: 1
---

**Uma `Column` compõe todo filho que recebe, quer alguém vá rolar até ele, quer não.** Para uma tela
de seis controles isso é exatamente o certo. Para um ano de sessões de estudo, significa construir,
medir e manter na memória centenas de linhas para mostrar a dúzia que cabe na tela. Acrescente um
modificador de rolagem e a `Column` rola perfeitamente; ela só faz todo o trabalho antes.

Uma `LazyColumn` compõe só as linhas que estão na tela, e compõe mais à medida que elas entram
rolando. Essa é a diferença inteira, e é fácil de ver contando. O teste abaixo dá mil linhas a cada
uma, cada linha com 48 dp de altura, e conta quantas vezes o conteúdo de uma linha roda:

```kotlin
// app/src/test/java/com/example/planner/LazinessTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(qualifiers = "w360dp-h640dp-xhdpi")
class LazinessTest {
    @get:Rule val rule = createComposeRule()

    @Test fun column() {
        var composed = 0
        rule.setContent {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                repeat(1000) { i ->
                    composed++
                    Text("Session $i", Modifier.height(48.dp))
                }
            }
        }
        rule.waitForIdle()
        println("Column: composed $composed rows of 1000")
    }

    @Test fun lazyColumn() {
        var composed = 0
        rule.setContent {
            LazyColumn {
                items(1000) { i ->
                    composed++
                    Text("Session $i", Modifier.height(48.dp))
                }
            }
        }
        rule.waitForIdle()
        println("LazyColumn: composed $composed rows of 1000")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.LazinessTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 36s
ana@vm:~/planner$ grep -h -e 'composed' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.LazinessTest.xml | sed 's/.*CDATA\[//'
Column: composed 1000 rows of 1000
LazyColumn: composed 14 rows of 1000
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l08-lazy\" aria-label=\"Duas listas com as mesmas 1000 linhas. À esquerda, uma Column compõe todas as linhas, 1000 de 1000, a maioria bem fora da tela. À direita, uma LazyColumn compõe só as linhas dentro da tela, 14 de 1000; as outras são contornos que ainda não existem.\"><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">Column</text><rect x=\"90\" y=\"40\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"50\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"60\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"70\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"80\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"90\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"100\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"110\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"120\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"130\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"140\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"150\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"160\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"170\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"180\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"190\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"200\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"210\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"220\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"230\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"240\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"250\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"260\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"270\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><text x=\"180\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">1000 de 1000 compostas</text><text x=\"180\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">todas as linhas, na tela ou não</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">LazyColumn</text><rect x=\"450\" y=\"40\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"50\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"60\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"70\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"80\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"90\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"100\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"110\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"120\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"130\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"140\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"150\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"160\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"170\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"180\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"190\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"200\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"210\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"220\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"230\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"240\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"250\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"260\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"270\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"440\" y=\"96\" width=\"200\" height=\"74\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"650\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">tela</text><text x=\"540\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">14 de 1000 compostas</text><text x=\"540\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">só o que a tela mostra</text></svg>", "caption": "As duas contagens que o teste imprimiu, fora de escala: os contornos à direita representam linhas que a LazyColumn nunca compôs."}
```

**Catorze contra mil.** A tela de mentira tem 640 dp de altura e cada linha 48 dp, então cabem treze
linhas e parte da décima quarta; a `LazyColumn` compôs exatamente essas. A `Column` compôs todas
antes de mostrar a primeira. Num celular, essa diferença é o tempo entre o toque e a lista aparecer,
e a memória que a lista segura enquanto está aberta.

Dois detalhes do teste merecem atenção. O `composed++` roda **dentro da composição**, o que a aula 3
disse que um composable de verdade nunca deve fazer, porque a composição pode rodar quantas vezes
for; num teste que está contando exatamente isso, é o objetivo. E `items(1000) { i -> … }` não é um
laço que roda mil vezes: ele diz à lista que há mil itens e lhe dá uma função para chamar nos que ela
precisar. **A lambda é a receita de uma linha, chamada sob demanda.**

O compilador imprimiu um aviso ao compilar estes testes: `createComposeRule` está obsoleto em favor
de uma versão `v2`, que roda corrotinas de outro jeito. Os testes desta aula ficam com o original,
que ainda funciona, e a aula 21 é onde o curso trata de testes.

`LazyRow` é a mesma coisa de lado, e `LazyVerticalGrid` arruma os itens em colunas. Tudo nesta aula
vale para os três.
