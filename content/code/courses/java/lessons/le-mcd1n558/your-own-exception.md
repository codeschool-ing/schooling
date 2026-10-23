---
title: An exception of your own
version: 1
---

The JDK's exceptions name what went wrong in the JDK's terms: a file was missing, a string was not a
number, an index was out of range. A program has failures of its own that none of those names fit.
**A member who already holds two books may not borrow a third**, and saying so with
`IllegalStateException` tells the caller that something went wrong without saying what. A class of
your own says what, and it can carry the details a caller needs to act on it.

## A checked one, for a failure the caller can handle

Writing one takes a class that extends the right ancestor and a constructor that passes a message up:

```java
// LoanNotAllowedException.java
public class LoanNotAllowedException extends Exception {
    private final String memberId;

    public LoanNotAllowedException(String memberId, String reason) {
        super("member " + memberId + " may not borrow: " + reason);
        this.memberId = memberId;
    }

    public String memberId() {
        return memberId;
    }
}
```

Three decisions are in those lines:

1. **The name ends in `Exception`**, as every exception class in the JDK does. A reader knows what it
   is before reading its body.
2. **It extends `Exception`, so it is checked.** A refused loan is an ordinary event at a library
   desk, and the caller can do something sensible with it: tell the member. Making it checked means
   the compiler will not let any caller forget that.
3. **`super(...)` builds the message**, which is what `getMessage()` returns and what a stack trace
   prints. The `memberId` field is the extra a caller may want, kept as data rather than buried in the
   text.

The desk that throws it, with a limit of two books, and a `main` that tries to lend three:

```java
// Desk.java
import java.util.HashMap;
import java.util.Map;

public class Desk {
    static final int LIMIT = 2;
    private final Map<String, Integer> loans = new HashMap<>();

    public void lend(String memberId, String isbn) throws LoanNotAllowedException {
        int held = loans.getOrDefault(memberId, 0);
        if (held >= LIMIT) {
            throw new LoanNotAllowedException(memberId, "already holds " + held + " books");
        }
        loans.put(memberId, held + 1);
        System.out.println("lent " + isbn + " to " + memberId);
    }

    public static void main(String[] args) {
        Desk desk = new Desk();
        String[] isbns = {"978-0-13-468599-1", "978-1-61729-136-8", "978-0-596-00920-5"};
        for (String isbn : isbns) {
            try {
                desk.lend("ana", isbn);
            } catch (LoanNotAllowedException e) {
                System.out.println("refused: " + e.getMessage());
                System.out.println("tell member " + e.memberId() + " at the desk");
            }
        }
    }
}
```

```
ana@vm:~/hierarchy$ javac LoanNotAllowedException.java Desk.java && java Desk
lent 978-0-13-468599-1 to ana
lent 978-1-61729-136-8 to ana
refused: member ana may not borrow: already holds 2 books
tell member ana at the desk
```

The third loan was refused, and the `catch` used both halves of the exception: the message for the
log line and `memberId()` for the next step. **`throws LoanNotAllowedException` on `lend` is part of
its signature**, as much as its parameters are. A caller that neither catches it nor declares it is
refused at compile time:

```java
// Careless.java
public class Careless {
    public static void main(String[] args) {
        new Desk().lend("ana", "978-0-13-468599-1");
    }
}
```

```
ana@vm:~/hierarchy$ javac Careless.java
Careless.java:4: error: unreported exception LoanNotAllowedException; must be caught or declared to be thrown
        new Desk().lend("ana", "978-0-13-468599-1");
                       ^
1 error
```

## An unchecked one, and the cause it carries

Some failures leave the caller nothing sensible to do. If the catalogue file cannot be read, the code
asking for a book cannot fix a disk, and forcing every caller to catch the problem only produces empty
`catch` blocks, which section 04 is about. **Such a failure is a `RuntimeException`**, and it travels
up to whichever layer can report it, often the top of the program or of a request.

What it must not lose is the original exception. Every exception constructor in the JDK has a form
that takes a `Throwable cause`, and passing it on is a matter of declaring the same form:

```java
// CatalogueUnavailableException.java
public class CatalogueUnavailableException extends RuntimeException {
    public CatalogueUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

```java
// Catalogue.java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

public class Catalogue {
    static List<String> load(Path file) {
        try {
            return Files.readAllLines(file);
        } catch (IOException e) {
            throw new CatalogueUnavailableException("cannot load the catalogue from " + file, e);
        }
    }

    public static void main(String[] args) {
        List<String> books = load(Path.of(args[0]));
        System.out.println(books.size() + " books");
    }
}
```

`load` catches the `IOException` it cannot handle and throws the new exception with **both a message
in this program's terms and the original as its cause**. With a file it works; without one, it reports
both layers:

```
ana@vm:~/hierarchy$ javac CatalogueUnavailableException.java Catalogue.java
ana@vm:~/hierarchy$ printf "Effective Java\nJava Concurrency in Practice\n" > catalogue.txt && java Catalogue catalogue.txt
2 books
ana@vm:~/hierarchy$ java Catalogue missing.txt
Exception in thread "main" CatalogueUnavailableException: cannot load the catalogue from missing.txt
	at Catalogue.load(Catalogue.java:12)
	at Catalogue.main(Catalogue.java:17)
Caused by: java.nio.file.NoSuchFileException: missing.txt
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
	at java.base/java.nio.file.Files.readAllLines(Files.java:3085)
	at java.base/java.nio.file.Files.readAllLines(Files.java:3122)
	at Catalogue.load(Catalogue.java:10)
	... 1 more
```

The trace now has two parts. The top says what failed in this program, `cannot load the catalogue
from missing.txt`, at `Catalogue.load`. **`Caused by:` says why**, with the JDK's own exception and
its own frames. The last line, `... 1 more`, says one frame of the cause's trace is the same as the
frame above it, `Catalogue.main`, and is not repeated.

That is the third way two exceptions travel together. Lesson 37's suppressed exception is a second
failure *beside* the first; a cause is the failure *underneath* it, the reason the outer one was
thrown. `getCause()` returns it, and a logging library prints the whole chain when it is handed the
outer one.
