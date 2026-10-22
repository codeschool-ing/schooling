---
title: Floating point, and why 0.1 + 0.2 is not 0.3
version: 1
---

The common belief is that a `double` holds a decimal number with sixteen-odd digits of it, so
`0.1` is one tenth. **A `double` holds a binary fraction, and one tenth has no exact binary form**,
for the same reason one third has no exact decimal form. The value stored for `0.1` is the nearest
binary fraction, a little above a tenth, and arithmetic on such values carries those small errors
along. Usually they stay invisible, below the digits `println` shows. Sometimes they surface:

```java
// Floats.java
public class Floats {
    public static void main(String[] args) {
        System.out.println(0.1 + 0.2);
        System.out.println(0.1 + 0.2 == 0.3);
        System.out.println(Math.abs((0.1 + 0.2) - 0.3) < 1e-9);
        System.out.println(new java.math.BigDecimal(0.3));
        System.out.println(new java.math.BigDecimal(0.1 + 0.2));

        double total = 0;
        for (int k = 0; k < 10; k++) {
            total += 0.1;
        }
        System.out.println(total);

        System.out.println(1.0 / 0);
        System.out.println(-1.0 / 0);
        double nan = 0.0 / 0;
        System.out.println(nan);
        System.out.println(nan == nan);
        System.out.println(Double.isNaN(nan));
        System.out.println(0.0 == -0.0);
        System.out.println(1 / -0.0);

        System.out.println(1 / 0);
    }
}
```

```
ana@vm:~/maths$ java Floats.java
0.30000000000000004
false
true
0.299999999999999988897769753748434595763683319091796875
0.3000000000000000444089209850062616169452667236328125
0.9999999999999999
Infinity
-Infinity
NaN
false
true
true
-Infinity
Exception in thread "main" java.lang.ArithmeticException: / by zero
	at Floats.main(Floats.java:25)
```

The first line is the famous one. `0.1 + 0.2` printed `0.30000000000000004`, and **`==` against
`0.3` said `false`**. The two lines after the `true` print the exact values involved, by handing the
`double`s to `BigDecimal`, which section 05 is about; here it only shows every digit. The literal
`0.3` is stored a hair below three tenths, and the sum lands a hair above:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A number line near 0.3. The literal 0.3 is stored as the double 0.29999999999999998889, just below the real 0.3. The sum 0.1 + 0.2 lands on the next double up, 0.30000000000000004440. No double lies between the two, so the comparison 0.1 + 0.2 == 0.3 is false.\"><path d=\"M40 120 H680\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 112 V128\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200 112 V128\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M520 112 V128\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M660 112 V128\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200 104 V136\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M520 104 V136\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M360 112 V128\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the real 0.3, which no double holds</text><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.3</text><rect x=\"40\" y=\"24\" width=\"320\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0.3 in the source</text><text x=\"200\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.29999999999999998889…</text><rect x=\"380\" y=\"24\" width=\"300\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">0.1 + 0.2</text><text x=\"530\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.30000000000000004440…</text><rect x=\"40\" y=\"170\" width=\"640\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">two neighbouring doubles, with no other double between them</text><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.1 + 0.2 rounds to the right-hand one, so it is not == 0.3</text></svg>", "caption": "The double nearest 0.3 and the sum 0.1 + 0.2 are neighbours. Both values are the ones BigDecimal printed above, cut at twenty decimal places."}
```

## Comparing with a tolerance

So `==` between computed `double`s asks a question the arithmetic cannot answer reliably. **Compare
the distance between them with a tolerance instead**: `Math.abs(a - b) < 1e-9` printed `true`.
`1e-9` is one billionth, written in scientific notation, and the right size depends on the numbers:
a billionth is tiny next to a price and enormous next to the width of an atom. Adding `0.1` ten
times shows the same thing from the other side: the total came out as `0.9999999999999999`, and a
loop that ran `while (total != 1.0)` would never stop.

## The values that are not numbers

Integer division by zero has no answer, and line 25, `1 / 0`, stopped the program with
`ArithmeticException: / by zero`. **Floating-point division by zero does not stop anything.** It
has answers, defined by the IEEE 754 standard that processors follow:

| expression | printed | |
|---|---|---|
| `1.0 / 0` | `Infinity` | too large to hold, on the positive side |
| `-1.0 / 0` | `-Infinity` | the same on the negative side |
| `0.0 / 0` | `NaN` | not a number: no answer exists |
| `nan == nan` | `false` | **NaN is unequal to everything, itself included** |
| `Double.isNaN(nan)` | `true` | the only reliable test |
| `0.0 == -0.0` | `true` | two zeros, equal to each other |
| `1 / -0.0` | `-Infinity` | and yet they divide differently |

A `NaN` spreads quietly: any arithmetic with one gives `NaN`, and every comparison with one is
`false`, so a sort or a `max` that meets one gives answers that look wrong and throw nothing. **When
a computation can produce one, test for it with `Double.isNaN` where it is produced**, before it
reaches anything else.
