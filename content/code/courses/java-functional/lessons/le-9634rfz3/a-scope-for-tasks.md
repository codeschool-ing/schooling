---
title: A scope for tasks
version: 1
---

**Structured concurrency gives concurrent tasks a scope, the way a block gives variables one.** Tasks
are forked inside a `StructuredTaskScope`, the scope waits for them in `join`, and when the
try-with-resources block ends, every task forked in it has ended too. No task can outlive the block that
started it. The default policy is the one the page needed: **all must succeed, and the first failure
cancels the rest.**

`StructuredTaskScope` is a **preview API** in Java 25. Preview features are complete and specified but may
still change, so the compiler refuses them unless asked: `--enable-preview` turns them on, and with the
source-file mode `--source 25` says which release's preview to use.

```schooling-example
{
  "language": "java",
  "file": "Scoped.java",
  "parts": [
    {
      "code": "// Scoped.java: the same page, with the lookups forked in a structured scope\nimport java.util.concurrent.StructuredTaskScope;\n\npublic class Scoped {\n    static long price() throws InterruptedException {\n        Thread.sleep(300);\n        throw new IllegalStateException(\"price service down\");\n    }\n\n    static int stock() throws InterruptedException {\n        try {\n            Thread.sleep(1000);\n            System.out.println(\"stock: finished\");\n            return 3;\n        } catch (InterruptedException e) {\n            System.out.println(\"stock: cancelled, because the price failed\");\n            throw e;\n        }\n    }",
      "note": "The same two lookups. `stock` now reports when it is interrupted, so the cancellation can be seen."
    },
    {
      "code": "\n    public static void main(String[] args) throws InterruptedException {\n        long start = System.nanoTime();\n        try (var scope = StructuredTaskScope.open()) {\n            StructuredTaskScope.Subtask<Long> p = scope.fork(Scoped::price);\n            StructuredTaskScope.Subtask<Integer> s = scope.fork(Scoped::stock);",
      "note": "`open()` makes a scope with the default policy. Each `fork` starts a subtask on a new virtual thread and returns a `Subtask`, a handle on its result."
    },
    {
      "code": "\n            scope.join();\n            System.out.println(p.get() + \" cents, \" + s.get() + \" in stock\");",
      "note": "`join` waits for every subtask. With the default policy it returns only if all succeeded, so `get` is safe after it."
    },
    {
      "code": "\n        } catch (StructuredTaskScope.FailedException e) {\n            System.out.printf(\"page failed after %d ms: %s%n\", (System.nanoTime() - start) / 1_000_000, e.getCause());\n        }\n        System.out.printf(\"main returned after %d ms%n\", (System.nanoTime() - start) / 1_000_000);\n    }\n}\n",
      "note": "When a subtask fails, the scope interrupts the others, `join` throws `FailedException` with the first failure as its cause, and the block ends only after every subtask has ended."
    }
  ]
}
```

Run it with the preview switched on, and then once without, to see the refusal:

```
ana@vm:~/fp/structured$ java --enable-preview --source 25 Scoped.java
stock: cancelled, because the price failed
page failed after 309 ms: java.lang.IllegalStateException: price service down
main returned after 315 ms
ana@vm:~/fp/structured$ java Scoped.java 2>&1 | head -n 4
Scoped.java:2: error: StructuredTaskScope is a preview API and is disabled by default.
import java.util.concurrent.StructuredTaskScope;
                           ^
  (use --enable-preview to enable preview APIs)
```

## The same failure, handled by structure

**The stock lookup was cancelled the moment the price failed**, and said so; the page reported the
failure at about 300 ms; and `main` returned right after, not a second later. The rule that did it is
not in the code that calls `price` and `stock`. It is in the scope, and it applies to every task forked
there, including ones added next year by somebody else.

The default is "all or nothing" because that is what most fan-outs mean: a page that needs a price and a
stock level needs both. The block also makes the structure visible to tools: a thread dump, taken with
`jcmd <pid> Thread.dump_to_file -format=json`, shows the subtasks' threads grouped under the scope that
forked them, which is the "who did this belong to" that section 02 could not answer.
