---
title: As restrições descem, os tamanhos sobem
version: 1
---

**O layout no Compose é uma conversa por elemento, feita uma vez por quadro.** O pai diz a cada
filho o menor e o maior tamanho que ele pode ter, o filho escolhe um tamanho dentro desses limites e
avisa, e então o pai decide onde colocá-lo. Os limites se chamam **restrições** (*constraints*), e
um filho não pode responder fora deles. Esse é o protocolo inteiro, e cada contêiner desta aula é um
jeito diferente de conduzir a conversa.

O jeito mais fácil de acreditar é assistir. `Modifier.layout` deixa um modificador participar da
conversa, e o teste abaixo o usa para imprimir o que cada elemento recebeu e o que ocupou:

```kotlin
// app/src/test/java/com/example/planner/ConstraintsTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.layout
import androidx.compose.ui.test.junit4.createComposeRule
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(qualifiers = "w360dp-h240dp-xhdpi")
class ConstraintsTest {
    @get:Rule val rule = createComposeRule()

    private fun Modifier.logged(name: String) = layout { measurable, constraints ->
        val placeable = measurable.measure(constraints)
        println("$name: given $constraints, took ${placeable.width}x${placeable.height}")
        layout(placeable.width, placeable.height) { placeable.place(0, 0) }
    }

    @Test fun whoAsksForWhat() {
        rule.setContent {
            Column(Modifier.logged("Column")) {
                Text("Kotlin", Modifier.logged("Text"))
                Text("Kotlin", Modifier.fillMaxWidth().logged("Text after fillMaxWidth"))
                Row(Modifier.logged("Row")) {
                    Text("Kotlin", Modifier.weight(1f).logged("weighted Text"))
                    Text("90 min", Modifier.logged("Text beside it"))
                }
            }
        }
        rule.waitForIdle()
    }
}
```

`measurable.measure(constraints)` repassa as restrições sem mudar nada e recebe a resposta do filho
como um `Placeable`; o modificador relata e depois ocupa o mesmo tamanho. O Gradle guarda o que um
teste imprimiu no arquivo de resultado que escreve para cada classe de teste:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.ConstraintsTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 20s
ana@vm:~/planner$ grep "given" app/build/test-results/testDebugUnitTest/TEST-com.example.planner.ConstraintsTest.xml | sed "s/.*CDATA\[//"
Text: given Constraints(minWidth = 0, maxWidth = 720, minHeight = 0, maxHeight = 480), took 72x33
Text after fillMaxWidth: given Constraints(minWidth = 720, maxWidth = 720, minHeight = 0, maxHeight = 447), took 720x33
Text beside it: given Constraints(minWidth = 0, maxWidth = 720, minHeight = 0, maxHeight = 414), took 86x33
weighted Text: given Constraints(minWidth = 634, maxWidth = 634, minHeight = 0, maxHeight = 414), took 634x33
Row: given Constraints(minWidth = 0, maxWidth = 720, minHeight = 0, maxHeight = 414), took 720x33
Column: given Constraints(minWidth = 0, maxWidth = 720, minHeight = 0, maxHeight = 480), took 720x99
```

Os números são pixels, porque o layout trabalha em pixels: a tela de mentira tem 360 dp de largura a
dois pixels por `dp`, então 720. Leia as linhas aos pares.

- **`Text`**: recebeu qualquer largura de 0 a 720 e ocupou só o que a palavra precisa. Um `Text` tem
  a largura do conteúdo, a não ser que digam outra coisa.
- **`Text after fillMaxWidth`**: recebeu mínimo e máximo de 720. O `fillMaxWidth` não estica o
  texto; ele reescreve as restrições para que a única resposta permitida seja a largura inteira.
  **Um modificador de tamanho funciona estreitando o que o próximo elemento da corrente pode
  escolher.**
- **Os dois filhos da `Row`** aparecem na ordem inversa à do código, e isso é a seção 06.
- **A `Column`** aparece por último. O tamanho dela depende dos filhos, então ela os mede primeiro e
  responde depois: tão larga quanto o filho mais largo, e tão alta quanto os três empilhados.

Repare também no `maxHeight` descendo pela lista: 480, depois menos para cada filho a partir do
primeiro. Uma `Column` entrega a cada filho a altura que os anteriores não usaram.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l06-pass\" aria-label=\"Uma Row mede os filhos em duas rodadas. Primeiro entrega ao filho sem peso a largura inteira, um máximo de 720 pixels, e o filho responde com o seu tamanho, 86 por 33. Depois entrega ao filho com peso exatamente o que sobrou, 720 menos 86. As restrições descem, os tamanhos sobem, e o pai os posiciona depois.\"><defs><marker id=\"l06-pass-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-pass-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l06-pass-w\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"20\" width=\"220\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">Row</text><rect x=\"60\" y=\"200\" width=\"240\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">Text(\"90 min\")</text><rect x=\"420\" y=\"200\" width=\"240\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">Text, weight(1f)</text><line x1=\"280\" y1=\"72\" x2=\"170\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#l06-pass-a)\"></line><text x=\"120\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">1. restrições descem</text><text x=\"120\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">max 720 px</text><line x1=\"205\" y1=\"196\" x2=\"305\" y2=\"74\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#l06-pass-p)\"></line><text x=\"220\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">2. tamanho sobe</text><text x=\"220\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">86 x 33</text><line x1=\"440\" y1=\"72\" x2=\"540\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#l06-pass-a)\"></line><text x=\"520\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">3. o que sobrou</text><text x=\"520\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">= 720 - 86</text><text x=\"360\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Cada um medido uma vez, nesta ordem; posicionados depois, da esquerda para a direita.</text></svg>", "caption": "A ordem que a saída do teste imprimiu: o filho sem peso é medido primeiro, e o com peso recebe o restante."}
```

## Medido uma vez, e isso é regra, não costume

**O Compose mede cada filho no máximo uma vez por passada de layout**, e pedir duas vezes é um erro,
não um caminho lento. O sistema de views antigo do Android deixava um pai medir um filho várias
vezes, e o aninhamento profundo podia multiplicar o trabalho: um layout de dez níveis, cada um
medindo duas vezes, mede o elemento mais interno mais de mil vezes. Com uma medição cada, aninhar não
custa nada a mais, e é por isso que código Compose aninha `Row` em `Column` em `Box` sem pensar duas
vezes. Quando um pai precisa mesmo saber o tamanho de um filho antes de medi-lo, o Compose tem as
medições *intrínsecas*, uma pergunta mais barata feita sem medir. Este curso não precisa delas, e a
documentação do Google sobre medições intrínsecas nos layouts do Compose as cobre.
