---
title: Standard in, out and error
version: 1
---

**Every program starts with three streams already open: standard input, standard output and standard
error.** Java names them `System.in`, an `InputStream`, and `System.out` and `System.err`, two
`PrintStream`s. The shell decides where they lead: the keyboard and the terminal by default, or a file,
or another program, which is how a Java program takes its place in a pipeline of commands.

```java
// WordCount.java: count the lines and words that arrive on standard input
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

public class WordCount {
    public static void main(String[] args) throws IOException {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
        long lines = 0;
        long words = 0;
        String line;
        while ((line = in.readLine()) != null) {
            lines++;
            String trimmed = line.strip();
            if (!trimmed.isEmpty()) {
                words += trimmed.split("\\s+").length;
            }
        }
        System.out.println(lines + " lines, " + words + " words");
        if (lines == 0) {
            System.err.println("warning: nothing arrived on standard input");
        }
    }
}
```

```
ana@vm:~/fp/io$ java WordCount.java < shelf.txt
3 lines, 4 words
ana@vm:~/fp/io$ printf 'the hobbit\nthere and back again\n' | java WordCount.java
2 lines, 6 words
ana@vm:~/fp/io$ java WordCount.java < /dev/null
0 lines, 0 words
warning: nothing arrived on standard input
ana@vm:~/fp/io$ java WordCount.java < /dev/null 2> errors.txt
0 lines, 0 words
ana@vm:~/fp/io$ cat errors.txt
warning: nothing arrived on standard input
```

## Reading the four runs

The first reads `shelf.txt`, the file `Layers.java` wrote in section 03, through `<`, which makes the file
the program's standard input. The second takes the output of `printf` through a pipe, `|`, as if the two
programs were one. **The program does not know or care where its input came from**, which is what lets
it be combined with any other.

The last two send nothing, from `/dev/null`, the file that is always empty. The count goes to standard
output and the warning to standard error, and `2> errors.txt` sends standard error to a file, so the
warning left the terminal and went where it was told. **Results on standard output, complaints on
standard error**: a script that pipes the output to another program then never feeds it a warning
message by mistake.

`System.in` is not closed by the program, deliberately: it belongs to the process, not to `main`, and
closing it would stop anything else in the program from reading it.
