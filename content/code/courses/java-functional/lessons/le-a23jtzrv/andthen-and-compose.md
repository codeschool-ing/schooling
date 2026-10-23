---
title: Two orders, two methods
version: 1
---

**`f.andThen(g)` is a new function that runs `f` and passes its result to `g`. `f.compose(g)` runs
`g` first and passes its result to `f`.** Both return a new `Function` and change neither of the
two they were built from. They are default methods of `Function` (lesson 2 section 02), which is
why any lambda typed as a `Function` already has them.

```java
// Compose.java: the same two functions joined in both orders
import java.util.Locale;
import java.util.function.Function;

public class Compose {
    public static void main(String[] args) {
        Function<Integer, Integer> addOne = x -> x + 1;
        Function<Integer, Integer> doubleIt = x -> x * 2;
        System.out.println("addOne.andThen(doubleIt): " + addOne.andThen(doubleIt).apply(5));
        System.out.println("addOne.compose(doubleIt): " + addOne.compose(doubleIt).apply(5));

        Function<String, String> strip = String::strip;
        Function<String, String> lower = s -> s.toLowerCase(Locale.ROOT);
        Function<String, Integer> length = String::length;
        Function<String, Integer> cleanLength = strip.andThen(lower).andThen(length);
        System.out.println(cleanLength.apply("   Middlemarch  "));

        Function<String, String> same = Function.identity();
        System.out.println("[" + same.apply("unchanged") + "]");
    }
}
```

```
ana@vm:~/fp/composition$ java Compose.java
addOne.andThen(doubleIt): 12
addOne.compose(doubleIt): 11
11
[unchanged]
```

With 5, `andThen` added one and then doubled, 12; `compose` doubled and then added one, 11. **The
names say the order in two different grammars.** `andThen` reads left to right, the order the work
happens, which is why almost all real code uses it. `compose` reads like the mathematics, where
`f(g(x))` is written with `f` first and runs `g` first; it is there for the cases where the
function you have is the outer one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two rows. In the first, addOne.andThen(doubleIt): 5 goes into addOne and becomes 6, then into doubleIt and becomes 12. In the second, addOne.compose(doubleIt): 5 goes into doubleIt first and becomes 10, then into addOne and becomes 11.\"><defs><marker id=\"order-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">addOne.andThen(doubleIt)</text><rect x=\"30\" y=\"50\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"70.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">5</text><rect x=\"150\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">addOne</text><rect x=\"300\" y=\"50\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">6</text><rect x=\"420\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">doubleIt</text><rect x=\"570\" y=\"50\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">12</text><path d=\"M110 70 L146 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M260 70 L296 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M380 70 L416 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M530 70 L566 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><text x=\"30\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">addOne.compose(doubleIt)</text><rect x=\"30\" y=\"150\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"70.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">5</text><rect x=\"150\" y=\"150\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">doubleIt</text><rect x=\"300\" y=\"150\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">10</text><rect x=\"420\" y=\"150\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">addOne</text><rect x=\"570\" y=\"150\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">11</text><path d=\"M110 170 L146 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M260 170 L296 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M380 170 L416 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M530 170 L566 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path></svg>", "caption": "andThen runs the function it is called on first; compose runs its argument first."}
```

## Types have to line up

`strip.andThen(lower).andThen(length)` changed type on the way: two steps from `String` to `String`
and the last from `String` to `Integer`, so the whole is a `Function<String, Integer>`. **Each
step's output type has to be the next step's input type**, and the compiler checks every joint. A
chain that tried `length.andThen(lower)` would be refused, because `lower` cannot take the
`Integer` that `length` gives.

`Function.identity()` is the function that returns its argument unchanged. It looks useless and is
the right starting point for a chain built in a loop, as section 05 shows, the way `0` is the
right start for a sum.

## The others that compose

`andThen` is not only on `Function`:

| type | method | what the result does |
|---|---|---|
| `Function<T, R>` | `andThen`, `compose` | runs both, passing the value along |
| `BiFunction<T, U, R>` | `andThen(Function)` | runs the two-argument one, then a one-argument one on its result |
| `Consumer<T>` | `andThen(Consumer)` | gives the same value to both, in order |
| `UnaryOperator<T>` | inherits `andThen` from `Function` | the result is typed as a `Function<T, R>`, not a `UnaryOperator` |

The last row catches people: joining two `UnaryOperator<String>` values gives a
`Function<String, String>`, because the method was declared on `Function`. Store the result in a
`Function` variable, and nothing is lost.
