---
title: When none of them fits
version: 1
---

**None of the 43 interfaces may throw a checked exception**, and that is the most common reason to
write your own. Reading a file is the plain case. `Files.readString` declares `throws IOException`,
and `Function.apply` declares nothing:

```java
// Checked.java: a Function whose body can throw IOException
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.function.Function;

public class Checked {
    public static void main(String[] args) {
        Function<Path, String> read = p -> Files.readString(p);
        System.out.println(read.apply(Path.of("notes.txt")));
    }
}
```

```
ana@vm:~/fp/interfaces$ javac -d out Checked.java
Checked.java:8: error: unreported exception IOException; must be caught or declared to be thrown
        Function<Path, String> read = p -> Files.readString(p);
                                                           ^
1 error
```

**A lambda's body is the method it implements**, so it obeys that method's `throws` clause, and
`apply` has none. The checked exception has nowhere to go: it cannot escape `apply`, and `main`'s
own `throws` clause would not help, because the body does not run inside `main`. It runs whenever
somebody calls `apply`, which could be anywhere.

## An interface that says it can fail

The fix is an interface whose one method declares the exception:

```schooling-example
{
  "language": "java",
  "file": "OwnInterface.java",
  "parts": [
    {
      "code": "// OwnInterface.java: a function that is allowed to fail with IOException\nimport java.io.IOException;\nimport java.io.UncheckedIOException;\nimport java.nio.file.Files;\nimport java.nio.file.Path;\nimport java.util.function.Function;\n\n@FunctionalInterface\ninterface IOFunction<T, R> {\n    R apply(T t) throws IOException;",
      "note": "The same shape as `Function<T, R>`, with one difference: `apply` may throw `IOException`, so a lambda whose body throws it now compiles."
    },
    {
      "code": "\n    static <T, R> Function<T, R> unchecked(IOFunction<T, R> f) {\n        return t -> {\n            try {\n                return f.apply(t);\n            } catch (IOException e) {\n                throw new UncheckedIOException(e);\n            }\n        };\n    }\n}",
      "note": "A bridge back to the standard `Function`, for an API that only accepts that. The checked exception is wrapped in `UncheckedIOException`, which keeps the original as its cause rather than losing it."
    },
    {
      "code": "\npublic class OwnInterface {\n    public static void main(String[] args) throws IOException {\n        IOFunction<Path, String> read = p -> Files.readString(p);\n        System.out.print(read.apply(Path.of(\"notes.txt\")));",
      "note": "Called directly, the exception stays checked, and `main` declares it. This is the honest version: the compiler still makes somebody decide what a missing file means."
    },
    {
      "code": "\n        Function<Path, String> lenient = IOFunction.unchecked(read);\n        try {\n            lenient.apply(Path.of(\"missing.txt\"));\n        } catch (UncheckedIOException e) {\n            System.out.println(\"failed: \" + e.getCause());\n        }\n    }\n}\n",
      "note": "Through the bridge, the failure arrives as an unchecked exception and is caught here. The message came from the original `IOException`, kept as the cause."
    }
  ]
}
```

Make the file it reads first, then run it:

```
ana@vm:~/fp/interfaces$ printf 'Lumen opens at nine on weekdays.\n' > notes.txt
ana@vm:~/fp/interfaces$ java OwnInterface.java
Lumen opens at nine on weekdays.
failed: java.nio.file.NoSuchFileException: missing.txt
```

**Wrapping is not hiding.** The second call failed, and the program said so, with the name of the
file and the exception the JDK raised. What would be wrong is a bridge that caught the
`IOException` and returned `null` or an empty string, so that a missing file read as an empty one;
lesson 10 shows what `null` costs further down the line.

## When to write one

| situation | use |
|---|---|
| the shape is in `java.util.function` and nothing throws | the standard interface |
| the body throws a checked exception you want callers to handle | your own, with `throws` |
| the shape fits, but a name would say more, as `PriceRule` did | your own, with `@FunctionalInterface` |
| more than two inputs | a record that groups them, or your own interface |

A name is not decoration. `PriceRule` in a method signature tells the reader what the lambda is
for; `Function<Long, Long>` only tells them its types.
