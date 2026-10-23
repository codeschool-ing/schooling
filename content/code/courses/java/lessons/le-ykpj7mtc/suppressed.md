---
title: Where the second exception goes
version: 1
---

Section 02 ended with an exception thrown by `close` erasing the one thrown by `use`. try-with-resources
has to decide the same question, two exceptions and one way out, and **it keeps the first one and
attaches the second to it** as a *suppressed* exception. Nothing is lost, and the one you read first
is the one that started the trouble.

`Suppressed` is `Masked` from section 02, rewritten with the new `try`. The resource fails while being
used and again while being closed:

```java
// Suppressed.java
public class Suppressed {
    public static void main(String[] args) {
        try (Resource r = new Resource("loans.db", true)) {
            r.use(true);
        }
    }
}
```

```
ana@vm:~/twr$ javac Suppressed.java Inspect.java
ana@vm:~/twr$ java Suppressed
open loans.db
use loans.db
close loans.db
Exception in thread "main" java.lang.IllegalStateException: use of loans.db failed
	at Resource.use(Resource.java:15)
	at Suppressed.main(Suppressed.java:5)
	Suppressed: java.lang.IllegalStateException: close of loans.db failed
		at Resource.close(Resource.java:23)
		at Suppressed.main(Suppressed.java:4)
```

The main line is `use of loans.db failed`, the original cause, at `Resource.use`. **Below its own
stack trace sits a line starting with `Suppressed:`**, indented one step further, carrying the close
failure and a stack trace of its own. Compare it with the output of `Masked`, which reported only the
close: same resource, same two failures, and this time both are on the screen in the order they
happened.

The line numbers moved by one against section 02 (`Resource.java:23` for the close, where `Masked`
said 22) because this `Resource.java` is the version from section 03, with `@Override` added above
`close`. A stack trace numbers the lines of the file that was compiled, which is worth remembering
when the source in front of you is not that file.

## Reading them from code

Every `Throwable` carries the list, and `getSuppressed()` returns it as an array. With two resources
that both fail to close, the list has two entries:

```java
// Inspect.java
public class Inspect {
    public static void main(String[] args) {
        try (Resource db = new Resource("loans.db", true);
             Resource log = new Resource("audit.log", true)) {
            db.use(true);
        } catch (IllegalStateException e) {
            System.out.println("main:       " + e.getMessage());
            for (Throwable s : e.getSuppressed()) {
                System.out.println("suppressed: " + s.getMessage());
            }
        }
    }
}
```

```
ana@vm:~/twr$ java Inspect
open loans.db
open audit.log
use loans.db
close audit.log
close loans.db
main:       use of loans.db failed
suppressed: close of audit.log failed
suppressed: close of loans.db failed
```

The resources closed in reverse order, as section 03 showed, and **the suppressed exceptions are in
the order they were added**, which is that same reverse order: `audit.log` first. A logging library
prints them for you when you pass it the exception, and the JVM's own `Exception in thread "main"`
report printed them above without being asked. You call `getSuppressed()` yourself only when you
handle the exception and want to say something about every failure in it.

## The rule, all in one place

| what failed | what the caller receives |
|---|---|
| the body only | the body's exception |
| `close` only | the exception from `close` |
| the body, then `close` | the body's exception, with the one from `close` suppressed inside it |
| the body, then two closes | the body's exception, with both closes suppressed, last opened first |

**The exception from the body always wins**, because it is the one that explains why the work did not
happen. A failure to close is real and worth knowing about, and it is almost never the cause. Lesson 38
adds the third way two exceptions travel together, the *cause*, which is for one exception that
explains another rather than one that happened alongside it.
