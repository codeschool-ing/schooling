---
title: What a finally block was asked to do
version: 1
---

Some objects hold something that is not memory: an open file, a connection to a database, a socket.
The garbage collector of lesson 19 gives memory back on its own schedule and **gives nothing else
back at all**, so a program that opens one of these has to close it, on every path out of the code
that used it. Lesson 36's `finally` was the tool for that, and this section shows what it costs.

The resource here is made up, so that it can be broken on purpose. Save it in `~/twr` as
`Resource.java`:

```schooling-example
{
  "language": "java",
  "file": "Resource.java",
  "parts": [
    {
      "code": "// Resource.java\npublic class Resource {\n    private final String name;\n    private final boolean failOnClose;",
      "note": "**A stand-in for anything that has to be given back**: a file, a database connection, a socket. It keeps a name to print and one switch that makes closing fail, so the lesson can break it on purpose."
    },
    {
      "code": "\n    public Resource(String name, boolean failOnClose) {\n        this.name = name;\n        this.failOnClose = failOnClose;\n        System.out.println(\"open \" + name);\n    }",
      "note": "**Opening is the constructor.** From the line `open` on, something outside the program is held, and somebody has to release it."
    },
    {
      "code": "\n    public void use(boolean fail) {\n        System.out.println(\"use \" + name);\n        if (fail) {\n            throw new IllegalStateException(\"use of \" + name + \" failed\");\n        }\n    }",
      "note": "`use` is the work. Passed `true`, it throws, the way a read fails on a full disk or a query on a lost connection."
    },
    {
      "code": "\n    public void close() {\n        System.out.println(\"close \" + name);\n        if (failOnClose) {\n            throw new IllegalStateException(\"close of \" + name + \" failed\");\n        }\n    }\n}",
      "note": "`close` gives the resource back and says so. **Closing can fail too**: a file whose last bytes cannot be written fails here, after the work looked finished."
    }
  ]
}
```

## The leak

The first program opens, uses and closes, in that order, as most first attempts do:

```java
// Leak.java
public class Leak {
    public static void main(String[] args) {
        Resource r = new Resource("loans.db", false);
        r.use(true);
        r.close();
    }
}
```

```
ana@vm:~/twr$ javac *.java
ana@vm:~/twr$ java Leak; echo "exit $?"
open loans.db
use loans.db
Exception in thread "main" java.lang.IllegalStateException: use of loans.db failed
	at Resource.use(Resource.java:15)
	at Leak.main(Leak.java:5)
exit 1
```

`open`, `use`, and then the exception. **There is no `close` line.** The exception left `main` at
line 5, and line 6 never ran. Here the process ended a moment later, and the operating system took
back whatever it held. A server does not end: it catches the exception, answers the next request, and
leaks one more connection each time `use` fails, until the pool is empty and every request waits.

## The repair, and its price

`finally` runs however the `try` block is left, so the close moves there:

```java
// Finally.java
public class Finally {
    public static void main(String[] args) {
        Resource r = new Resource("loans.db", false);
        try {
            r.use(true);
        } finally {
            r.close();
        }
    }
}
```

```
ana@vm:~/twr$ java Finally
open loans.db
use loans.db
close loans.db
Exception in thread "main" java.lang.IllegalStateException: use of loans.db failed
	at Resource.use(Resource.java:15)
	at Finally.main(Finally.java:6)
```

`close loans.db` is there, and the exception still reaches the caller. That is correct, and it took
four lines and a variable declared outside the `try` so that `finally` can see it. With two resources
it takes nested `try` blocks, because the second must be closed even when closing the first fails.

## The masked exception

The repair has a hole that only shows when closing fails as well. `Masked` is `Finally` with the
resource's second argument set to `true`:

```java
// Masked.java
public class Masked {
    public static void main(String[] args) {
        Resource r = new Resource("loans.db", true);
        try {
            r.use(true);
        } finally {
            r.close();
        }
    }
}
```

```
ana@vm:~/twr$ java Masked
open loans.db
use loans.db
close loans.db
Exception in thread "main" java.lang.IllegalStateException: close of loans.db failed
	at Resource.close(Resource.java:22)
	at Masked.main(Masked.java:8)
```

Read the stack trace and you would go looking at `close`. **The failure that started it all, `use of
loans.db failed`, is gone.** When `finally` throws, its exception replaces the one already on its way
out, and nothing keeps the first. Whoever reads this log at three in the morning fixes the wrong
thing. Section 03 removes the boilerplate, and section 04 shows where the lost exception goes instead.
