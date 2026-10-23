---
title: Lifetime, and the stack the locals live on
version: 1
---

Scope is about where a name can be **seen**, in the source. Lifetime is about how long the value
**exists**, while the program runs. For a local variable the two line up, and the reason is where
locals are kept.

Each time a method is called, the JVM gives the call a **frame**: a small block of memory holding
that call's parameters and local variables. Frames pile up on a **stack**, one per thread, with the
current call on top. When the method returns, its frame is removed and everything in it is gone.
**A local variable lives exactly as long as the call that declared it**, and a second call to the
same method gets a fresh frame with fresh copies of its locals.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 286\" role=\"img\" aria-label=\"The stack of the main thread drawn as a pile of frames: main at the bottom with args, then dive(1), dive(2) and dive(3), each holding its own level, and above them the room left, about 1 MB in all. Each call pushes a frame holding its parameters and locals; returning pops it and its locals are gone; when there is no room for the next frame the JVM throws StackOverflowError.\"><rect x=\"40\" y=\"20\" width=\"300\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the stack of the main thread</text><rect x=\"60\" y=\"216\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><text x=\"250\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">args</text><rect x=\"60\" y=\"176\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dive(1)</text><text x=\"250\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level = 1</text><rect x=\"60\" y=\"136\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dive(2)</text><text x=\"250\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level = 2</text><rect x=\"60\" y=\"96\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dive(3)</text><text x=\"250\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level = 3</text><rect x=\"60\" y=\"56\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"190\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">room left, about 1 MB in all</text><text x=\"520\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">each call pushes a frame</text><text x=\"520\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">holding its parameters and locals</text><text x=\"520\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">returning pops it,</text><text x=\"520\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and its locals are gone</text><text x=\"520\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no room for the next frame:</text><text x=\"520\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">StackOverflowError</text></svg>", "caption": "A local variable lives in its method’s frame, and the frame lives exactly as long as the call. Depth reached the top after some twenty-three thousand of them."}
```

## Running out of stack

The stack has a fixed size, so a chain of calls that never returns must eventually run out of room.
A method that calls itself, which is called **recursion**, is the easy way to make such a chain:

```java
// Depth.java
public class Depth {
    static int deepest = 0;

    static void dive(int level) {
        deepest = level;
        dive(level + 1);
    }

    public static void main(String[] args) {
        try {
            dive(1);
        } catch (StackOverflowError e) {
            System.out.println("frames before the stack ran out: " + deepest);
        }
    }
}
```

`dive` records how deep it is and calls itself one level deeper, forever. Each call adds a frame, and
when there is no room for the next one the JVM throws `StackOverflowError`. Lessons 36 to 38 are
about `try` and `catch`; here `catch` is what lets `main` print the depth instead of dying with a
stack trace.

```
ana@vm:~/scope$ javac Depth.java
ana@vm:~/scope$ java Depth
frames before the stack ran out: 23254
ana@vm:~/scope$ java Depth
frames before the stack ran out: 23254
ana@vm:~/scope$ java -Xss256k Depth
frames before the stack ran out: 1646
ana@vm:~/scope$ java -Xss4m Depth
frames before the stack ran out: 100048
```

**23,254 frames on the default stack**, and the same number twice in a row on this machine. `-Xss`
sets the size of each thread's stack, which on 64-bit Linux defaults to 1 MB. With 256 KB the chain
broke after 1,646 calls, and with 4 MB it reached 100,048. The numbers are not in proportion to the
sizes, and part of the reason is the JIT from lesson 1. Frames of interpreted code and frames of
compiled code are not the same size, and how much of `dive` was compiled before the stack filled
depends on how long it ran.

A real program almost never needs a bigger stack. `StackOverflowError` nearly always means a
recursion with no way to stop, as here, or one that stops far too late, and the fix is in the code.

## What outlives a call

Locals hold primitives and references. When a method creates an **object**, with `new`, the object is
not in the frame: it lives in a separate area called the **heap**, and the local holds only a
reference to it. So the frame can disappear while the object stays, as long as something else still
refers to it: a field, or the value the method returned. Lesson 12 draws the two areas side by side,
and lesson 19 is about what happens to an object nobody refers to any more.
