---
title: Tipo e forma, e a tela que os lê
version: 1
---

**Tipografia e forma também são papéis.** O Material 3 nomeia quinze estilos de texto, de
`displayLarge` até `labelSmall`, em cinco grupos de três tamanhos: display, headline, title, body e
label. Uma tela pede `titleMedium` e o tema diz o que é `titleMedium`. As formas funcionam do mesmo
jeito, com tamanhos de canto de `extraSmall` a `extraLarge`, e os componentes escolhem o seu: um
`Card` usa `medium`.

O planner muda dois estilos de texto e uma forma. Como nos esquemas de cor, tudo o que não é passado
fica com o padrão do Material:

```kotlin
// app/src/main/java/com/example/planner/ui/theme/Type.kt
package com.example.planner.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

val PlannerTypography = Typography(
    headlineSmall = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 24.sp, lineHeight = 32.sp),
    titleMedium = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 16.sp, lineHeight = 24.sp),
)

val PlannerShapes = Shapes(
    medium = RoundedCornerShape(16.dp),
)
```

`sp` é o `dp` do texto: **um pixel independente de escala acompanha o tamanho de fonte que a pessoa
escolheu nas configurações do celular**, então quem pediu texto maior também o recebe no seu app.
Escreva tamanhos de texto em `sp` e todo o resto em `dp`; um título em `dp` continua pequeno para
quem precisava dele maior.

Eis uma tela que usa tudo isso, o topo da semana do planner: um título, um cartão com os minutos da
semana e dois botões. **Ela nomeia papéis e estilos, e nenhuma cor ou tamanho próprio**, e é isso
que deixa as próximas três seções a redesenharem sem tocar nela:

```kotlin
// app/src/main/java/com/example/planner/ui/WeekSummary.kt
package com.example.planner.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun WeekSummary(planned: Int, done: Int, modifier: Modifier = Modifier) {
    Column(modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("This week", style = MaterialTheme.typography.headlineSmall)
        Card(
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer,
                contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
            ),
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column(Modifier.padding(16.dp)) {
                Text("$planned min planned", style = MaterialTheme.typography.titleMedium)
                Text("$done min done", style = MaterialTheme.typography.bodyMedium)
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = {}) { Text("Add session") }
            OutlinedButton(onClick = {}) { Text("See courses") }
        }
    }
}
```

`CardDefaults.cardColors` é como um componente deixa você escolher outros papéis. Um `Card` sozinho é
desenhado num dos papéis de superfície; este pede o par de contêiner, então se destaca da superfície
atrás dele nos dois modos. O `contentColor` é herdado por tudo dentro do cartão, e é por isso que as
duas chamadas de `Text` nele não nomeiam cor.

`Text("This week")` quebra a regra da aula 1 de que os textos do planner moram no `strings.xml`. Ele
fica literal nesta aula para a tela e o teste caberem numa página; no app, as cinco strings dela vão
para o `strings.xml` como as outras.
