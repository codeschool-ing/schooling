---
title: Checked and unchecked, and what the compiler demands
version: 1
---

Section 02's exceptions surprised the compiler as much as the program: nothing in `Fine.java` said
that `parseInt` might throw, and `javac` compiled it without a word. Some exceptions are different.
**For a checked exception, the compiler insists that every method either catches it or declares that
it throws it**, and refuses the file otherwise.

Reading a file is the standard example. This program counts the loans in `loans.txt`, one per line:

```java
// Count.java
import java.nio.file.Files;
import java.nio.file.Path;

public class Count {
    public static void main(String[] args) {
        String text = Files.readString(Path.of("loans.txt"));
        System.out.println(text.lines().count() + " loans");
    }
}
```

```
ana@vm:~/exc$ javac Count.java
Count.java:7: error: unreported exception IOException; must be caught or declared to be thrown
        String text = Files.readString(Path.of("loans.txt"));
                                      ^
1 error
```

`Files.readString` declares `throws IOException`, because a file can be missing, unreadable or on a
disk that has just gone away. **`IOException` is checked**, so the compiler stopped at the call and
named the two choices: catch it there, or declare it, which passes the duty to whoever calls `main`.

Declaring it is one change, on the line that declares `main`:

```java
// Count.java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class Count {
    public static void main(String[] args) throws IOException {
        String text = Files.readString(Path.of("loans.txt"));
        System.out.println(text.lines().count() + " loans");
    }
}
```

```
ana@vm:~/exc$ javac Count.java && java Count
Exception in thread "main" java.nio.file.NoSuchFileException: loans.txt
	at java.base/sun.nio.fs.UnixException.translateToIOException(UnixException.java:92)
	at java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:106)
	at java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:111)
	at java.base/sun.nio.fs.UnixFileSystemProvider.newFileChannel(UnixFileSystemProvider.java:213)
	at java.base/sun.nio.fs.UnixFileSystemProvider.newByteChannel(UnixFileSystemProvider.java:244)
	at java.base/java.nio.file.Files.newByteChannel(Files.java:357)
	at java.base/java.nio.file.Files.newByteChannel(Files.java:399)
	at java.base/java.nio.file.Files.readAllBytes(Files.java:2973)
	at java.base/java.nio.file.Files.readString(Files.java:3043)
	at java.base/java.nio.file.Files.readString(Files.java:3006)
	at Count.main(Count.java:8)
```

**It compiled, and it failed exactly as the declaration warned it might**: `NoSuchFileException`, an
`IOException`, because there was no `loans.txt` yet. Ten frames inside the JDK, and one of yours,
at line 8. Write the file and run it again:

```
ana@vm:~/exc$ printf "Dune\nEmma\nUlysses\n" > loans.txt
ana@vm:~/exc$ java Count
3 loans
```

`throws IOException` on `main` is right for a program this small. The JVM is `main`'s caller, and a
stack trace is a fair answer to a missing file. In a larger program, the method that knows what a
missing file means, such as one that shows a message on a screen, is the one that catches it.

## Which exceptions are checked

The rule is about the class, and it is short:

| class | checked? | what it is for | examples from this lesson |
|---|---|---|---|
| `RuntimeException` and its subclasses | no | mistakes in the program, which a correct program does not make | `NumberFormatException`, `ArithmeticException`, `NullPointerException` |
| other subclasses of `Exception` | **yes** | conditions outside the program, which a correct program still meets | `IOException`, `NoSuchFileException` |
| `Error` and its subclasses | no | the JVM itself in trouble | `OutOfMemoryError`, `StackOverflowError` |

The logic is in the middle column. **A checked exception is one a correct program must be ready for**:
a perfect program still meets a missing file, so the compiler makes sure somebody decided what to do
about it. An unchecked one is a bug: `parseInt("ten")` is fixed by not passing `"ten"`, and forcing
every caller of `parseInt` to write a `catch` would bury real handling under ceremony.

The line is drawn by the JDK's designers and it is not always where you would draw it; `parseInt`
reading user input is arguably a condition outside the program. Lesson 38 draws the whole hierarchy
and decides, for an exception of the course's own, which side it belongs on.
