---
title: try-with-resources
version: 1
---

Java 7 added a form of `try` that closes things by itself. You declare the resource in parentheses
after `try`, and **the compiler writes the `finally` for you**, including the parts section 02 got
wrong. The only thing it asks of the resource is that its class implement one interface with one
method, `java.lang.AutoCloseable`, whose method is `close()`.

`Resource` already has a `close()`, so two changes make it qualify: `implements AutoCloseable` on
the class line, and `@Override` above `close`, which lesson 24 explained and lesson 39 comes back to.
Replace `~/twr/Resource.java` with this version:

```java
// Resource.java
public class Resource implements AutoCloseable {
    private final String name;
    private final boolean failOnClose;

    public Resource(String name, boolean failOnClose) {
        this.name = name;
        this.failOnClose = failOnClose;
        System.out.println("open " + name);
    }

    public void use(boolean fail) {
        System.out.println("use " + name);
        if (fail) {
            throw new IllegalStateException("use of " + name + " failed");
        }
    }

    @Override
    public void close() {
        System.out.println("close " + name);
        if (failOnClose) {
            throw new IllegalStateException("close of " + name + " failed");
        }
    }
}
```

Then the leak of section 02, written the new way:

```java
// Twr.java
public class Twr {
    public static void main(String[] args) {
        try (Resource r = new Resource("loans.db", false)) {
            r.use(true);
        }
    }
}
```

```
ana@vm:~/twr$ javac Resource.java Twr.java Order.java CountLines.java
ana@vm:~/twr$ java Twr
open loans.db
use loans.db
close loans.db
Exception in thread "main" java.lang.IllegalStateException: use of loans.db failed
	at Resource.use(Resource.java:15)
	at Twr.main(Twr.java:5)
```

**`close loans.db` printed before the exception left `main`.** No `finally`, no variable outside the
block, and the variable `r` exists only inside the `try`, so no code after it can use a closed
resource by mistake. That last part is easy to miss: in `Finally.java` the variable stayed in scope
after the close, and nothing stopped a later line from calling `r.use(false)` on it.

## Two resources, and the order they close in

Several resources go in the same parentheses, separated by semicolons. A `catch` and a `finally` can
follow, like on any `try`:

```java
// Order.java
public class Order {
    public static void main(String[] args) {
        try (Resource db = new Resource("loans.db", false);
             Resource log = new Resource("audit.log", false)) {
            db.use(false);
            log.use(true);
        } catch (IllegalStateException e) {
            System.out.println("caught: " + e.getMessage());
        } finally {
            System.out.println("finally");
        }
    }
}
```

```
ana@vm:~/twr$ java Order
open loans.db
open audit.log
use loans.db
use audit.log
close audit.log
close loans.db
caught: use of audit.log failed
finally
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"The order of events in Order.java. loans.db opens, then audit.log opens. The body uses both and throws. audit.log closes, then loans.db closes. Only then does the catch run, and the finally runs last. Each resource is in scope only inside its own box.\"><defs><marker id=\"jv37-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"22\" width=\"400\" height=\"176\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"70\" y=\"57\" width=\"340\" height=\"106\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"100\" y=\"92\" width=\"280\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">open loans.db</text><text x=\"240\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">open audit.log</text><text x=\"240\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">use loans.db, use audit.log: throws</text><text x=\"240\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">close audit.log</text><text x=\"240\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">close loans.db</text><rect x=\"40\" y=\"212\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">catch: caught: use of audit.log failed</text><rect x=\"40\" y=\"252\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"267\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">finally</text><text x=\"462\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">opened second</text><text x=\"462\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">so it closes first</text><text x=\"462\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">opened first</text><text x=\"462\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and this one closes last</text><text x=\"462\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the body throws here</text><text x=\"462\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the handler runs after every close</text><text x=\"462\" y=\"267\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and finally after that</text></svg>", "caption": "Each resource is closed when the block it opened leaves, innermost first, and before any catch sees the exception."}
```

