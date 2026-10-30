---
title: Modificadores são uma corrente, e a ordem é o significado
version: 1
---

**A imagem errada de um modificador é uma lista de configurações**: padding 16, fundo amarelo, como
se o elemento tivesse uma propriedade de padding e uma de fundo e o modificador as preenchesse. Com
essa imagem na cabeça, os dois textos abaixo deveriam sair iguais, já que cada um recebe as mesmas
duas configurações.

**A imagem certa é uma corrente de embrulhos, aplicada de fora para dentro.** Cada modificador
embrulha tudo o que vem escrito depois dele. `padding(16.dp).background(amber)` quer dizer "deixe 16
dp livres e, dentro disso, pinte o fundo". `background(amber).padding(16.dp)` quer dizer "pinte o
fundo e, dentro dele, deixe 16 dp livres antes do texto":

```kotlin
// app/src/test/java/com/example/planner/ModifierOrderTest.kt
package com.example.planner

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.unit.dp
import com.github.takahirom.roborazzi.captureRoboImage
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(qualifiers = "w360dp-h120dp-xhdpi")
class ModifierOrderTest {
    @get:Rule val rule = createComposeRule()

    @Test fun paddingAndBackground() {
        val amber = Color(0xFFFFD54F)
        rule.setContent {
            Surface {
                Row(Modifier.padding(16.dp)) {
                    Text("padding first", Modifier.padding(16.dp).background(amber))
                    Text("background first", Modifier.background(amber).padding(16.dp))
                }
            }
        }
        rule.onRoot().captureRoboImage("shots/modifier-order.png")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain recordRoborazziDebug --tests '*.ModifierOrderTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 16s
```

```schooling-figure
{"image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAiYAAAChCAYAAADz5HQPAAAWKUlEQVR4Xu3d+bskVX3Hcf+PPMkTcJBlVmGGmYGZgRlmvQNDlAwaUeMT8EFFRdxFcYEEBRfcUSSKCCqKC4io4wKICyguqJ2QnexmN6tms3I/1Tl9T3+6urrvre7Tp6feP7ye5z5dVX2rq8/51LdOLf2Yn/+0KAAAAHLwGH8BAABgVihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMgBYpOucCQC3PjdQoTIAW8QACAOe5kRqFCdAiHkAA4Dw3UqMwAVrEAwgAnOdGahQmQIt4AAGA89xIjcIEaBEPIABwnhupUZgALeIBBADOcyM1ChOgRTyAAMB5bqRGYQK0iAcQADjPjdQoTIAW8QACAOe5kRqFCdAiHkAA4Dw3UqMwAVrEAwgAnOdGahQmQIt4AAGA89xIjcIEaBEPIABwnhupUZgALeIBBADOcyM1ChOgRTyAAMB5bqRGYQK0iAcQADjPjdQoTIAW8QACAOe5kRqFCdAiHkAA4Dw3UqMwAVrEAwgAnOdGahQmQIt4AAGA89xIjcIEaBEPIABwnhupUZgALeIBBADOcyM1ChOgRTyAAMB5bqRGYQK0iAcQADjPjdQoTIAW8QACAOe5kRqFCdAiHkAA4Dw3UqMwAVrEAwgAnOdGahQmQIt4AAGA89xIjcIEaBEPIABwnhupUZgALeIBBADOcyM1ChOgRTyAAMB5bqTW+sLEvxBgmrz9pebrAwDOcyM1CpOKLwWYFm9/qfn6AIDz3EiNwqTiSwGmxdtfar4+AOA8N1KjMKn4UoBp8faXmq8PADjPjdQoTCq+FMyff37w7OKRu/YWv3PnnuJv718ofv6jQwPz5MDbX2q+PkBbzEtG5MBzIzUKk4ovJUeX/vrji1/8hV8uLjy8bmDaOOqW/++Hzyl+fN+Bueyof/ql/cVl///ZYvu2n1hc94rN2X0mb3+p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", "alt": "Dois textos numa superfície clara. À esquerda, padding first: o fundo amarelo justo nas letras, com espaço em volta. À direita, background first: um bloco amarelo maior, com espaço dentro dele em volta das palavras.", "caption": "Os mesmos dois modificadores nas duas ordens."}
```

O padding do texto da esquerda fica fora do fundo, então o amarelo fica justo nas letras e os 16 dp
em volta têm a cor da própria superfície. O padding do texto da direita fica dentro, então o amarelo
o cobre também. **Os mesmos dois modificadores, os mesmos valores, dois desenhos diferentes.**

## A mesma regra decide até onde vai um toque

`clickable` é um modificador como os outros, e a ordem decide o tamanho do alvo. Escrito antes do
`padding`, ele embrulha o padding, e um toque em qualquer lugar da área com padding conta. Escrito
depois, só a parte de dentro é alvo, e um dedo que cai no padding não faz nada. O curso
`mobile-fundamentals`, na aula 19, dá o alvo mínimo que as diretrizes do Google pedem, 48 dp; **pôr
o `clickable` primeiro é como um ícone pequeno ganha um alvo desse tamanho.**

## O parâmetro `modifier`, aplicado primeiro

O `SessionRow` da seção 02 recebe um parâmetro `modifier` e começa a própria corrente com ele:
`modifier.fillMaxWidth().padding(…)`. Essa ordem é a convenção, e tem motivo: os modificadores de
quem chama ficam por fora, então quem escreve `SessionRow(…, Modifier.padding(8.dp))` acrescenta
espaço fora da linha sem a linha precisar saber. Um composable que aplicasse o modificador de quem
chama por último, dentro do próprio padding, surpreenderia todo mundo que lê a assinatura dele.

**Passe o parâmetro `modifier` a exatamente um elemento: o mais de fora.** Passado a dois, o padding
de quem chama é aplicado duas vezes; passado a um filho de dentro, ele cai num lugar que quem chama
não vê.
