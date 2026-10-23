---
title: Creating and starting a thread
version: 1
---

**A thread is a separate line of execution inside the same program: its own call stack, running at the
same time as the others, sharing the same objects.** Every Java program already has one, `main`. Lessons
11 to 18 are about adding more, and about what goes wrong when several of them touch the same data.

A thread runs a `Runnable`, the functional interface from lesson 2 with one method, `run`. So a lambda
is all it takes to describe the work:

```java
// First.java: a thread started, a thread run by mistake, and waiting for one to finish
public class First {
    static void report(String what) {
        System.out.println(what + " on " + Thread.currentThread().getName());
    }

    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(() -> report("work"));
        worker.start();
        worker.join();

        Thread mistake = new Thread(() -> report("run() instead of start()"));
        mistake.run();

        Thread named = Thread.ofPlatform().name("invoice-", 1).start(() -> report("builder"));
        named.join();

        report("main finishes");
    }
}
```

```
ana@vm:~/fp/threads$ java First.java
work on Thread-0
run() instead of start() on main
builder on invoice-1
main finishes on main
```

## `start`, not `run`

`worker.start()` asked the JVM for a new thread, and the work was reported on `Thread-0`, the default
name of the first thread a program creates. **`mistake.run()` started nothing**: `run` is an ordinary
method of `Thread`, so calling it ran the lambda right there, on `main`, like any other method call.
Nothing failed. The program simply was not concurrent, and on a fast machine nobody would notice until
the work got slow. `start` is the only method that creates the thread; `run` is what the new thread
calls once it exists.

## Waiting with `join`

`worker.join()` made `main` wait until `worker` had finished. Without it, `main` would carry on at once,
and the two threads' output could come out in either order, decided by the operating system's
scheduler from one run to the next. **`join` is the simplest form of coordination**: one thread
waiting for another to end. It throws `InterruptedException`, a checked exception section 03 explains,
which is why `main` declares it.

## The builder

`Thread.ofPlatform()`, added in Java 21, builds threads with a fluent API (lesson 26 of `java`).
`.name("invoice-", 1)` names the threads it starts `invoice-1`, `invoice-2` and so on, and a thread
dump full of `invoice-7` says far more than one full of `Thread-7`. The name **platform** is there to
tell these threads apart from the virtual threads of lesson 17, which the same builder makes with
`Thread.ofVirtual()`. Every thread in this lesson is a platform thread: a thread of the operating
system, with a Java object in front of it.
