---
title: derivedStateOf, para um valor que muda menos que a fonte
version: 1
---

**O `derivedStateOf` transforma um valor que muda muito num que só muda quando o resultado muda.** A
semana do planner tem uma meta, 300 minutos. Um aviso diz *Keep going* até o total chegar a ela e
*Goal reached* depois. O aviso só precisa de um sim ou um não, mas o total muda a cada sessão
acrescentada, e um composable que lê o total roda de novo a cada uma dessas mudanças, para calcular o
mesmo `false` treze vezes seguidas.

O teste monta o aviso de dois jeitos, lado a lado. Um lê os minutos e os compara ele mesmo; o outro
lê `reached`, um estado derivado que recalcula `minutes >= GOAL` sempre que os minutos mudam mas só
avisa quem o lê quando a resposta é diferente. Os dois recebem uma lambda em vez de um valor, o jeito
de ler mais tarde da seção 02, e por isso a tela que é dona dos minutos também é contada:

```kotlin
// app/src/test/java/com/example/planner/DerivedTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

const val GOAL = 300

@Composable
fun GoalBanner(reached: Boolean, name: String) {
    SideEffect { count(name) }
    Text(if (reached) "Goal reached" else "Keep going")
}

@Composable
fun Banners() {
    var minutes by remember { mutableIntStateOf(0) }
    SideEffect { count("Banners") }
    val reached by remember { derivedStateOf { minutes >= GOAL } }
    Column {
        BannerFromMinutes({ minutes })
        BannerFromDerived({ reached })
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@Composable
fun BannerFromMinutes(minutes: () -> Int) {
    SideEffect { count("reads the minutes") }
    GoalBanner(minutes() >= GOAL, "banner below it")
}

@Composable
fun BannerFromDerived(reached: () -> Boolean) {
    SideEffect { count("reads the derived state") }
    GoalBanner(reached(), "banner below the derived one")
}

@RunWith(RobolectricTestRunner::class)
class DerivedTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun aDerivedStateChangesLessOften() {
        rule.setContent { Banners() }
        repeat(14) {
            rule.onNodeWithText("Add").performClick()
            rule.waitForIdle()
        }
        println("after 14 clicks of 25 minutes: $runs")
    }
}
```

Catorze cliques de 25 minutos levam o total de 0 a 350, passando da meta no décimo segundo:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*DerivedTest" 2>&1 | grep -E "after 14|^BUILD"
    after 14 clicks of 25 minutes: {Banners=1, reads the minutes=15, banner below it=2, reads the derived state=2, banner below the derived one=2}
BUILD SUCCESSFUL in 23s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" data-fig=\"l05-derived\" aria-label=\"Duas linhas de marcas contra catorze cliques, de 25 a 350 minutos. A linha de minutes tem uma marca em cada clique. A linha do valor derivado reached tem uma marca, no décimo segundo clique, 300 minutos, a meta.\"><defs></defs><text x=\"156\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">minutes mudou</text><line x1=\"162\" y1=\"70\" x2=\"663\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"167\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"204\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"241\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"278\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"315\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"352\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"389\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"426\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"463\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"500\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"537\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"574\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"611\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"648\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"156\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reached mudou</text><line x1=\"162\" y1=\"130\" x2=\"663\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"574\" y=\"118\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"172\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25</text><text x=\"209\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><text x=\"246\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">75</text><text x=\"283\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><text x=\"320\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">125</text><text x=\"357\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150</text><text x=\"394\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">175</text><text x=\"431\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><text x=\"468\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">225</text><text x=\"505\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">250</text><text x=\"542\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">275</text><text x=\"579\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300</text><text x=\"616\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">325</text><text x=\"653\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">350</text><text x=\"156\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minutos depois de cada clique</text><text x=\"579\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">300: a meta</text></svg>", "caption": "Catorze mudanças na fonte, uma mudança no valor derivado: quem o lê roda quando a resposta muda, não quando a entrada muda."}
```

**O composable que leu os minutos rodou 15 vezes; o que leu o estado derivado rodou duas**: uma no
começo, outra quando 275 virou 300 e `false` virou `true`. Os avisos abaixo dos dois rodaram duas
vezes, porque recebem um `Boolean` e são pulados enquanto ele não muda. E `Banners`, que é dona dos
minutos mas só passa lambdas para baixo, rodou uma vez: a leitura mais tarde da seção 02, medida.

## Quando vale a pena

O `derivedStateOf` tem um custo próprio: um objeto a mais, e o recálculo do bloco sempre que uma fonte
muda. Ele se paga quando **o resultado muda muito menos que a entrada**. O caso clássico é a lista da aula 8: a posição de rolagem muda a cada quadro de um arrasto rápido, e um botão de *voltar ao topo* só precisa saber se o primeiro item saiu da tela. Para um resultado que muda tanto quanto a
entrada, o `derivedStateOf` é puro desperdício: um `fullName` montado com nome e sobrenome muda sempre
que qualquer um dos dois muda, e uma expressão simples é o certo.

O `remember` em volta não é opcional. Sem ele o estado derivado é criado de novo a cada execução, o
erro da seção 02 da aula 4, e não conta nada.
