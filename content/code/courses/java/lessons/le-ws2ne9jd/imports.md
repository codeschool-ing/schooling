---
title: Imports, and the two `Date` classes
version: 1
---

**An import does not load anything, include anything or make a program bigger.** It is a promise to
the compiler about short names: when this file says `Book`, it means `com.example.library.Book`.
Every class can always be named in full, `java.util.List`, with no import at all. Imports exist so
that nobody has to, and the compiled class file holds the full names either way.

## The four kinds

| form | example | what it makes available |
|---|---|---|
| single-type | `import java.util.List;` | one class, by its short name |
| on-demand | `import java.util.*;` | every class of one package, when used |
| static | `import static java.lang.Math.max;` | a static member, called without its class |
| module | `import module java.base;` | every package a module exports, Java 25 only |

And one import nobody writes: **`java.lang` is imported into every file**. That is why `String`,
`System`, `Math` and `Integer` have needed no import in any lesson so far.

The `*` is not a wildcard over sub-packages. `import java.util.*;` brings in `java.util.List` and
does not bring in `java.util.concurrent.ExecutorService`: as far as the compiler is concerned
`java.util.concurrent` is a different package that happens to share the first part of its name.

## When two packages have the same name in them

`java.util` has a class called `Date`, and so does `java.sql`. A file that imports both packages on
demand and then says `Date` has asked for one of two classes:

```java
// src/com/example/library/app/Dates.java
package com.example.library.app;

import java.util.*;
import java.sql.*;

public class Dates {
    public static void main(String[] args) {
        Date start = new Date(0);
        System.out.println(start.getTime());
    }
}
```

```
ana@vm:~/pkgs$ javac -d out src/com/example/library/app/Dates.java
src/com/example/library/app/Dates.java:9: error: reference to Date is ambiguous
        Date start = new Date(0);
        ^
  both class java.sql.Date in java.sql and class java.util.Date in java.util match
src/com/example/library/app/Dates.java:9: error: reference to Date is ambiguous
        Date start = new Date(0);
                         ^
  both class java.sql.Date in java.sql and class java.util.Date in java.util match
2 errors
```

**`reference to Date is ambiguous`**, and the compiler names both candidates. It reported the error
twice because the line says `Date` twice, once for the variable's type and once after `new`. Nothing
in the program is wrong except the name. There are two fixes, and the first is the usual one: **a
single-type import beats an on-demand one**, so adding `import java.util.Date;` settles which `Date`
the file means. This version does that, and adds a static import:

```java
// src/com/example/library/app/Dates.java
package com.example.library.app;

import java.util.*;
import java.sql.*;
import java.util.Date;

import static java.lang.Math.max;

public class Dates {
    public static void main(String[] args) {
        Date start = new Date(0);
        System.out.println(start.getClass().getName() + " " + max(start.getTime(), 1));
    }
}
```

```
ana@vm:~/pkgs$ javac -d out src/com/example/library/app/Dates.java && java -cp out com.example.library.app.Dates
java.util.Date 1
```

The program printed the class it actually used, `java.util.Date`, and `max(...)` worked without
`Math.` in front of it because of `import static java.lang.Math.max;`. A static import is worth it
for a few names a file uses constantly; a file full of them leaves the reader asking where each name
came from. The second fix for the clash is to give up the short name and write the full one,
`java.sql.Date`, at the one place that needs it, which is what code that uses both does.

**Most editors write imports for you**, and they write single-type ones. You will read far more
imports than you type, so the skill is reading them: an import line says which `Date` this file
means, and that is the first place to look when a class does not behave the way its short name
suggests.

## Importing a whole module: new in Java 25

The JDK's library is split into **modules**, each a set of packages; lesson 40 is about them. Java 25
added a fourth kind of import that brings in every package a module exports in one line.
`java.base` is the module with the core of the library, `java.util`, `java.io`, `java.nio.file` and
the rest:

```java
// Modules.java
import module java.base;

public class Modules {
    public static void main(String[] args) {
        List<String> titles = List.of("Effective Java", "Head First Java");
        Map<String, Integer> editions = Map.of("Effective Java", 3);
        Path home = Path.of(System.getProperty("user.home"));
        System.out.println(titles.size() + " " + editions.get("Effective Java") + " " + home);
    }
}
```

```
ana@vm:~/pkgs$ java Modules.java
2 3 /home/ana
ana@vm:~/pkgs$ javac --release 21 -d /tmp/m21 Modules.java
Modules.java:2: error: module imports are not supported in -source 21
import module java.base;
       ^
  (use -source 25 or higher to enable module imports)
1 error
```

`List`, `Map` and `Path` live in three different packages, and one line covered all of them.
**It does not exist before Java 25**: compiled with `--release 21`, the same file fails with a
message that says so and names the release it needs. It is handy in short programs. In a project, single-type imports remain the norm, because they say exactly which class a
name means, and a module import of two modules that both export a `Date` is the ambiguity above, again.
