---
title: Colours by role, not by name
version: 1
---

**A Material 3 app never asks for "green". It asks for `primary`**, and the theme decides what
`primary` is. That indirection is the whole design: the same screen code is drawn in the light
theme, the dark theme and a theme taken from the user's wallpaper, and none of the three needs a
line of it changed. A composable that writes `Color(0xFF2F6F4E)` into itself is the one that stays
green on a black background at night.

The colours come in **roles**, and the roles come in pairs. `primary` is the colour of the most
important control on a screen; `onPrimary` is the colour of whatever is drawn *on* `primary`, the
label of that button. `primaryContainer` is a quieter fill for something related, and
`onPrimaryContainer` is its text. `surface` is the background of cards and sheets, and `onSurface`
is the text on them. **Every `onX` exists to be readable on `X`**, and section 06 measures how
readable.

The planner's theme sets six of those roles for each mode, by hand, starting from the green the
`code` school uses as its accent:

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

`lightColorScheme` and `darkColorScheme` take over thirty roles, and every role not passed keeps
Material's default for that mode. Six is enough to make the planner recognisably its own; a real
product sets all of them, and Google's Material Theme Builder generates the full set from one seed
colour. It is a web page, and it was not used for this course.

`PlannerTheme` chooses one of three schemes and hands it to `MaterialTheme`, which makes it the
answer to `MaterialTheme.colorScheme` for everything drawn inside. **A theme is not global state**:
it is provided to the composables inside the `PlannerTheme { }` call, and a composable outside it
gets Material's defaults. Section 04 is about `isSystemInDarkTheme()` and section 05 about the
branch that reads `Build.VERSION.SDK_INT`.

Components read the roles for you. A `Button` fills itself with `primary` and writes its label in
`onPrimary`, an `OutlinedButton` draws its border and label from other roles, and a `Card` takes
its colours from `CardDefaults`, which the planner overrides below to use the container pair.