Three things in that output, and each is a rule:

1. **Resources open in the order they are written and close in the reverse order.** `audit.log` was
   opened second, so it closed first. A later resource may depend on an earlier one, a writer built
   on a file for instance, and closing in reverse never pulls the floor out from under it.
2. **Both closes ran before the `catch`.** By the time your handler sees the exception, every
   resource is already given back, so the handler cannot use them and does not need to close them.
3. `finally` ran last, after the `catch`, as it does on any `try`.

## A real resource

The JDK's own files, streams, readers, writers, sockets and database connections all implement
`AutoCloseable`, most of them through its older sub-interface `java.io.Closeable`. This program counts
the lines of a file with a `BufferedReader` from `java.nio.file.Files`:

```java
// CountLines.java
import java.io.BufferedReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class CountLines {
    public static void main(String[] args) throws IOException {
        int lines = 0;
        try (BufferedReader in = Files.newBufferedReader(Path.of(args[0]))) {
            while (in.readLine() != null) {
                lines++;
            }
        }
        System.out.println(args[0] + ": " + lines + " lines");
    }
}
```

Create a three-line file to count, and then ask for one that does not exist:

```
ana@vm:~/twr$ printf "978-0-13-468599-1 ana\n978-1-61729-136-8 rui\n978-0-596-00920-5 ana\n" > loans.txt
ana@vm:~/twr$ java CountLines loans.txt
loans.txt: 3 lines
ana@vm:~/twr$ java CountLines missing.txt
Exception in thread "main" java.nio.file.NoSuchFileException: missing.txt
	at java.base/sun.nio.fs.UnixException.translateToIOException(UnixException.java:92)
	at java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:106)
	at java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:111)
	at java.base/sun.nio.fs.UnixFileSystemProvider.newFileChannel(UnixFileSystemProvider.java:213)
	at java.base/sun.nio.fs.UnixFileSystemProvider.newByteChannel(UnixFileSystemProvider.java:244)
	at java.base/java.nio.file.Files.newByteChannel(Files.java:357)
	at java.base/java.nio.file.Files.newByteChannel(Files.java:399)
	at java.base/java.nio.file.spi.FileSystemProvider.newInputStream(FileSystemProvider.java:371)
	at java.base/java.nio.file.Files.newInputStream(Files.java:154)
	at java.base/java.nio.file.Files.newBufferedReader(Files.java:2645)
	at java.base/java.nio.file.Files.newBufferedReader(Files.java:2674)
	at CountLines.main(CountLines.java:10)
```

The reader was closed on both paths. On the second, `Files.newBufferedReader` threw before the reader
existed, so there was nothing to close, and **try-with-resources only closes what was actually
opened**: a resource whose initialiser throws is never closed, because it is not there. The long stack
trace is the JDK's own methods, top to bottom; the last line, `CountLines.main(CountLines.java:10)`,
is the one that belongs to you, and it points at the `try` line. `throws IOException` on `main` is
lesson 36's checked exception, passed on rather than handled.

## What does not qualify

A class without `AutoCloseable` is refused at compile time, however obvious its use looks:

```java
// NotCloseable.java
public class NotCloseable {
    public static void main(String[] args) {
        try (StringBuilder sb = new StringBuilder()) {
            sb.append("loan");
        }
    }
}
```

```
ana@vm:~/twr$ javac NotCloseable.java
NotCloseable.java:4: error: incompatible types: try-with-resources not applicable to variable type
        try (StringBuilder sb = new StringBuilder()) {
                           ^
    (StringBuilder cannot be converted to AutoCloseable)
1 error
```

`StringBuilder` holds only memory, so it has nothing to give back and no `close` method, and the
compiler says exactly that. **The rule is the interface, not the name of a method**: section 02's
first `Resource` had a perfectly good `close()` and would have been refused the same way.
