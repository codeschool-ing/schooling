---
title: Reachable or garbage
version: 1
---

Java has no `delete`. A program asks for memory with `new` and never gives it back, and a separate
part of the JVM, the **garbage collector**, decides when that memory can be used again. The common
picture is a collector that frees objects "when you stop using them". **It frees objects nothing can
reach any more**, which is a narrower and much more useful rule, because you can check it.

## The rule

An object is **reachable** if a chain of references leads to it from a **root**: a local variable
of a method that is still running, a static field, and a few things inside the JVM. Every other
object is garbage, and the collector may reuse its memory whenever it likes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Roots on the left: a local variable of main called pages, and the static field latest. pages points at an ArrayList, which points at two byte arrays; latest points at one byte array. Those four objects are reachable and kept. On the right, a Loan that points at a Book, with no arrow reaching either from any root: both are unreachable, and garbage.\"><defs><marker id=\"jv19-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"20\" width=\"170\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">roots</text><rect x=\"30\" y=\"60\" width=\"142\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main: pages</text><rect x=\"30\" y=\"120\" width=\"142\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">static latest</text><text x=\"101\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">local variables of</text><text x=\"101\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">running methods,</text><text x=\"101\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">static fields</text><rect x=\"230\" y=\"50\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ArrayList</text><rect x=\"400\" y=\"30\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">byte[]</text><rect x=\"400\" y=\"76\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">byte[]</text><rect x=\"230\" y=\"124\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">byte[]</text><path d=\"M172 80 H228\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv19-a)\"></path><path d=\"M350 64 L398 49\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv19-a)\"></path><path d=\"M350 76 L398 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv19-a)\"></path><path d=\"M172 140 H228\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv19-a)\"></path><text x=\"450\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">reachable: kept</text><rect x=\"540\" y=\"150\" width=\"164\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"560\" y=\"170\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Loan</text><rect x=\"560\" y=\"212\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Book</text><text x=\"622\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">unreachable: garbage</text><text x=\"622\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no path from a root</text><path d=\"M620 202 V210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv19-a)\"></path></svg>", "caption": "The collector starts from the roots and follows every reference. What it reaches is kept; what it never reaches is free memory, however many objects point at each other inside it."}
```

That is the only rule. An object you will never use again is kept for as long as something reachable
still points at it, and lesson 17's hidden `this$0` was one way that happens without anybody noticing.
An object with no path from a root is gone even if a hundred other unreachable objects point at it.

## Allocating far more than the heap holds

`Churn` asks for two million arrays of a kilobyte each, almost 2 GB, in a heap capped at 32 MB by
`-Xmx32m`. It keeps only the newest one, in a static field:

```java
// Churn.java
public class Churn {
    static byte[] latest;

    public static void main(String[] args) {
        long total = 0;
        for (int i = 0; i < 2_000_000; i++) {
            latest = new byte[1024];
            total += latest.length;
        }
        System.out.println("allocated " + total / (1024 * 1024) + " MB, holding one page at a time");
    }
}
```

```
ana@vm:~/lifecycle$ javac Churn.java Hoard.java Request.java
ana@vm:~/lifecycle$ java -Xmx32m Churn
allocated 1953 MB, holding one page at a time
```

The `javac` line compiled all three programs of this section at once, so save the other two, shown
below, before you type it.
**It worked, in a heap sixty times smaller than what it allocated**, because each array became
garbage the moment the next one replaced it in `latest`. `-Xlog:gc` makes the collector report each
time it runs:

```
ana@vm:~/lifecycle$ java -Xmx32m -Xlog:gc Churn > gc.log; head -4 gc.log
[0.004s][info][gc] Using G1
[0.112s][info][gc] GC(0) Pause Young (Normal) (G1 Evacuation Pause) 18M->1M(32M) 2.649ms
[0.114s][info][gc] GC(1) Pause Young (Normal) (G1 Evacuation Pause) 14M->1M(32M) 0.411ms
[0.117s][info][gc] GC(2) Pause Young (Normal) (G1 Evacuation Pause) 18M->1M(32M) 0.784ms
ana@vm:~/lifecycle$ grep -c Pause gc.log
111
```

Each line is one **pause**, a moment the program stopped while the collector worked. `18M->1M(32M)`
reads as: 18 MB in use before, 1 MB after, in a 32 MB heap. The collector is **G1**, the JVM's
default on a machine like this one, and it ran 111 times in that run; the times and the count differ
on every run and every machine. Every pause found almost everything dead, and cleaning up dead
objects is what such a collector is fastest at.

## Running out

`Hoard` keeps everything, in a list held by a local variable of `main`:

```java
// Hoard.java
import java.util.ArrayList;
import java.util.List;

public class Hoard {
    public static void main(String[] args) {
        List<byte[]> pages = new ArrayList<>();
        while (true) {
            pages.add(new byte[1024 * 1024]);
        }
    }
}
```

```
ana@vm:~/lifecycle$ java -Xmx32m Hoard; echo $?
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at Hoard.main(Hoard.java:9)
1
```

**`OutOfMemoryError: Java heap space`**: every megabyte was still reachable through `pages`, so the
collector could free nothing, and the JVM gave up at the line that asked for one more. It is an
`Error`, not an `Exception`, and lesson 38 says why a program should not try to catch it. When you
meet it, the question is never "how do I get more memory" first. It is **what is still holding
references it should have let go**, and the answer is usually a collection that only ever grows.

## `System.gc()` is a request

`System.gc()` asks the JVM to collect now. The JVM may say no:

```java
// Request.java
public class Request {
    public static void main(String[] args) {
        byte[][] junk = new byte[8][];
        for (int i = 0; i < junk.length; i++) {
            junk[i] = new byte[1024 * 1024];
        }
        junk = null;
        System.gc();
        System.out.println("asked");
    }
}
```

```
ana@vm:~/lifecycle$ java -Xlog:gc Request
[0.003s][info][gc] Using G1
[0.054s][info][gc] GC(0) Pause Full (System.gc()) 18M->1M(14M) 10.252ms
asked
ana@vm:~/lifecycle$ java -XX:+DisableExplicitGC -Xlog:gc Request
[0.003s][info][gc] Using G1
asked
```

The first run did a **`Pause Full (System.gc())`**, a full collection of the whole heap, which took
far longer than any of `Churn`'s young pauses. The second ran with `-XX:+DisableExplicitGC`, a
setting servers use to ignore exactly this call, and no collection happened. Same program, same
call. **A program that needs `System.gc()` to work correctly is wrong**, because nothing promises
the call does anything, and one that calls it for speed is usually slower for it.
