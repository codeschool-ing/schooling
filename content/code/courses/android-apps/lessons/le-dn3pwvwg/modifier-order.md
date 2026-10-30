---
title: Modifiers are a chain, and the order is the meaning
version: 1
---

**The wrong picture of a modifier is a list of settings**: padding 16, background yellow, as if
the element had a padding property and a background property and the modifier filled them in. Hold
that picture and the two texts below should look the same, since each gets the same two settings.

**The right picture is a chain of wrappers, applied from the outside in.** Each modifier wraps
everything written after it. `padding(16.dp).background(amber)` means "keep 16 dp clear, and inside
that, paint the background". `background(amber).padding(16.dp)` means "paint the background, and
inside it, keep 16 dp clear before the text":

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
{"image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAiYAAAChCAYAAADz5HQPAAAWKUlEQVR4Xu3d+bskVX3Hcf+PPMkTcJBlVmGGmYGZgRlmvQNDlAwaUeMT8EFFRdxFcYEEBRfcUSSKCCqKC4io4wKICyguqJ2QnexmN6tms3I/1Tl9T3+6urrvre7Tp6feP7ye5z5dVX2rq8/51LdOLf2Yn/+0KAAAAHLwGH8BAABgVihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMAABANihMgBYpOucCQC3PjdQoTIAW8QACAOe5kRqFCdAiHkAA4Dw3UqMwAVrEAwgAnOdGahQmQIt4AAGA89xIjcIEaBEPIABwnhupUZgALeIBBADOcyM1ChOgRTyAAMB5bqRGYQK0iAcQADjPjdQoTIAW8QACAOe5kRqFCdAiHkAA4Dw3UqMwAVrEAwgAnOdGahQmQIt4AAGA89xIjcIEaBEPIABwnhupUZgALeIBBADOcyM1ChOgRTyAAMB5bqRGYQK0iAcQADjPjdQoTIAW8QACAOe5kRqFCdAiHkAA4Dw3UqMwAVrEAwgAnOdGahQmQIt4AAGA89xIjcIEaBEPIABwnhupUZgALeIBBADOcyM1ChOgRTyAAMB5bqRGYQK0iAcQADjPjdQoTIAW8QACAOe5kRqFCdAiHkAA4Dw3UqMwAVrEAwgAnOdGahQmQIt4AAGA89xIjcIEaBEPIABwnhupUZgALeIBBADOcyM1ChOgRTyAAMB5bqTW+sLEvxBgmrz9pebrAwDOcyM1CpOKLwWYFm9/qfn6AIDz3EiNwqTiSwGmxdtfar4+AOA8N1KjMKn4UoBp8faXmq8PADjPjdQoTCq+FMyff37w7OKRu/YWv3PnnuJv718ofv6jQwPz5MDbX2q+PkBbzEtG5MBzIzUKk4ovJUeX/vrji1/8hV8uLjy8bmDaOOqW/++Hzyl+fN+Bueyof/ql/cVl///ZYvu2n1hc94rN2X0mb3+p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", "alt": "Two texts on a pale surface. On the left, padding first: the yellow background fits the letters tightly, with space around it. On the right, background first: a larger yellow block with space inside it around the words.", "caption": "The same two modifiers in the two orders."}
```

The left text's padding is outside its background, so the yellow fits the letters exactly and the
16 dp of space around it is the surface's own colour. The right text's padding is inside, so the
yellow covers it too. **Same two modifiers, same values, two different drawings.**

## The same rule decides what a tap reaches

`clickable` is a modifier like the others, and the order decides the size of the target. Written
before `padding`, it wraps the padding, and a tap anywhere in the padded area counts. Written after,
only the inner part is the target, and a finger that lands in the padding does nothing. The
`mobile-fundamentals` course, lesson 19, gives the minimum target Google's guidelines ask for, 48 dp;
**putting `clickable` first is how a small icon gets a target that large.**

## The `modifier` parameter, applied first

Section 02's `SessionRow` takes a `modifier` parameter and starts its own chain with it:
`modifier.fillMaxWidth().padding(…)`. That order is the convention, and it has a reason: the
caller's modifiers are outermost, so a caller who writes `SessionRow(…, Modifier.padding(8.dp))`
adds space outside the row without the row having to know. A composable that applied the caller's
modifier last, inside its own padding, would surprise every caller who reads its signature.

**Pass the `modifier` parameter to exactly one element: the outermost one.** Passed to two, the
caller's padding is applied twice; passed to an inner child, it lands somewhere the caller cannot
see.
