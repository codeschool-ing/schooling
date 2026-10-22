---
title: When the file system says no
version: 1
---

**Every method of `Files` reports a refusal with an exception that names what went wrong and the path it
went wrong on.** They are all subclasses of `FileSystemException`, itself an `IOException`, so code can
catch the one it has a plan for and let the rest go up:

```java
// Failures.java: three things the file system refuses, each with its own exception
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class Failures {
    public static void main(String[] args) throws IOException {
        Path shelf = Path.of("shelf");
        Files.createDirectories(shelf);
        Files.writeString(shelf.resolve("dune.txt"), "Dune\n");

        attempt("read a missing file", () -> Files.readString(Path.of("missing.txt")));
        attempt("create it again", () -> Files.createDirectory(shelf));
        attempt("create it again, leniently", () -> Files.createDirectories(shelf));
        attempt("delete it while full", () -> Files.delete(shelf));
    }

    interface Action {
        void run() throws IOException;
    }

    static void attempt(String label, Action action) {
        try {
            action.run();
            System.out.println(label + ": done");
        } catch (IOException e) {
            System.out.println(label + ": " + e.getClass().getSimpleName() + ", " + e.getMessage());
        }
    }
}
```

```
ana@vm:~/fp/files$ java Failures.java
read a missing file: NoSuchFileException, missing.txt
create it again: FileAlreadyExistsException, shelf
create it again, leniently: done
delete it while full: DirectoryNotEmptyException, shelf
```

Each refusal arrived with its own class: **`NoSuchFileException`** for the missing file,
**`FileAlreadyExistsException`** for a directory created twice, **`DirectoryNotEmptyException`** for a
delete that would have lost a file. `createDirectories` is the lenient one: a directory already there
is what it was asked for, so it returned without complaint. The message is the path, and the class says what happened
to it. `Action` is a functional interface of the program's own because it may throw `IOException`, the
same problem the helpers of section 04 solved the other way.

## A name from outside stays inside

A server that sends files from a folder takes the name from the request, and the request is written by
whoever sends it. `../` is a legal part of a path, so **a name joined to the folder without a check can
point anywhere the program is allowed to read**. The defence is to resolve the name, normalize the result
and check that it still starts with the folder:

```java
// Inside.java: a name that arrives from outside must stay inside its directory
import java.nio.file.Path;

public class Inside {
    static final Path BASE = Path.of("library").toAbsolutePath().normalize();

    static Path inside(String name) {
        Path p = BASE.resolve(name).normalize();
        if (!p.startsWith(BASE)) {
            throw new IllegalArgumentException("outside the library: " + name);
        }
        return p;
    }

    public static void main(String[] args) {
        for (String name : new String[] {"dune.txt", "fiction/../emma.txt", "../orders.csv", "/etc/hostname"}) {
            try {
                System.out.println(name + " -> " + BASE.relativize(inside(name)));
            } catch (IllegalArgumentException e) {
                System.out.println(name + " -> refused, " + e.getMessage());
            }
        }

        Path sibling = BASE.resolve("../library-old/notes.txt").normalize();
        System.out.println("as strings: " + sibling.toString().startsWith(BASE.toString()));
        System.out.println("as paths:   " + sibling.startsWith(BASE));
    }
}
```

```
ana@vm:~/fp/files$ java Inside.java
dune.txt -> dune.txt
fiction/../emma.txt -> emma.txt
../orders.csv -> refused, outside the library: ../orders.csv
/etc/hostname -> refused, outside the library: /etc/hostname
as strings: true
as paths:   false
```

`fiction/../emma.txt` came back in, so it was accepted; `../orders.csv` left, so it was refused. The
fourth is the case people forget: **`resolve` with an absolute path ignores the base entirely** and
returns the other path, so `/etc/hostname` came through as itself and only the check stopped it.

The last two lines are why the check is `Path.startsWith` and not `String.startsWith`. A folder named
`library-old` begins with the letters `library`, and a check on the text accepted it. `Path.startsWith`
compares whole names, `library` against `library-old`, and refused it.

One thing `normalize` cannot see is a symbolic link: it reads names, not the disk, so a link inside the
folder that points outside it passes the check. Where the folder may contain links, check
`toRealPath()`, which asks the disk where the path really leads, and reject the name if the real path is
outside.
