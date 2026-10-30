---
title: Contraste, medido em vez de julgado a olho
version: 1
---

**Um par de cores atinge o contraste que a WCAG pede ou não atinge, e isso é aritmética.** As Web
Content Accessibility Guidelines, que as orientações de acessibilidade do próprio Android seguem,
definem o contraste entre duas cores como a razão entre as luminâncias relativas delas, cada uma mais
0,05. Texto normal precisa de **4,5:1** no nível AA; texto grande precisa de 3:1. Um par que parece
bom na sua tela, na sua luz, pode falhar para alguém com baixa visão, numa tela barata, sob o sol.

O Compose dá a toda `Color` a luminância relativa com `luminance()`, então a razão são três linhas de
Kotlin, e um teste de unidade sem Android nenhum consegue conferir cada par de que o planner depende:

```kotlin
// app/src/test/java/com/example/planner/ContrastTest.kt
package com.example.planner

import androidx.compose.material3.ColorScheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import com.example.planner.ui.theme.PlannerDark
import com.example.planner.ui.theme.PlannerLight
import org.junit.Assert.assertTrue
import org.junit.Test

class ContrastTest {
    private fun ratio(a: Color, b: Color): Double {
        val (light, dark) = listOf(a.luminance(), b.luminance()).sortedDescending()
        return (light + 0.05) / (dark + 0.05)
    }

    private fun check(name: String, s: ColorScheme) {
        val pairs = listOf(
            "onPrimary on primary" to ratio(s.onPrimary, s.primary),
            "onPrimaryContainer on primaryContainer" to ratio(s.onPrimaryContainer, s.primaryContainer),
            "onSurface on surface" to ratio(s.onSurface, s.surface),
            "primary on surface" to ratio(s.primary, s.surface),
        )
        pairs.forEach { (pair, r) ->
            println("%-6s %-40s %5.2f:1".format(name, pair, r))
            assertTrue("$name $pair is $r", r >= 4.5)
        }
    }

    @Test fun light() = check("light", PlannerLight)
    @Test fun dark() = check("dark", PlannerDark)
}
```

Este teste não precisa de Robolectric nem de `@RunWith`: ele lê dois objetos `ColorScheme` e faz
contas, então roda na JVM pura.

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.ContrastTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 4s
ana@vm:~/planner$ grep ":1" app/build/test-results/testDebugUnitTest/TEST-com.example.planner.ContrastTest.xml | sed "s/.*CDATA\[//"
dark   onPrimary on primary                      7.76:1
dark   onPrimaryContainer on primaryContainer    7.28:1
dark   onSurface on surface                     14.31:1
dark   primary on surface                       10.96:1
light  onPrimary on primary                      5.99:1
light  onPrimaryContainer on primaryContainer   13.34:1
light  onSurface on surface                     16.34:1
light  primary on surface                        5.72:1
```

**Os oito pares passam, e o mais fraco é `primary on surface` no tema claro, 5,72:1.** Esse par
importa porque `primary` não é só preenchimento: um `OutlinedButton` e um link de texto desenham as
palavras em `primary` direto sobre a superfície. O `primary` claro do esquema escuro passa na mesma
conferência com 10,96:1.

O teste derruba o build se um par cair abaixo de 4,5, então a próxima pessoa que ajustar uma cor
descobre antes de um estudante. **Um tema com um teste assim é uma promessa; sem ele, é uma
intenção.**

## E o esquema que ninguém escreveu

O teste da seção 05 mediu também um par do esquema dinâmico: `onPrimaryContainer` sobre
`primaryContainer` deu 4,67:1, um pouco acima do limite, para as cores que o Android 15 do
Robolectric produziu. Num celular essas cores vêm de um papel de parede, então nenhum teste que você
escreva as conhece de antemão. O Google desenha os esquemas dinâmicos para que os papéis `onX` sejam
legíveis sobre o seu `X`, e essa é uma propriedade do algoritmo deles em que você confia, não que você
confere. **É um motivo para usar os papéis exatamente como nomeados**: ponha texto
`onPrimaryContainer` sobre um fundo `primary` e ninguém prometeu nada a você.
