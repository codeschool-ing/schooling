---
title: Other policies, and what preview means
version: 1
---

**The policy of a scope is a `Joiner`, passed to `open`, and it decides when `join` returns and what it
returns.** "All must succeed" is the default. The other common question is the opposite one: ask
several sources the same thing and keep whichever answers first.

```java
// FirstAnswer.java: three mirrors asked at once, the first answer kept, the others cancelled
import java.util.concurrent.StructuredTaskScope;
import java.util.concurrent.StructuredTaskScope.Joiner;

public class FirstAnswer {
    static String ask(String mirror, long ms) throws InterruptedException {
        try {
            Thread.sleep(ms);
            return mirror;
        } catch (InterruptedException e) {
            System.out.println(mirror + ": cancelled");
            throw e;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        try (var scope = StructuredTaskScope.open(Joiner.<String>anySuccessfulResultOrThrow())) {
            scope.fork(() -> ask("mirror-a", 400));
            scope.fork(() -> ask("mirror-b", 100));
            scope.fork(() -> ask("mirror-c", 250));
            System.out.println("first answer: " + scope.join());
        }
    }
}
```

```
ana@vm:~/fp/structured$ java --enable-preview --source 25 FirstAnswer.java
first answer: mirror-b
mirror-a: cancelled
mirror-c: cancelled
```

`mirror-b` answered first, after 100 ms, `join` returned its answer, and **the scope cancelled the two
that were still waiting**. A query sent to three replicas, a lookup in a cache and a database at once, a
request retried on a second server when the first is slow: each is this shape.

| `Joiner` | `join` returns | when |
|---|---|---|
| default, `open()` | nothing; read each `Subtask` | all succeeded; fails with the first failure |
| `anySuccessfulResultOrThrow()` | the first successful result | one succeeded; fails if all failed |
| `allSuccessfulOrThrow()` | the subtasks, all successful | all succeeded |
| `awaitAll()` | nothing | all finished, successfully or not |

## What preview means, and what will age

A preview feature is in the JDK so people can use it and say what is wrong with it. **Its API may change
between releases**, and this one has: the previews in Java 21 to 24 had subclasses called
`ShutdownOnFailure` and `ShutdownOnSuccess` in place of `Joiner`, and code written for them does not
compile on Java 25. That is why this lesson is an overview, why its programs need `--enable-preview`, and
why it will need revisiting when the API is final. The ideas will not age: a task's lifetime bounded by
the block that started it, failure that cancels siblings, and the structure visible in a thread dump.

**Scoped values**, the companion feature, became final in Java 25. A `ScopedValue` carries a value, such as
the current user or a request id, to every method a block calls and to the subtasks it forks, without
passing it as a parameter. It replaces most uses of `ThreadLocal`, which costs memory per thread and is
an awkward fit for a million virtual threads. This course stops at naming it; the documentation of
`java.lang.ScopedValue` in the JDK is the place to start.
