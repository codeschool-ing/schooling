---
title: An array inside, replaced when full
version: 1
---

"A list that grows" sounds as if `ArrayList` were some new kind of structure. **It is an ordinary
array, kept in a private field, plus a count of how many of its slots are in use.** When the array is
full, the next `add` makes a bigger array, copies every element across, and throws the old one away.
The **size** is how many elements the list holds; the **capacity** is the length of the array inside.

The field is private, and the program below reads it anyway, through reflection, the part of Java
that lets a program inspect classes while it runs. Lesson 39 uses reflection on purpose; here it is a
way to look inside, and the JDK does not make it easy. In `~/lists/growth`:

```java
// Growth.java
import java.lang.reflect.Field;
import java.util.ArrayList;

public class Growth {
    public static void main(String[] args) throws Exception {
        Field data = ArrayList.class.getDeclaredField("elementData");
        data.setAccessible(true);

        ArrayList<Integer> list = new ArrayList<>();
        int capacity = -1;
        for (int i = 0; i < 100; i++) {
            list.add(i);
            int now = ((Object[]) data.get(list)).length;
            if (now != capacity) {
                System.out.println("size " + list.size() + ": capacity " + now);
                capacity = now;
            }
        }
    }
}
```

```
ana@vm:~/lists/growth$ javac Growth.java && java Growth
Exception in thread "main" java.lang.reflect.InaccessibleObjectException: Unable to make field transient java.lang.Object[] java.util.ArrayList.elementData accessible: module java.base does not "opens java.util" to unnamed module @2b2fa4f7
	at java.base/java.lang.reflect.AccessibleObject.throwInaccessibleObjectException(AccessibleObject.java:353)
	at java.base/java.lang.reflect.AccessibleObject.checkCanSetAccessible(AccessibleObject.java:329)
	at java.base/java.lang.reflect.AccessibleObject.checkCanSetAccessible(AccessibleObject.java:277)
	at java.base/java.lang.reflect.Field.checkCanSetAccessible(Field.java:179)
	at java.base/java.lang.reflect.Field.setAccessible(Field.java:173)
	at Growth.main(Growth.java:8)
```

**Refused.** `java.util` belongs to the module `java.base`, and since Java 16 the JDK does not let
code outside it reach its private fields. Lesson 40 explains modules and this message. The number
after `@` identifies the unnamed module in this run and differs between runs. For a look at the
internals in a lesson, the JVM accepts a flag that opens the package to the program, and it is a flag
for exactly this and nothing you would ship:

```
ana@vm:~/lists/growth$ java --add-opens java.base/java.util=ALL-UNNAMED Growth
size 1: capacity 10
size 11: capacity 15
size 16: capacity 22
size 23: capacity 33
size 34: capacity 49
size 50: capacity 73
size 74: capacity 109
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Size against capacity for an ArrayList that grows from 0 to 100 elements. The size rises by one with every add. The capacity, the length of the array inside, jumps in steps: 10 at the first add, then 15, 22, 33, 49, 73 and 109, each about one and a half times the last, at sizes 11, 16, 23, 34, 50 and 74.\"><path d=\"M80 250 H680 M80 250 V30\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"230\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25</text><text x=\"380\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><text x=\"530\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">75</text><text x=\"680\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><text x=\"72\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M80 150 H680\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M80 50 H680\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"380\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">elements added (size)</text><text x=\"80\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">length of the array inside</text><path d=\"M80 250 L680 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" fill=\"none\"></path><path d=\"M80 250 V230 H146 V220 H176 V206 H218 V184 H284 V152 H380 V104 H524 V32 H680\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"82\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><text x=\"142\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15</text><text x=\"172\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">22</text><text x=\"214\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">33</text><text x=\"280\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">49</text><text x=\"376\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">73</text><text x=\"520\" y=\"23\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">109</text><path d=\"M560 200 H588\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></path><text x=\"596\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">capacity</text><path d=\"M560 220 H588\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></path><text x=\"596\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">size</text></svg>", "caption": "Each step is a new array, half as big again as the old one, and a copy of every element. Between steps, an add only writes into a slot that is already there."}
```

Three facts are in those seven lines.

**A new `ArrayList` has no array worth the name.** The first `add` gives it 10 slots, which is the
default capacity. Creating a list costs almost nothing until something goes into it.

**Each new array is about one and a half times the old one**: 10, 15, 22, 33, 49, 73, 109. The new
length is the old length plus half of it, rounded down, so 15 + 7 = 22 and 49 + 24 = 73. Adding a
hundred elements replaced the array six times after the first, and the copies added up to 202
elements (10 + 15 + 22 + 33 + 49 + 73), about two for every element added.

**Most adds copy nothing.** Between two steps, `add` writes into a slot that already exists and
increments the size. The occasional copy is spread over all the cheap adds between it and the next,
so adding at the end stays fast on average however long the list gets. If you know in advance that a
list will hold a million elements, `new ArrayList<>(1_000_000)` or `ensureCapacity(1_000_000)` sizes
the array once and skips every step.

## Adding at the front moves everything

Adding at the **end** writes one slot. Adding at index 0 has to make room first: every element moves
one place along, and in a long list that is a long walk. The same 100,000 numbers, added both ways:

```java
// Shifting.java
import java.util.ArrayList;
import java.util.List;

public class Shifting {
    static long millis(boolean atFront) {
        List<Integer> list = new ArrayList<>();
        long start = System.nanoTime();
        for (int i = 0; i < 100_000; i++) {
            if (atFront) {
                list.add(0, i);
            } else {
                list.add(i);
            }
        }
        return (System.nanoTime() - start) / 1_000_000;
    }

    public static void main(String[] args) {
        System.out.println("at the end:   " + millis(false) + " ms");
        System.out.println("at the front: " + millis(true) + " ms");
    }
}
```

```
ana@vm:~/lists/growth$ javac Shifting.java && java Shifting
at the end:   26 ms
at the front: 492 ms
```

**About nineteen times slower at the front, in this run.** The two numbers differ on every run and every
machine, and the gap between them grows with the size of the list, because each insertion at the
front moves every element already there. `remove(0)` has the same cost for the same reason. When a
program needs to add and remove at the front often, a different structure fits better, and lesson 33's
`ArrayDeque` is it.
