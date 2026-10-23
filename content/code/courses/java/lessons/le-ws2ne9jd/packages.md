---
title: Packages, a name with directories in it
version: 1
---

Every class until now lived in the **default package**, the nameless one a file belongs to when it
says nothing. That is fine for one directory of programs, and nobody ships code that way. A real
program has hundreds of classes, uses thousands more from libraries, and two of them called `Book`
or `Date` is a certainty. **A package gives a class a full name**, and that name is also the
directory where its class file has to be.

## The `package` line

Make a directory for this lesson, `~/pkgs`, with a `src` directory in it, and two files under that:

```java
// src/com/example/library/Book.java
package com.example.library;

public class Book {
    private final String title;

    public Book(String title) {
        this.title = title;
    }

    public String title() {
        return title;
    }
}
```

```java
// src/com/example/library/app/Main.java
package com.example.library.app;

import com.example.library.Book;

public class Main {
    public static void main(String[] args) {
        Book book = new Book("Effective Java");
        System.out.println(book.title());
    }
}
```

**The first line of each file names its package**, and nothing but comments may come before it.
`Book` is in `com.example.library`, so its full name, its **fully qualified name**, is
`com.example.library.Book`. `Main` is in a different package, `com.example.library.app`, and to use
`Book` by its short name it imports it, which section 03 is about.

The name is a domain written backwards. Whoever owns `example.com` may use every package under
`com.example`, and nobody else may, so two companies cannot pick the same name by accident. The
domain `example.com` is reserved for documentation, which is why this course uses it. **Package
names are all lower case**, and the course's own layout, which section 04 fixes, puts every class
of a project called `library` under `com.example.library`.

## Where the class files go

`javac -d out` compiles into a directory called `out` instead of beside the source, and builds the
package's directories for you:

```
ana@vm:~/pkgs$ javac -d out src/com/example/library/Book.java src/com/example/library/app/Main.java
ana@vm:~/pkgs$ find out -type f
out/com/example/library/app/Main.class
out/com/example/library/Book.class
ana@vm:~/pkgs$ java -cp out com.example.library.app.Main
Effective Java
```

Two things to read in that. **The package became directories**: `com.example.library.app.Main`
is the file `out/com/example/library/app/Main.class`, one directory for each part of the name. And
**`java` was given the full name**, and with `-cp out`, short for `--class-path`, the directory
where the package tree starts.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The class name com.example.library.app.Main, split at its dots into com, example, library, app and Main, above the file out/com/example/library/app/Main.class, split into the same pieces. Each piece of the name lines up with one directory, and the directory out, the class path root given with -cp out, comes first.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">class name</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">file on disk</text><rect x=\"110\" y=\"128\" width=\"70\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">out/</text><text x=\"145\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">class path</text><text x=\"145\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">root, -cp out</text><rect x=\"190\" y=\"28\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">com</text><rect x=\"190\" y=\"128\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">com/</text><path d=\"M220.0 72 V126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"262\" y=\"28\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"307.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">example</text><rect x=\"262\" y=\"128\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"307.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">example/</text><path d=\"M307.0 72 V126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"364\" y=\"28\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"409.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">library</text><rect x=\"364\" y=\"128\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"409.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">library/</text><path d=\"M409.0 72 V126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"466\" y=\"28\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"496.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app</text><rect x=\"466\" y=\"128\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"496.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app/</text><path d=\"M496.0 72 V126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"538\" y=\"28\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"598.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Main</text><rect x=\"538\" y=\"128\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"598.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Main.class</text><path d=\"M598.0 72 V126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"455\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each dot in the name is a directory under the root</text></svg>", "caption": "The JVM turns a class name into a path by replacing each dot with a slash, then looks for that path under every class path root. The package is the directories; the root is not part of it."}
```

The **class path** is the list of places the JVM looks for classes, and a class's name says where
to look under each of them. Ask for the short name, or start from the wrong directory, and the two
failures are different:

```
ana@vm:~/pkgs$ java -cp out Main
Error: Could not find or load main class Main
Caused by: java.lang.ClassNotFoundException: Main
ana@vm:~/pkgs$ cd out/com/example/library/app && java Main
Error: Could not find or load main class Main
Caused by: java.lang.NoClassDefFoundError: Main (wrong name: com/example/library/app/Main)
```

**`ClassNotFoundException: Main`**: there is no `out/Main.class`, because no class is called just
`Main`. The second failure is the more instructive one. Standing in the directory that holds
`Main.class`, `java Main` found the file and opened it, and the file said its name was
`com/example/library/app/Main`, which is not the name it was asked for: **`wrong name`**. A class
file knows its package, and it is only valid at the path that package spells.

## Source files follow the same rule

`javac` does not insist that a source file sits in its package's directory when you name the file on
the command line. It does when it has to **find** one. With `-sourcepath src`, `javac` compiles the
file it was given, and goes looking under `src` for any class that file uses:

```
ana@vm:~/pkgs$ rm -rf out && javac -d out -sourcepath src src/com/example/library/app/Main.java && find out -type f
out/com/example/library/app/Main.class
out/com/example/library/Book.class
ana@vm:~/pkgs$ mv src/com/example/library/Book.java src/Book.java
ana@vm:~/pkgs$ rm -rf out && javac -d out -sourcepath src src/com/example/library/app/Main.java
src/com/example/library/app/Main.java:4: error: cannot find symbol
import com.example.library.Book;
                          ^
  symbol:   class Book
  location: package com.example.library
src/com/example/library/app/Main.java:8: error: cannot find symbol
        Book book = new Book("Effective Java");
        ^
  symbol:   class Book
  location: class Main
src/com/example/library/app/Main.java:8: error: cannot find symbol
        Book book = new Book("Effective Java");
                        ^
  symbol:   class Book
  location: class Main
3 errors
ana@vm:~/pkgs$ mv src/Book.java src/com/example/library/Book.java
```

The first compile was given `Main.java` alone and found `Book.java` by itself, at
`src/com/example/library/Book.java`. Then Ana moved `Book.java` to the top of `src`, and the same
command failed with **`cannot find symbol`** three times: `javac` looked for `Book` exactly where its
name said, and it was not there. The last line put it back.

That is the whole contract. **The package says where the file must be, and every tool, `javac`,
`java`, Maven and your editor, looks there and nowhere else.** Keep the two in step and none of these
errors can happen.
