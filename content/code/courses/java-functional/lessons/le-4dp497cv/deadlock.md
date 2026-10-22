---
title: Deadlock
version: 1
---

**A deadlock is two or more threads each holding a lock the other needs, each waiting for the other to
let go.** None of them ever will, so the program stops without an error, a message or a spinning
processor: it simply does nothing, forever. The classic case is a transfer between two accounts that
locks the sender first and the receiver second:

```java
// Deadlock.java: two transfers that lock two accounts in opposite orders
public class Deadlock {
    static class Account {
        final String id;
        long cents;

        Account(String id, long cents) {
            this.id = id;
            this.cents = cents;
        }
    }

    static void transfer(Account from, Account to, long cents) {
        synchronized (from) {
            pause();
            synchronized (to) {
                from.cents -= cents;
                to.cents += cents;
            }
        }
    }

    static void pause() {
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Account shop = new Account("shop", 100_000);
        Account supplier = new Account("supplier", 50_000);
        Thread a = Thread.ofPlatform().name("pay-supplier").start(() -> transfer(shop, supplier, 2_000));
        Thread b = Thread.ofPlatform().name("refund-shop").start(() -> transfer(supplier, shop, 500));
        a.join();
        b.join();
        System.out.println("never printed");
    }
}
```

`pay-supplier` locks `shop` and then wants `supplier`; `refund-shop` locks `supplier` and then wants
`shop`. The `pause` holds each thread inside its first lock long enough for the other to take its own.
Start it in the background, then ask the JVM what its threads are doing. `jcmd` sends commands to a
running JVM; with no arguments it lists the JVMs running under your user, each after its process id, and
`Thread.print` is the thread dump from lesson 11 section 03. `kill` with the same id ends the program:

```
ana@vm:~/fp/locks$ java Deadlock.java > /dev/null &
ana@vm:~/fp/locks$ jcmd | grep Deadlock
15108 jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher Deadlock.java
ana@vm:~/fp/locks$ jcmd 15108 Thread.print | grep -A 16 'Found one'
Found one Java-level deadlock:
=============================
"pay-supplier":
  waiting to lock monitor 0x00007f4978002130 (object 0x00000007360c30a0, a Deadlock$Account),
  which is held by "refund-shop"

"refund-shop":
  waiting to lock monitor 0x00007f496c000f20 (object 0x00000007360c3058, a Deadlock$Account),
  which is held by "pay-supplier"

Java stack information for the threads listed above:
===================================================
"pay-supplier":
	at Deadlock.transfer(Deadlock.java:17)
	- waiting to lock <0x00000007360c30a0> (a Deadlock$Account)
	- locked <0x00000007360c3058> (a Deadlock$Account)
	at Deadlock.lambda$main$0(Deadlock.java:34)
ana@vm:~/fp/locks$ kill 15108
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A cycle of four boxes. Thread pay-supplier holds the lock on shop and waits for the lock on supplier. Thread refund-shop holds the lock on supplier and waits for the lock on shop. Arrows go from each thread to the lock it holds, and from each thread to the lock it wants, which the other thread holds, closing the cycle.\"><defs><marker id=\"cycle-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"cycle-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">pay-supplier</text><rect x=\"480\" y=\"150\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">refund-shop</text><rect x=\"480\" y=\"20\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">lock on shop</text><rect x=\"40\" y=\"150\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">lock on supplier</text><path d=\"M240 45 L476 45\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#cycle-ah-phosphor)\"></path><text x=\"358\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">holds</text><path d=\"M480 175 L244 175\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#cycle-ah-phosphor)\"></path><text x=\"362\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">holds</text><path d=\"M140 70 L140 146\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#cycle-ah-amber)\"></path><text x=\"150\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">waits for</text><path d=\"M580 150 L580 74\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#cycle-ah-amber)\"></path><text x=\"570\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">waits for</text></svg>", "caption": "Each thread holds what the other wants; neither will let go, so neither moves."}
```

## The dump says it outright

**`Found one Java-level deadlock`**, and then the cycle: `pay-supplier` waits for a monitor held by
`refund-shop`, which waits for one held by `pay-supplier`. The stack information below names the line,
`Deadlock.java:17`, the inner `synchronized`, and which lock each thread holds and wants. A hung program in production gets the
same treatment: a thread dump first, and it often answers the question in one paragraph.

## Preventing it: one order for every lock

A deadlock needs a cycle, and a cycle needs two threads to take the same locks in different orders.
**Take locks in one global order** and the cycle cannot form. For accounts, order by something every
thread agrees on:

```java
// Ordered.java: the same transfers, locking the two accounts in id order
public class Ordered {
    static class Account {
        final String id;
        long cents;

        Account(String id, long cents) {
            this.id = id;
            this.cents = cents;
        }
    }

    static void transfer(Account from, Account to, long cents) {
        Account first = from.id.compareTo(to.id) < 0 ? from : to;
        Account second = first == from ? to : from;
        synchronized (first) {
            Deadlock.pause();
            synchronized (second) {
                from.cents -= cents;
                to.cents += cents;
            }
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Account shop = new Account("shop", 100_000);
        Account supplier = new Account("supplier", 50_000);
        Thread a = Thread.ofPlatform().start(() -> transfer(shop, supplier, 2_000));
        Thread b = Thread.ofPlatform().start(() -> transfer(supplier, shop, 500));
        a.join();
        b.join();
        System.out.println("shop " + shop.cents + ", supplier " + supplier.cents);
    }
}
```

```
ana@vm:~/fp/locks$ java Ordered.java
shop 98500, supplier 51500
```

Both transfers now lock `shop` before `supplier`, whichever direction the money goes, and they finish:
`shop` paid 2,000 and received 500. `tryLock` with a timeout, from section 04, is the other defence:
a thread that cannot get its second lock gives up the first and tries again later. Fewer locks is the
best defence of all, and lessons 15 and 16 are mostly about tools that need none.
