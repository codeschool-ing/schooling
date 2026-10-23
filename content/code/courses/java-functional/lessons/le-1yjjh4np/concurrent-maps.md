---
title: Concurrent maps
version: 1
---

**`HashMap` was written for one thread at a time, and sharing one between threads without a lock
corrupts it.** `ConcurrentHashMap` is the map built for sharing: many threads read and write it at once,
each operation is thread-safe, and it has methods that do a whole read-modify-write on one key as a
single step. Counting words from several threads shows the difference:

```java
// WordCount.java: four threads counting words into a HashMap, then into a ConcurrentHashMap
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class WordCount {
    static final String[] WORDS = {"dune", "emma", "ulysses", "beowulf", "middlemarch", "persuasion"};

    static void onFourThreads(Runnable work) throws InterruptedException {
        List<Thread> threads = new ArrayList<>();
        for (int t = 0; t < 4; t++) {
            threads.add(Thread.ofPlatform().start(work));
        }
        for (Thread t : threads) {
            t.join();
        }
    }

    static long total(Map<String, Integer> counts) {
        return counts.values().stream().mapToLong(Integer::longValue).sum();
    }

    public static void main(String[] args) throws InterruptedException {
        for (int run = 1; run <= 3; run++) {
            Map<String, Integer> plain = new HashMap<>();
            onFourThreads(() -> {
                for (int i = 0; i < 100_000; i++) {
                    String w = WORDS[i % WORDS.length];
                    plain.put(w, plain.getOrDefault(w, 0) + 1);
                }
            });
            System.out.println("HashMap, run " + run + ": " + total(plain) + " of 400000");
        }

        Map<String, Integer> shared = new ConcurrentHashMap<>();
        onFourThreads(() -> {
            for (int i = 0; i < 100_000; i++) {
                shared.merge(WORDS[i % WORDS.length], 1, Integer::sum);
            }
        });
        System.out.println("ConcurrentHashMap with merge: " + total(shared) + " of 400000");

        Map<String, Integer> almost = new ConcurrentHashMap<>();
        onFourThreads(() -> {
            for (int i = 0; i < 100_000; i++) {
                String w = WORDS[i % WORDS.length];
                almost.put(w, almost.getOrDefault(w, 0) + 1);
            }
        });
        System.out.println("ConcurrentHashMap with get then put: " + total(almost) + " of 400000");
    }
}
```

```
ana@vm:~/fp/concurrent$ java WordCount.java
HashMap, run 1: 237328 of 400000
HashMap, run 2: 195332 of 400000
HashMap, run 3: 199674 of 400000
ConcurrentHashMap with merge: 400000 of 400000
ConcurrentHashMap with get then put: 312264 of 400000
```

## Three results

**The shared `HashMap` lost around half of the counts**, a different number on each run. Its `put` is not
thread-safe, and two threads writing at once can lose an entry or leave the table's internal links in a
state no single thread could have produced. Nothing threw. This is the most dangerous shape of race,
because the program runs on, with wrong numbers.

**`ConcurrentHashMap` with `merge` got all 400,000.** `merge(key, 1, Integer::sum)` puts 1 if the key is
missing, or adds 1 to the current value, as one atomic step for that key. `compute` and
`computeIfAbsent` are its relatives, and between them they cover every "read this key, change it, write
it back" a program needs.

**`ConcurrentHashMap` with `get` and then `put` lost counts again.** Each call is thread-safe on its own;
the pair is a check-then-act, exactly lesson 14's overdraft. **A thread-safe collection does not make two
calls into one.** That is why `merge` and `compute` exist, and why reading code that calls `get` and then
`put` on a shared map is reading a bug.
