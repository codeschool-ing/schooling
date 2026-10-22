---
title: synchronized
version: 1
---

**Every Java object has a lock, called its monitor, and `synchronized` takes it.** A `synchronized`
block runs only while its thread holds the lock of the object named in brackets; any other thread that
reaches a block on the same object waits, in state `BLOCKED` (lesson 11 section 03), until the lock is
free. A `synchronized` method is the same thing with `this` as the object, or the class itself for a
static method.

```schooling-example
{
  "language": "java",
  "file": "Synced.java",
  "parts": [
    {
      "code": "// Synced.java: the counter and the account of lessons 13 and 14, synchronised\nimport java.util.ArrayList;\nimport java.util.List;\n\npublic class Synced {"
    },
    {
      "code": "    static class Counter {\n        private long count;\n\n        synchronized void increment() {\n            count++;\n        }\n\n        synchronized long get() {\n            return count;\n        }\n    }",
      "note": "Both methods synchronise on the same `Counter`, so an increment never overlaps another increment or a read. The field no longer needs `volatile`: the lock gives visibility as well as exclusion."
    },
    {
      "code": "\n    static class Account {\n        private long cents;\n\n        Account(long cents) {\n            this.cents = cents;\n        }\n\n        boolean withdraw(long amount) {\n            synchronized (this) {\n                if (cents < amount) {\n                    return false;\n                }\n                Thread.yield();\n                cents -= amount;\n                return true;\n            }\n        }\n\n        synchronized long balance() {\n            return cents;\n        }\n    }",
      "note": "The check and the act are now inside one block, so no other till can change `cents` between them. The same gap is still there, and nobody can use it."
    },
    {
      "code": "\n    static void onFourThreads(Runnable work) throws InterruptedException {\n        List<Thread> threads = new ArrayList<>();\n        for (int t = 0; t < 4; t++) {\n            threads.add(Thread.ofPlatform().start(work));\n        }\n        for (Thread t : threads) {\n            t.join();\n        }\n    }",
      "note": "Four threads running the same work, and `join` on each, which makes their results visible to `main` (lesson 12 section 04)."
    },
    {
      "code": "\n    public static void main(String[] args) throws InterruptedException {\n        Counter counter = new Counter();\n        onFourThreads(() -> {\n            for (int i = 0; i < 1_000_000; i++) {\n                counter.increment();\n            }\n        });\n        System.out.println(\"count: \" + counter.get() + \" of 4000000\");\n\n        for (int run = 1; run <= 3; run++) {\n            Account account = new Account(100_000);\n            onFourThreads(() -> {\n                for (int i = 0; i < 1000; i++) {\n                    account.withdraw(50);\n                }\n            });\n            System.out.println(\"run \" + run + \": balance \" + account.balance());\n        }\n    }\n}\n",
      "note": "The same work as before, on the synchronised classes."
    }
  ],
  "output": "count: 4000000 of 4000000\nrun 1: balance 0\nrun 2: balance 0\nrun 3: balance 0"
}
```

**Four million, exactly, and the balance at zero every time.** A lock gives two things at once: only one
thread inside, and, by the happens-before rule for monitors (lesson 12 section 04), everything a thread
did inside is visible to the next thread that takes the same lock. That is why `count` needs no
`volatile` once every access to it is synchronised, **including the read**: an unsynchronised `get()`
could read a stale value.

## Three rules of thumb

- **Every access to the shared state goes through the same lock.** Synchronising the writes and not the
  reads, or two methods on two different objects, protects nothing.
- **Keep the block short**: the check and the act, and nothing that waits. A thread holding a lock while
  it calls a web service makes every other thread wait for the web service too.
- **Lock on an object you control.** `synchronized (this)` in a class others can see lets them take your
  lock too; a private `final Object lock = new Object();` keeps it yours.

A `synchronized` block is **reentrant**: a thread that already holds a lock can enter another block on
the same lock without waiting for itself, which is why a synchronised method can call another
synchronised method of the same object.
