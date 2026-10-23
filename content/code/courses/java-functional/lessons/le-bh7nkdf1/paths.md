---
title: A Path is a name
version: 1
---

**`java.nio.file` is the newer door to the file system, and it starts with `Path`: the name of a file or
a directory, and nothing more.** Building a `Path` does not open anything and does not check that
anything exists. It is a sequence of names joined by the system's separator, with methods to take it
apart and put it together:

```java
// Names.java: a Path is a name, and nothing here touches the disk but one line
import java.nio.file.Files;
import java.nio.file.Path;

public class Names {
    public static void main(String[] args) {
        Path dune = Path.of("library", "fiction", "dune.txt");
        System.out.println("path:      " + dune);
        System.out.println("file name: " + dune.getFileName());
        System.out.println("parent:    " + dune.getParent());
        System.out.println("names:     " + dune.getNameCount());
        System.out.println("exists:    " + Files.exists(dune));

        Path base = Path.of("library");
        Path odes = base.resolve("fiction/../poetry/./odes.txt");
        System.out.println("resolved:  " + odes);
        System.out.println("normal:    " + odes.normalize());
        System.out.println("relative:  " + base.relativize(dune));
        System.out.println("absolute:  " + dune.toAbsolutePath());
    }
}
```

```
ana@vm:~/fp/files$ java Names.java
path:      library/fiction/dune.txt
file name: dune.txt
parent:    library/fiction
names:     3
exists:    false
resolved:  library/fiction/../poetry/./odes.txt
normal:    library/poetry/odes.txt
relative:  fiction/dune.txt
absolute:  /home/ana/fp/files/library/fiction/dune.txt
```

## Taking it apart, putting it together

`Path.of("library", "fiction", "dune.txt")` joined three names into `library/fiction/dune.txt`, with the
separator of the system it ran on, so the same line gives `library\fiction\dune.txt` on Windows. **The
path was built, printed and taken apart, and the one line that asked the disk said the file does not
exist.** Nothing failed before that line, and nothing would have: a `Path` to a file that is not there
is a perfectly good `Path`.

| method | answers | touches the disk? |
|---|---|---|
| `getFileName()` | the last name, `dune.txt` | no |
| `getParent()` | everything before it | no |
| `resolve(other)` | this path with `other` joined after it | no |
| `normalize()` | the same path with `.` and `name/..` removed | no |
| `relativize(other)` | the steps from this path to `other` | no |
| `toAbsolutePath()` | the path from the root, using the working directory | no |
| `Files.exists(path)` | whether something is there now | yes |

`resolve` joined the text as it was given, dots included, and **`normalize` tidied it by reading the
names, not the disk**: `fiction/..` cancels out whether or not `fiction` exists. `toAbsolutePath` asked
the program for its working directory, `/home/ana/fp/files`, and still did not look for the file.
Everything that does look at the disk is a static method of `Files`, which is the next section.

`Path` replaces `java.io.File`, the class from Java 1.0. `File` is still in old code and old APIs, and
the two convert with `file.toPath()` and `path.toFile()`. New code starts with `Path`, because the
methods that use it report a failure with an exception that names it, where `File` often answered
`false` and said nothing more.
