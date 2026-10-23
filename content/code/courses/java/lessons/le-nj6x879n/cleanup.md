---
title: Cleaning up, and the method that was never called
version: 1
---

The collector reclaims memory. An object can hold things that are not memory: an open file, a
network connection, a lock on a database row. **Nothing about garbage collection closes those**,
and Java's first answer to that, a method the collector would call on an object before freeing it,
turned out to be one of the language's well-known mistakes. It is worth one section to know why,
because older code is full of it.

## `finalize`, deprecated for removal

Every class inherits a method `finalize()` from `Object`, and a class could override it, expecting
the collector to call it on the way out. `Tidy` does:

```java
// Tidy.java
public class Tidy {
    @Override
    protected void finalize() {
        System.out.println("finalize ran");
    }

    public static void main(String[] args) {
        new Tidy();
        System.out.println("main ends");
    }
}
```

```
ana@vm:~/lifecycle$ javac Tidy.java
Tidy.java:4: warning: [removal] finalize() in Object has been deprecated and marked for removal
    protected void finalize() {
                   ^
1 warning
ana@vm:~/lifecycle$ java Tidy
main ends
```

Two things went wrong, and only one of them was announced.

**The compiler warned**, without being asked: `finalize()` has been deprecated and **marked for
removal** since Java 18, so a future JDK will not call it at all. A `[removal]` warning is the
strongest kind of deprecation, and lesson 39 shows how a library marks one of its own methods that
way.

**And the program printed `main ends` and nothing else.** The object became garbage on the line it
was created, and `finalize` never ran: the program finished before the collector had any reason to
run, and the JVM does not collect the heap on its way out. That is the design flaw in one line of
output. **Nobody knows when, or whether, a finaliser runs**, so it cannot be trusted to close a file
that another part of the program wants to open, or to release a lock that another user is waiting
for.

## What replaced it

Two things, for two situations:

- **Close it yourself, at a known point.** A class that holds something to release implements a
  `close()` method, and the code that opened it calls `close()` when it is done, which Java makes
  hard to forget with `try`-with-resources. That is lesson 37, and it is the answer nearly every
  time.
- **`java.lang.ref.Cleaner`, as a safety net.** A `Cleaner` runs an action after an object has
  become unreachable, and unlike `finalize` the action cannot bring the object back to life. It has
  the same uncertainty about *when*, so it is a backstop for a resource somebody forgot to close,
  never the main way of closing it.

**The rule this lesson leaves is the same rule twice**: memory is the collector's business and
needs nothing from you, and everything else an object holds is yours to release at a moment you
choose.
