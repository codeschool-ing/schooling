---
title: Escrevendo um layout seu
version: 1
---

**Quando nenhuma combinação de `Row`, `Column` e `Box` diz o que você quer, você mesmo conduz a
conversa da seção 05**, com `Layout`. Dá menos trabalho do que parece, porque o protocolo são os
mesmos três passos que todo contêiner segue: medir cada filho dentro de restrições que você escolhe,
decidir o próprio tamanho, posicionar os filhos.

O planner quer uma barra da semana: um bloco colorido por curso, tão largo quanto a parte dos minutos
da semana que aquele curso levou. Vinte e cinco minutos de Kotlin, noventa de Android e quarenta e
cinco de SQL deveriam dar blocos na proporção 25 para 90 para 45. Uma `Row` com pesos chegaria perto,
mas um peso é uma parte do que sobra depois dos filhos sem peso, e aqui cada filho tem uma parte do
todo. `Layout` diz isso diretamente:

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/ui/ProportionalRow.kt", "parts": [{"code": "// app/src/main/java/com/example/planner/ui/ProportionalRow.kt\npackage com.example.planner.ui\n\nimport androidx.compose.runtime.Composable\nimport androidx.compose.ui.Modifier\nimport androidx.compose.ui.layout.Layout\nimport androidx.compose.ui.unit.Constraints", "note": "`Layout` vem de `androidx.compose.ui.layout`, e `Constraints` é o tipo que a seção 05 imprimiu."}, {"code": "@Composable\nfun ProportionalRow(\n    shares: List<Int>,\n    modifier: Modifier = Modifier,\n    content: @Composable () -> Unit,\n) {", "note": "Um composable como qualquer outro: os dados, o `modifier` de costume e uma lambda `content` com os filhos, o slot que a aula 3 apresentou."}, {"code": "    Layout(content = content, modifier = modifier) { measurables, constraints ->\n        require(measurables.size == shares.size) { \"one share per child\" }\n        val total = shares.sum()\n        val width = constraints.maxWidth", "note": "`Layout` entrega os filhos como `measurables`, coisas que podem ser medidas uma vez, e as restrições que este layout recebeu. A largura a dividir é o máximo que ele pode ocupar."}, {"code": "        val placeables = measurables.mapIndexed { i, child ->\n            val childWidth = width * shares[i] / total\n            child.measure(Constraints(minWidth = childWidth, maxWidth = childWidth, maxHeight = constraints.maxHeight))\n        }", "note": "Passo um: medir. Cada filho recebe restrições cujo mínimo e máximo de largura são ambos a sua parte, então ele não escolhe a largura; a altura fica livre, até o que este layout pôde ter."}, {"code": "        val height = placeables.maxOf { it.height }\n        layout(width, height) {\n            var x = 0\n            placeables.forEach { placeable ->\n                placeable.placeRelative(x, 0)\n                x += placeable.width\n            }\n        }\n    }\n}", "note": "Passos dois e três: o tamanho deste layout é a largura toda e a altura do filho mais alto, e dentro de `layout(…)` os filhos são posicionados um depois do outro, cada um começando onde o anterior acabou."}]}
```

E o teste que desenha os três cursos de uma semana:

```kotlin
// app/src/test/java/com/example/planner/ProportionalRowTest.kt
package com.example.planner

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.unit.dp
import com.example.planner.ui.ProportionalRow
import com.github.takahirom.roborazzi.captureRoboImage
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(qualifiers = "w360dp-h80dp-xhdpi")
class ProportionalRowTest {
    @get:Rule val rule = createComposeRule()

