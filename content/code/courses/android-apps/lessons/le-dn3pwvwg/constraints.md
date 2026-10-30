---
title: Constraints go down, sizes come up
version: 1
---

**Layout in Compose is one conversation per element, held once per frame**: the parent tells each
child the smallest and largest size it may be, the child picks a size inside those limits and says
so, and then the parent decides where to put it. The limits are called **constraints**, and a child
may not answer outside them. That is the whole protocol, and every container in this lesson is a
different way of holding the conversation.

The easiest way to believe it is to watch it. `Modifier.layout` lets a modifier take part in the
conversation, and the test below uses it to print what each element was given and what it took:

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

`measurable.measure(constraints)` passes the constraints through unchanged and gets the child's
answer back as a `Placeable`; the modifier reports it, and then takes the same size itself. Gradle
keeps what a test printed in the result file it writes for each test class:

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

The numbers are pixels, because layout works in pixels: the pretend screen is 360 dp wide at two
pixels per `dp`, so 720. Read the lines in pairs.

- **`Text`**: given any width from 0 to 720, it took only what the word needs. A `Text` is as wide
  as its content unless told otherwise.
- **`Text after fillMaxWidth`**: given a minimum and maximum both of 720. `fillMaxWidth` does not
  stretch the text; it rewrites the constraints so that the only answer allowed is the full width.
  **A size modifier works by narrowing what the next element in the chain may choose.**
- **The `Row`'s two children** arrive in the opposite order from the code, and that is section 06.
- **`Column`** is printed last of all. Its own size depends on its children's, so it measures them
  first and answers afterwards: as wide as its widest child, and as tall as the three stacked.

Look at `maxHeight` going down the list, too: 480, then less for each child after the first. A
`Column` hands each child the height its earlier children have not used.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l06-pass\" aria-label=\"A Row measures its children in two rounds. First it hands the unweighted child the whole width, a maximum of 720 pixels, and the child answers with its size, 86 by 33. Then it hands the weighted child exactly what is left, 720 minus 86. Constraints go down, sizes come back up, and the parent places them afterwards.\"><defs><marker id=\"l06-pass-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-pass-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l06-pass-w\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"20\" width=\"220\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">Row</text><rect x=\"60\" y=\"200\" width=\"240\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">Text(\"90 min\")</text><rect x=\"420\" y=\"200\" width=\"240\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">Text, weight(1f)</text><line x1=\"280\" y1=\"72\" x2=\"170\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#l06-pass-a)\"></line><text x=\"120\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">1. constraints down</text><text x=\"120\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">max 720 px</text><line x1=\"205\" y1=\"196\" x2=\"305\" y2=\"74\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#l06-pass-p)\"></line><text x=\"220\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">2. size back up</text><text x=\"220\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">86 x 33</text><line x1=\"440\" y1=\"72\" x2=\"540\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#l06-pass-a)\"></line><text x=\"520\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">3. what is left</text><text x=\"520\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">= 720 - 86</text><text x=\"360\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Measured once each, in this order; placed afterwards, left to right.</text></svg>", "caption": "The order the test's output printed: the child without a weight is measured first, and the weighted one gets the remainder."}
```

## Measured once, which is a rule and not a habit

**Compose measures each child at most once per layout pass**, and asking twice is an error rather
than a slow path. The older Android view system let a parent measure a child several times, and
deep nesting could multiply the work: a layout ten levels deep, each measuring twice, measures the
innermost element over a thousand times. With one measurement each, nesting costs nothing extra,
which is why Compose code nests `Row` in `Column` in `Box` without a second thought. When a
parent truly needs to know a child's size before measuring it, Compose has *intrinsic*
measurements, a cheaper question asked without measuring; this course does not need them, and
Google's documentation on intrinsic measurements in Compose layouts covers them.
