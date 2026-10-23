---
title: Reading and writing whole files
version: 1
---

**`Files` is a class of static methods that do the work, each taking a `Path`.** Writing a file, reading
it back and reading it line by line are one call each, and every one of them opens the file, does its
job and closes it before returning:

```java
// Catalogue.java: write a file, add a line to it, then read it back three ways
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.List;
import java.util.stream.Stream;

public class Catalogue {
    public static void main(String[] args) throws IOException {
        Path file = Path.of("catalogue.csv");
        Files.write(file, List.of(
                "Dune,Frank Herbert,1965,412",
                "Emma,Jane Austen,1815,474",
                "Dom Casmurro,Machado de Assis,1899,256"));
        Files.writeString(file, "Neuromancer,William Gibson,1984,271\n", StandardOpenOption.APPEND);
        System.out.println(Files.size(file) + " bytes");

        String all = Files.readString(file);
        System.out.println(all.lines().count() + " lines in one string");

        List<String> lines = Files.readAllLines(file);
        System.out.println("last: " + lines.getLast());

        try (Stream<String> stream = Files.lines(file)) {
            int pages = stream.map(line -> line.split(","))
                    .filter(fields -> Integer.parseInt(fields[2]) > 1900)
                    .mapToInt(fields -> Integer.parseInt(fields[3]))
                    .sum();
            System.out.println("pages after 1900: " + pages);
        }
    }
}
```

```
ana@vm:~/fp/files$ java Catalogue.java
129 bytes
4 lines in one string
last: Neuromancer,William Gibson,1984,271
pages after 1900: 683
```

## Three ways to read, and when each fits

`Files.write` took a list of lines and wrote each with a line break after it; `Files.writeString` took
one string. **With no options both replace the file**, creating it if it is missing, and
`StandardOpenOption.APPEND` made the second call add to the end instead. Both encode with UTF-8 unless
told otherwise, so lesson 19's rule about naming the encoding is already kept for you.

| call | gives | holds in memory |
|---|---|---|
| `Files.readString(path)` | the whole file as one `String` | all of it |
| `Files.readAllLines(path)` | a `List<String>`, one per line | all of it |
| `Files.lines(path)` | a `Stream<String>`, read as it is pulled | a buffer's worth |

The first two are the right call for a configuration file or a template, where all of it is needed and
it is small. **`Files.lines` is the one for a log of two gigabytes**: it reads lines only as the stream
pulls them, so the sum above would have needed about the same memory on a file a million times larger. This is
the source lesson 6 promised, and the pipeline on it is lesson 7's `map`, `filter` and `sum`. The two
books published after 1900 have 412 and 271 pages, and the sum was 683.

## A stream that holds a file must be closed

`Files.lines` is the one stream in this course that **must go in a `try` with resources**. A stream
built from a list holds nothing, but this one holds an open file, the descriptor of lesson 19 section 04,
until it is closed, and a terminal operation such as `sum` does not close it. `Files.list`, `Files.walk`
and `Files.find` in the next section are the same, for the same reason.

For files too large to read whole and not made of lines, `Files.newBufferedReader`,
`Files.newBufferedWriter`, `Files.newInputStream` and `Files.newOutputStream` give the streams of
lesson 19, already opened on the path.
