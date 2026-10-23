---
title: Closing
version: 1
---

**An open stream holds a resource of the operating system, a file descriptor, and the operating system
gives each process a limited number of them.** A stream that is never closed keeps its descriptor until
the garbage collector happens to clean up, which may be never. A program that opens files in a loop and
forgets to close them runs out:

```java
// Leak.java: opening a file again and again without closing it
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class Leak {
    public static void main(String[] args) throws IOException {
        Files.writeString(Path.of("orders.txt"), "1,Dune\n");
        for (int i = 1; i <= 100; i++) {
            try {
                FileInputStream in = new FileInputStream("orders.txt");
                in.read();
            } catch (IOException e) {
                System.out.println("file " + i + ": " + e.getMessage());
                return;
            }
        }
        System.out.println("opened 100 files");
    }
}
```

`ulimit -n` sets how many descriptors the shell's programs may hold. The usual limit on Ubuntu is 1,024;
the brackets run the program with a limit of 64, so the failure arrives quickly, and leave the terminal's
own limit as it was:

```
ana@vm:~/fp/io$ (ulimit -n 64; java Leak.java)
file 61: orders.txt (Too many open files)
```

The JVM itself holds a few dozen descriptors for its own files, and **the 61st `FileInputStream` was
refused** with `Too many open files`. In a server that leaks one descriptor per request, the same message
arrives after a few thousand requests, from whichever code happens to open the next file or socket, far
from the leak.

## try-with-resources, always

The cure is lesson 37 of `java`: declare the stream in a `try` with resources, and it is closed when the
block ends, normally or by an exception. With layers, **close the outermost one**; each stream closes the
stream it wraps, so one `close` on a `BufferedReader` closes the reader, the bridge and the file.

```java
// NoLeak.java: the same loop with try-with-resources
import java.io.FileInputStream;
import java.io.IOException;

public class NoLeak {
    public static void main(String[] args) throws IOException {
        for (int i = 1; i <= 100; i++) {
            try (FileInputStream in = new FileInputStream("orders.txt")) {
                in.read();
            }
        }
        System.out.println("opened and closed 100 files");
    }
}
```

```
ana@vm:~/fp/io$ (ulimit -n 64; java NoLeak.java)
opened and closed 100 files
```

The same 64 descriptors were enough for a hundred files, and for a million, because each was returned
before the next was taken.