    @Test fun theWeek() {
        val minutes = listOf(25, 90, 45)
        val colours = listOf(Color(0xFF81C784), Color(0xFF64B5F6), Color(0xFFFFB74D))
        rule.setContent {
            Surface {
                ProportionalRow(minutes, Modifier.padding(16.dp)) {
                    minutes.forEachIndexed { i, m ->
                        Box(Modifier.background(colours[i]).padding(8.dp)) { Text("$m") }
                    }
                }
            }
        }
        rule.onRoot().captureRoboImage("shots/proportional.png")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain recordRoborazziDebug --tests '*.ProportionalRowTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 25s
ana@vm:~/planner$ ls app/shots
arrangements.png
course-cards.png
modifier-order.png
proportional.png
session-rows.png
```

```schooling-figure
{"image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAACBCAYAAADpGo3nAAAP9UlEQVR4Xu3d+XNV53nA8fwfmdpgBAItgEBICAFCQhIIxCZLCCQWsdjG7BjCvhm8lMZLTGxKbAc7OGBCbMd2wG4zdmJnccZp6k7SaRPPZLOTaexmc9M2SaczeevnvT1H0vMe5PteiTk57/3+8Bnj+54jPFdzH3/nzLnv+dif/2gMAAAAgPx8TL8AAAAA4NoIaAAAAMADAQ0AAAB4IKABAAAADwQ0AAAA4IGABgAAADwQ0AAAAIAHAhoAAADwQEADAAAAHghoAAAAwAMBDQAAAHggoAEAAAAPBDQAAADggYAGAAAAPBDQAAAAgAcCGgAAAPBAQAMAAAAeCGgAAADAAwENAAAAeCCgAQAAAA8ENAAAAOCBgAYAAAA8ENAAAACABwIaAAAA8EBAAwAAAB4IaAAAAMADAQ0AAAB4IKABAAAADwQ0AAAA4IGABgAAADwQ0AAAAICH1AP6zm/fhb9AG6/+AQCQUeblRUCwdEumgYBGIj2MAQDZoYMDCIluyTQQ0EikhzEAIDt0cAAh0S2ZBgIaifQwBgBkhw4OICS6JdNAQCORHsYAgOzQwQGERLdkGghoJNLDGACQHTo4gJDolkwDAY1EehgDALJDBwcQEt2SaSCgkUgPYwBAdujgAEKiWzINBDQS6WEMAMgOHRxASHRLpoGARiI9jAEA2aGDAwiJbsk0ENBIpIcxACA7dHAAIdEtmQYCGon0MAYAZIcODiAkuiXTQEAjkR7GAIDs0MEBhES3ZBoIaCTSwxgAkB06OICQ6JZMAwGNRHoYAwCyQwcHEBLdkmkgoJFID2MAQHbo4ABColsyDQQ0EulhDADIDh0cQEh0S6aBgEYiPYwBANmhgwMIiW7JNBDQSKSHMQAgO3RwACHRLZkGAhqJ9DAGAGSHDg4gJLol00BAI5EexgCA7NDBAYREt2Qagg3og68cNXte3Gf2Xj1ojn7jTmcdQ9PDeKSs/cIvTc/5H5k1l37hrOVj3Zd+a3qf+rFZdfEds/7F3zvrAAACGmHTLZmGoAL6yGvHTc9dq0x1U435q4+PipWUlpqWvvlmx+XdzjkD3fHcHjOxriovR14PO8r1MB4OCd0FRy+bytnLBv1eyusWmAWHL324/p/OOVrXw2+aaUs3mxtHlcbnjymvMbPWnzSrnvqpczwAFDMdHNfDp7fWmuaaUuu7Dzc565GfPNkSH/dR/vTCQud8QNMtmYZgAlquONcvnh3H1ahRY0xl7WRTWjGh/7XRY8zGR25zzo3c/tktgwJvKEdeP+6cHxI9jAsl8Tyj90D8vt1wQ4kpnTzL/jN6TSJ4w5X/ds6NtB2+OOi9L62aY0rKquN/H1tRZ5affcs5DwCKlQ6Okfa9M3MHzeU3Hmx0jom8+VCj8//Qa/kjAY086JZMQzAB3bpuvv3wSST33LPGHPrqUfv6sW+dMLc/sc1UTJtk10vGjTN7rxxwzhd9D2zIBdmE8WbNfeuHFPptIXoYF6rt4Ofjwdi09bRZ+8X37etrLv+bmbXuRLw2/9AF51whYRzFdvXiTfb2D3ldgvvm02+Y8dW5IV5W22b6nv2Vcz4AFCMdHCNJrhIvmdV/cUoMFdBXT+Yubk0qHWNeuHPWkP73CgGNj6ZbMg1BBPSOS7viD3H30ZXOutj0eP/V5eXXOKb7zl67Pq21zlkrNnoYF0LuV5arw/Ke1vXsd9Ylgmes3GfX5ap033O/do6R82R9/NSmxEDuOvMP8e+1/cTzzjoAFCMdHCPpMzun25k7c/LYvAL6/L4Z9piupnJnDSiEbsk0BBHQXYdW2A/njTfcZA5/7ZizHpF7l+W45r75zppYvLPDrjf1tjprxUYP40J03P9aPFy7H/u+sy7kC4HRMUv++u8Gra17/gMzuqTSrrXc8Rnn3Mjk1tX2mNrOXc4aABQjHRwj5e3HW0zJqNHWlROz8gro+zflvpd0R1eVswYUQrdkGoII6EXbl5iyqgozfeFMZ22gWZ1z7Ie4safZWRMS1rLevn2ps1Zs9DAuRMvux+z7OeqmcrPhy//lrEcmze22xzXcemrQ6yvP/Us8nDs+9Q3nvEjT1ofsMXJvtF4DgGKkg2MkyO0Vva0Vdt6e2V5rfvREa14BvW9l7uLV39w6zVkDCqFbMg1BBHQ+jr9xMr4CvWzPzc66qGufaddXHO9x1oqNHsaFaNx8v30/ZbcNvTZQ/erD9ji5x3ng6wOvYK984m3nvIjs5BEdJ7eN6HUAKDY6OEbChf25WzEW1k+wX/bLN6BXz8tF9/m9M5w1oBC6JdNQNAG99fz2+IMuf9brIvqi4bI9nWbJrg5TPbfWjBk7zkyYXGmvWt9yZpMNcX1eiPQwLkTzzrP2/Rw9bvKQu2w03HKvPa5yTueg15fc+3L8O1t98V3nvEj7yRf6j7v0c2cdAIqNDo7hevepeaZi7E12zkZb1uUb0A1TctuPyrZ3D9xeYzoaykxZyU2mbuJYs6Nzsnntk3PMn19qd84DrkW3ZBqKIqBlx4zo6nJDV5OzHh0j91BHw+Ba2m5rD34HDqGHcSEWnXwxft9WnvtXZz0SXYEun7Fw0OsDw3ioB68suudqfJzcU63XAaDY6OAYDonbTUsm2hl794bq+PV8Alpu+xh9g/v/Uu1E31R24EDedEumoSgCWm7ZkA+obE/3iS/vd9bFvpcPxR/k8ZPKzcoTvWbzk9vMls9tN713rzaVNbmr06IYbvHQw7gQqy78LH7P9P3NkeVn/zHepk5fgZZdNaLzCWgAyJ8OjuGQ7eVkvs6uGmc+eGZB/Ho+Af3vl9riY2orx9rbQOQK9lsPzzVfOFRvGqvHxevc4oF86ZZMQ/ABveaT6+IP57pPbXTWI3Jrxu7n95q19683e1866KxLYE+qn2J/zriyCebgq0ecY0Kih3GhZq49at8ziWS5ohzdyiFfKpRbNORpgtHvZ0pb36BzCWgAKIwOjkK9//R8M7VsjJ2vr55qGLSWT0DL1et3zs+zO3bIz9LrEtit08fbn1E1ocT8/tk25xhA0y2ZhqAD+tZHb49vy+jY2+Ws+5KnGEbD4pazm5z1kOhhXCi5J7m8vj1+38bXtJopCzeYcVW5jfXl36vmr7F/1ntFFxLQqz7/E2cdAIqNDo5C7enOffk+aQu6fAI6H189NSf+Oa/fN8dZBzTdkmkINqC3XdhpnzooH8jW9W3m2DdPOMf4ksd3yyPC5WcuP7LCWQ+JHsbDseriO/EDUSJyRVpeky8HTm3faF+bu/3hQectvvel/jD+8GfonxsZeK/1UKENAMVCB0chXjnVYOeqXBl+76J79XikAlp29JB9peXnnNtT56wDmm7JNAQZ0Luf+4TdOUM+jHNWzP0wfEfuS39lU3NfpFi6O3krvFDoYTwSVj/9rul65Dum89Pftn+W19Z96Xd2lw77nt736qDjOx54PR7OPU/80Pl5kbbDT8fHJT3NEACKjQ4OXx98sc3MrMpdhGquKTUHe6c4tnb0fzdow8KJ8euF3IYR/V0Pbalx1gBNt2Qaggvo3L3KU+0HsX7x7CGfTDjQrmf22EeCy/l6LSK7b0RXoDsPLHfWQ6KH8fUi0SzvpzxsZc3l9watrfhs/4NUbn7w6865kcbND9pjeJAKAOTo4PD1T480xfPX128u91+tlqvUP3i02d7rrP+OiOy+EV2BlseE63VA0y2ZhqACWr7YVzsvt9F7dfN0c/Ar+X/Rr2F5bli0XOMx30KubEcDou/BDc56SPQwvh7kUd2VDbnHpzdsvCdxPXqUd/POM856pP9R3jucNQAoRjo4fEkEy73JQ4kerCLkyYTR6396oX87ui3Lclep9/dMcf6OyM+e7L8V5KW7ZjvrgKZbMg3BBLTcpjG7s9F+AOUKdNJOGkORbevkXNnqbu+VA866aN+2xB4jX0zce9Xv52eNHsYjbe0z75tpSzfb91N24rjW7hkzeg/YY+Tqct+zv3LWu8++FQ/ehceecdYBoBjp4Lge8rkHOorsSaVjzC8vzHPWxalbqu0xsl/0ewk7dQCabsk0BBHQx751wrRuWJALrYoJZtvFXebgK0eHdPi1wbd27P/7Q3b/Z/kZ0xfUmx2Xd8drR75+3O4FHe3osWDzYue/ITR6GA+X7Max8twP7K0YcjU52oXjxlGl9pHd+vhI199+N94netqyLYOeSNj92Pftw1fs731Ko41yfT4AFCMdHNdDPgEtV7Jl/2c5prelwrz9eEu89j8vLrR7QUcPWhn4kBZgKLol0xBEQG86tzX+EOerZX1b4s+Jdu4Q5dWTzPS2ehvl0Ws18+tsgOtzQ6OH8XBNblnl/A5ke7vlZ99yjtXm7XsyPkeCe2Lj8kFb48mXEG8+/YZzHgAUKx0c10M+AS3ePN0YPwZcyANZej6M6Wh/adE9t9z8x7P9D2kBhqJbMg1BBPRtj21x4uyjJAW0kIepyNqo0f0fbFFaWWaW7uksingWehgPlwS03M9cOXuZfXT3oruv2Huc9XHXIlepJ81dMeh3Ilemazq22S8b6uMBoJjp4Lge8g1oIQ9TkR06xv7/lwUj1RUl5vSWWuIZXnRLpiGIgL4e5BYPuY1D9pOWLw/KDhz6mJDpYTxc8uRB/VohZD9ouWrd/ej3nF07AAA5Ojj+Uvzh+QX2No5/PttsvzwoO3DoY4CPolsyDQQ0EulhDADIDh0cQEh0S6aBgEYiPYwBANmhgwMIiW7JNBDQSKSHMQAgO3RwACHRLZkGAhqJ9DAGAGSHDg4gJLol00BAI5EexgCA7NDBAYREt2QaCGgk0sMYAJAdOjiAkOiWTAMBjUR6GAMAskMHBxAS3ZJpIKCRSA9jAEB26OAAQqJbMg0ENBLpYQwAyA4dHEBIdEumgYBGIj2MAQDZoYMDCIluyTQQ0EikhzEAIDt0cAAh0S2ZBgIaifQwBgBkhw4OICS6JdNAQCORHsYAgOzQwQGERLdkGghoJNLDGACQHTo4gJDolkwDAY1EehgDALJDBwcQEt2SaSCgkUgPYwBAdujgAEKiWzINBDQS6WEMAMgOHRxASHRLpoGARiI9jAEA2aGDAwiJbsk0ENBIpIcxACA7dHAAIdEtmQYCGon0MAYAZIcODiAkuiXTQEAjkR7GAIDs0MEBhES3ZBoIaCTSwxgAkB06OICQ6JZMQ+oBDQAAAGQJAQ0AAAB4IKABAAAADwQ0AAAA4IGABgAAADwQ0AAAAIAHAhoAAADwQEADAAAAHghoAAAAwAMBDQAAAHggoAEAAAAPBDQAAADggYAGAAAAPBDQAAAAgAcCGgAAAPBAQAMAAAAeCGgAAADAAwENAAAAeCCgAQAAAA8ENAAAAOCBgAYAAAA8ENAAAACABwIaAAAA8EBAAwAAAB4IaAAAAMADAQ0AAAB4IKABAAAADwQ0AAAA4IGABgAAADwQ0AAAAIAHAhoAAADwQEADAAAAHv4PpsebBsayoJoAAAAASUVORK5CYII=", "alt": "Uma barra dividida em três blocos coloridos de larguras diferentes, marcados 25, 90 e 45, o do meio de longe o mais largo.", "caption": "Os minutos da semana como o ProportionalRow os desenhou: 25, 90 e 45 da largura da barra."}
```

**A divisão inteira custa pixels no fim.** 656 pixels divididos 25 para 90 para 45 não dão um número
inteiro de pixels por bloco, e `width * shares[i] / total` arredonda cada um para baixo, então os três
blocos podem terminar um ou dois pixels antes da borda direita. Para uma barra da semana não faz
diferença. Para um layout em que faça, o último filho fica com `width - x` em vez da parte calculada,
e o vão some.

Dois detalhes do código estão ali para quem for construir em cima dele. O `require` faz uma chamada
com o número errado de partes falhar alto, com uma mensagem, em vez de ler além do fim de uma lista.
`placeRelative` em vez de `place` espelha o posicionamento numa língua da direita para a esquerda,
como o `End` fez na seção 03, então o primeiro curso fica na borda direita para quem lê árabe.
