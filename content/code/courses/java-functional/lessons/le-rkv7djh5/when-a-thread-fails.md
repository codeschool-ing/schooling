---
title: When a thread fails
version: 1
---

**An exception that nobody catches ends the thread it was thrown in, and only that thread.** In `main`
that ends the program, which is loud and obvious. In any other thread the JVM prints a stack trace and
the program carries on, with whatever that thread was supposed to do left undone:

```java
// Failing.java: an uncaught exception in a worker, and a handler that reports it
public class Failing {
    public static void main(String[] args) throws InterruptedException {
        Thread quiet = new Thread(() -> {
            System.out.println("worker: about to divide");
            int ratio = 10 / Integer.parseInt("0");
            System.out.println("worker: ratio is " + ratio);
        }, "worker-a");
        quiet.start();
        quiet.join();
        System.out.println("main: still running, and nothing told me the worker failed");

        Thread reported = new Thread(() -> {
            throw new IllegalStateException("stock file is missing");
        }, "worker-b");
        reported.setUncaughtExceptionHandler((t, e) ->
                System.out.println("handler: " + t.getName() + " died with " + e));
        reported.start();
        reported.join();

        Thread daemon = new Thread(() -> {
            try {
                Thread.sleep(60_000);
                System.out.println("daemon: never printed");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        daemon.setDaemon(true);
        daemon.start();
        System.out.println("main: done, and the daemon does not keep the JVM alive");
    }
}
```

```
ana@vm:~/fp/threads$ java Failing.java
worker: about to divide
Exception in thread "worker-a" java.lang.ArithmeticException: / by zero
	at Failing.lambda$main$0(Failing.java:6)
	at java.base/java.lang.Thread.run(Thread.java:1474)
main: still running, and nothing told me the worker failed
handler: worker-b died with java.lang.IllegalStateException: stock file is missing
main: done, and the daemon does not keep the JVM alive
```

## A stack trace is not a report

`worker-a` died on the division, and the JVM printed `Exception in thread "worker-a"` with the trace.
Then **`main` carried on and printed its next line**, with no way of knowing what happened. In a terminal
someone might notice the trace. In a server whose output goes to a log nobody reads, a thread that was
meant to process orders stops and the program keeps answering as though all were well. That is the
failure this repository's rules call silent, and it is the most common way threads lose work.

`setUncaughtExceptionHandler` gives the thread a place to report its death: the handler received the
thread and the exception, and could log it, count it, or stop the program on purpose. There is also a
default handler for every thread, `Thread.setDefaultUncaughtExceptionHandler`, set once at start-up.
Lesson 16 shows a better answer still: with an executor, the exception is kept and handed to whoever
asks for the task's result.

## Daemons

`daemon.setDaemon(true)` marked the third thread as a **daemon**: a helper the JVM does not wait for.
The program exits when its last non-daemon thread ends, so `main` returned and the JVM stopped,
taking the sleeping daemon with it, which is why its line never appeared. A thread you forget to join
keeps the JVM alive if it is not a daemon, and a daemon you rely on is killed halfway through its work
when `main` ends. Neither is a reason to avoid them; both are reasons to decide on purpose.
