---
title: Contrast, measured rather than judged by eye
version: 1
---

**A colour pair either meets the contrast WCAG asks for or it does not, and that is arithmetic.**
The Web Content Accessibility Guidelines, which Android's own accessibility guidance follows,
define the contrast between two colours as the ratio of their relative luminances, each plus 0.05.
Normal text needs **4.5:1** at level AA; large text needs 3:1. A pair that looks fine on your screen
in your light can fail for somebody with low vision, on a cheap display, in sunlight.

Compose gives every `Color` its relative luminance with `luminance()`, so the ratio is three lines of
Kotlin, and a unit test with no Android in it at all can check every pair the planner relies on:

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

This test needs no Robolectric and no `@RunWith`: it reads two `ColorScheme` objects and does
arithmetic, so it runs on the plain JVM.

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

**All eight pairs pass, and the weakest is `primary on surface` in the light theme, 5.72:1.** That
pair matters because `primary` is not only a fill: an `OutlinedButton` and a text link draw their
words in `primary` straight on the surface. The dark scheme's pale `primary` passes the same check
at 10.96:1.

The test fails the build if a pair drops below 4.5, so the next person to adjust a colour finds out
before a student does. **A theme with a test like this is a promise; without one it is an
intention.**

## And the scheme nobody wrote

Section 05's test measured one pair of the dynamic scheme as well: `onPrimaryContainer` on
`primaryContainer` came out at 4.67:1, just over the line, for the colours Robolectric's Android 15
produced. On a phone those colours come from a wallpaper, so no test you can write knows them in
advance. Google designs the dynamic schemes so that the `onX` roles are readable on their `X`, and
that is a property of their algorithm you rely on rather than check. **It is a reason to use the
roles exactly as named**: put `onPrimaryContainer` text on a `primary` background and nobody has
promised you anything.
