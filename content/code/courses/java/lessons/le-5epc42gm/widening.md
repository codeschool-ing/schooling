---
title: Widening, which Java does by itself
version: 1
---

Lesson 4 gave every value a type. Values meet values of other types all the time: an `int` count
goes into a `long` total, an `int` price is divided by a `double` rate. **Java converts by itself
only in the direction that cannot overflow**, from a smaller type to a larger one, and that is
called a **widening conversion**. The other direction needs you to say so, which is section 03.

## The safe direction

```java
// Widen.java
public class Widen {
    public static void main(String[] args) {
        int copies = 16_777_217;
        long asLong = copies;
        double asDouble = copies;
        float asFloat = copies;
        System.out.println(copies);
        System.out.println(asLong);
        System.out.println(asDouble);
        System.out.println(asFloat);
        System.out.println(asFloat == 16_777_216);
        char initial = 'J';
        int code = initial;
        System.out.println(code);
    }
}
```

```
ana@vm:~/convert$ java Widen.java
16777217
16777217
1.6777217E7
1.6777216E7
true
74
```

The same `int`, 16,777,217, went into a `long`, a `double` and a `float` with no cast written and no
complaint from the compiler. `char` to `int` is widening too: `initial` became 74, the code of `J`.
The `long` and the `double` kept the number exactly; the `double` only prints it in scientific
notation, `1.6777217E7`, meaning 1.6777217 × 10⁷.

**The `float` did not keep it.** It printed `1.6777216E7`, one less, and the comparison on the next
line confirmed that what the variable holds is 16,777,216. A `float` has 32 bits and spends 24 of
them on the digits, so it holds every whole number up to 2²⁴, which is 16,777,216, and from there
on only some of them. **A widening conversion can never overflow, and a few of them can round**:
the range of a `float` is far larger than an `int`'s, and its precision is smaller.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The widening conversions Java makes by itself, as arrows from left to right: byte to short to int to long to float to double, and char to int. Every arrow is automatic. Dashed arrows mark the ones that can round the value: int to float, and long to float or double.\"><defs><marker id=\"jv6-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"jv6-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">byte</text><rect x=\"135\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">short</text><rect x=\"250\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">int</text><rect x=\"365\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">long</text><rect x=\"480\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"525\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">float</text><rect x=\"595\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">double</text><path d=\"M110 87 H133\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv6-a)\"></path><path d=\"M225 87 H248\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv6-a)\"></path><path d=\"M340 87 H363\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv6-a)\"></path><path d=\"M455 87 H478\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\" marker-end=\"url(#jv6-b)\"></path><path d=\"M570 87 H593\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv6-a)\"></path><rect x=\"250\" y=\"160\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">char</text><path d=\"M295 160 V106\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv6-a)\"></path><path d=\"M295 70 C 330 20, 480 20, 520 68\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" fill=\"none\" marker-end=\"url(#jv6-b)\"></path><path d=\"M410 104 C 440 140, 600 140, 635 106\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" fill=\"none\" marker-end=\"url(#jv6-b)\"></path><text x=\"408\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">int to float: may lose digits</text><text x=\"520\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">long to float, and to double: may lose digits</text><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every arrow is automatic; the dashed ones can round the value</text></svg>", "caption": "Widening only ever goes to the right. The range always fits; the digits do not always fit, which is how 16,777,217 became 16,777,216."}
```

The arrows run one way. Every type to the left fits into every type to its right without a cast,
`byte` into `double` included. The rounding arrows are the three where the target's digits are
fewer than the source's: `int` to `float`, `long` to `float` and `long` to `double`. For money,
counts and identifiers this matters, and lesson 8 is about what to use instead of a floating-point
type when every digit must survive.

`boolean` is in no arrow at all. It converts to nothing and nothing converts to it: `true` is not 1
in Java, and `if (count)` does not compile.
