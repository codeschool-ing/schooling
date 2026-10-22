---
title: When to use it
version: 1
---

**Use `volatile` when every write to the field is independent of the field's current value, and the
field stands on its own.** That rule, from the original specification's discussion of the keyword, covers
the cases where it is right and excludes the ones where it is not:

| use | `volatile` is | why |
|---|---|---|
| a stop flag or a status set by one thread and read by others | right | each write is a plain assignment |
| a reference to an immutable object, replaced as a whole | right | lesson 12 section 05's `PriceList` |
| a "ready" flag guarding data written before it | right | section 03's handover |
| a counter, a total, a running maximum | **wrong** | the new value depends on the old one |
| two fields that must change together, a minimum and a maximum | **wrong** | each is visible on its own, never as a pair |

## Lazy initialisation, done once

The one well-known pattern that combines `volatile` with a lock is lazy initialisation of something
expensive, so that it is built on first use and only once:

```java
// Lazy.java: build an expensive object once, on first use, safely
public class Lazy {
    record Index(int entries) {}

    private static volatile Index index;

    static Index index() {
        Index local = index;
        if (local == null) {
            synchronized (Lazy.class) {
                local = index;
                if (local == null) {
                    System.out.println("building the index");
                    local = new Index(12);
                    index = local;
                }
            }
        }
        return local;
    }

    public static void main(String[] args) throws InterruptedException {
        Thread a = Thread.ofPlatform().start(() -> System.out.println("a got " + index()));
        Thread b = Thread.ofPlatform().start(() -> System.out.println("b got " + index()));
        a.join();
        b.join();
    }
}
```

```
ana@vm:~/fp/volatile$ java Lazy.java
building the index
b got Index[entries=12]
a got Index[entries=12]
```

The index was built once, and both threads got it. The first check, outside the lock, keeps the fast
path free of locking once the object exists; the second, inside, stops two threads that both saw `null`
from both building it. And **`volatile` is what makes the published object safe to read on the fast
path**, by the ordering promise of section 03. Without it, a thread could see the reference before the
object's fields, which is lesson 12 section 05's unsafe publication. Lesson 14 explains `synchronized`.

There is usually a simpler way. A static field of a nested class is initialised by the JVM, lazily and
safely, the first time the class is used; and when "expensive" turns out to mean a few milliseconds at
start-up, building the object eagerly is simpler still. Reach for the pattern above when you have
measured that you need it.
