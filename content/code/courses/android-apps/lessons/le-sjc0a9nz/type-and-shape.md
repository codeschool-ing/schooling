---
title: Type and shape, and the screen that reads them
version: 1
---

**Typography and shape are roles too.** Material 3 names fifteen text styles, from `displayLarge`
down to `labelSmall`, in five groups of three sizes: display, headline, title, body and label. A
screen asks for `titleMedium` and the theme says what `titleMedium` is. Shapes work the same way,
with corner sizes from `extraSmall` to `extraLarge`, and components pick theirs: a `Card` uses
`medium`.

The planner changes two text styles and one shape. Like the colour schemes, everything not passed
keeps Material's default:

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

`sp` is `dp` for text: **a scale-independent pixel follows the font size the person chose in the
phone's settings**, so a reader who asked for larger text gets it in your app too. Write text sizes
in `sp` and everything else in `dp`; a heading in `dp` stays small for the person who needed it
bigger.

Here is a screen that uses all of it, the top of the planner's week: a heading, a card with the
week's minutes, and two buttons. **It names roles and styles, and not one colour or size of its
own**, which is what lets the next three sections redraw it without touching it:

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

`CardDefaults.cardColors` is how a component lets you choose different roles. A `Card` alone is
drawn in one of the surface roles; this one asks for the container pair, so it stands out from the
surface behind it in either mode. `contentColor` is inherited by everything inside the card, which is
why the two `Text` calls in it name no colour.

`Text("This week")` breaks lesson 1's rule that the planner's text lives in `strings.xml`. It is
kept literal in this lesson so that the screen and its test fit on one page; in the app, its five
strings go in `strings.xml` like the rest.
