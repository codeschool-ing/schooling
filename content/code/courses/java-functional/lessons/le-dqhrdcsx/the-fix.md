---
title: The fix for the flag
version: 1
---

**A field declared `volatile` must be read from memory every time the code reads it, and written to
memory every time the code writes it.** The compiler may not keep it in a register across a loop, and
the processor may not let a later read overtake it. That is exactly what `Stop.java` in lesson 12 was
missing, and the fix is one word in the declaration:

```java
// VolatileStop.java: lesson 12's flag, declared volatile
public class VolatileStop {
    static volatile boolean stop = false;

    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(() -> {
            long spins = 0;
            while (!stop) {
                spins++;
            }
            System.out.println("worker saw stop after " + spins + " spins");
        });
        worker.start();
        Thread.sleep(1000);
        stop = true;
        System.out.println("main set stop = true");
        worker.join(3000);
        System.out.println("worker still running after 3 s: " + worker.isAlive());
        System.exit(0);
    }
}
```

```
ana@vm:~/fp/volatile$ java VolatileStop.java
main set stop = true
worker saw stop after 3676553062 spins
worker still running after 3 s: false
```

The worker noticed the write and ended, and `main`'s `join` returned at once instead of waiting the
three seconds. **The program is now correct by the rules of the language**, not by the luck of how the
JVM ran it, so it behaves the same interpreted, compiled, on x86 and on ARM.

Compare the spin counts. The worker of lesson 12, run with `-Xint`, made about 160 million spins in a
second; this one, compiled and with a `volatile` read on every turn, made about 3.7 billion. **The
`volatile` read did not make the loop slow**: on x86 it costs little more than a plain read, because the
processor already keeps reads in order. What `volatile` took away was only the compiler's freedom to
read the field once, which is exactly the freedom that broke the program.
