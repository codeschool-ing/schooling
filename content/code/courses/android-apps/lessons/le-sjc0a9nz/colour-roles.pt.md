---
title: Cores por papel, não por nome
version: 1
---

**Um app Material 3 nunca pede "verde". Ele pede `primary`**, e o tema decide o que é `primary`.
Essa indireção é o desenho inteiro: o mesmo código de tela é desenhado no tema claro, no escuro e
num tema tirado do papel de parede do usuário, e nenhum dos três precisa mudar uma linha dele. Um
composable que escreve `Color(0xFF2F6F4E)` dentro de si é o que continua verde sobre fundo preto à
noite.

As cores vêm em **papéis**, e os papéis vêm aos pares. `primary` é a cor do controle mais
importante de uma tela; `onPrimary` é a cor do que é desenhado *sobre* `primary`, o rótulo daquele
botão. `primaryContainer` é um preenchimento mais discreto para algo relacionado, e
`onPrimaryContainer` é o texto dele. `surface` é o fundo de cartões e painéis, e `onSurface` é o
texto sobre eles. **Todo `onX` existe para ser legível sobre `X`**, e a seção 06 mede quão legível.

O tema do planner define seis desses papéis para cada modo, à mão, partindo do verde que a escola
`code` usa como destaque:

```kotlin
// app/src/main/java/com/example/planner/ui/theme/Theme.kt
package com.example.planner.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

val PlannerLight = lightColorScheme(
    primary = Color(0xFF2F6F4E),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFB2F1CD),
    onPrimaryContainer = Color(0xFF002112),
    surface = Color(0xFFF6FBF5),
    onSurface = Color(0xFF171D19),
)

val PlannerDark = darkColorScheme(
    primary = Color(0xFF96D5B1),
    onPrimary = Color(0xFF00391F),
    primaryContainer = Color(0xFF13512F),
    onPrimaryContainer = Color(0xFFB2F1CD),
    surface = Color(0xFF0F1511),
    onSurface = Color(0xFFDEE4DD),
)

@Composable
fun PlannerTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit,
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> PlannerDark
        else -> PlannerLight
    }
    MaterialTheme(
        colorScheme = colorScheme,
        typography = PlannerTypography,
        shapes = PlannerShapes,
        content = content,
    )
}
```

`lightColorScheme` e `darkColorScheme` recebem mais de trinta papéis, e todo papel não passado fica
com o padrão do Material para aquele modo. Seis bastam para o planner ficar reconhecível; um produto
real define todos, e o Material Theme Builder do Google gera o conjunto completo a partir de uma cor
semente. É uma página web, e não foi usada para este curso.

`PlannerTheme` escolhe um de três esquemas e o entrega ao `MaterialTheme`, que o torna a resposta de
`MaterialTheme.colorScheme` para tudo o que é desenhado dentro dele. **Um tema não é estado global**:
ele é fornecido aos composables de dentro da chamada `PlannerTheme { }`, e um composable fora dela
recebe os padrões do Material. A seção 04 é sobre `isSystemInDarkTheme()` e a seção 05 sobre o ramo
que lê `Build.VERSION.SDK_INT`.

Os componentes leem os papéis por você. Um `Button` se preenche com `primary` e escreve o rótulo em
`onPrimary`, um `OutlinedButton` tira a borda e o rótulo de outros papéis, e um `Card` tira as cores
de `CardDefaults`, que o planner sobrescreve abaixo para usar o par de contêiner.
