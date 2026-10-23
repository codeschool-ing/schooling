---
title: A module and the file that declares it
version: 1
---

Lesson 14 gave a class four levels of access, and the widest, `public`, meant **anybody, anywhere**.
For a single program that was enough. For a library it is a problem: a library is several packages,
its own classes need to call each other across them, so those classes have to be `public`, and then
every program that uses the library can call them too. Nothing in the language said "public to my own
packages, and private to everybody else". Java 9 added a level above the package to say exactly that:
the **module**, a named group of packages that declares which of them the rest of the world may see.

## Two modules, one file each

A module is a directory with a `module-info.java` at its root. This library has two packages, one
meant for callers and one for itself, and its declaration exports only the first:

```java
// src/com.example.library/module-info.java
module com.example.library {
    exports com.example.library.api;
}
```

```java
// src/com.example.library/com/example/library/api/Catalogue.java
package com.example.library.api;

import com.example.library.internal.Index;

public class Catalogue {
    private final Index index = new Index();

    public String titleOf(String isbn) {
        return index.lookup(isbn);
    }
}
```

```java
// src/com.example.library/com/example/library/internal/Index.java
package com.example.library.internal;

import java.util.Map;

public class Index {
    private final Map<String, String> titles = Map.of(
            "978-0-13-468599-1", "Effective Java",
            "978-0-596-00920-5", "Java Concurrency in Practice");

    public String lookup(String isbn) {
        return titles.getOrDefault(isbn, "unknown");
    }
}
```

`Index` is `public`, because `Catalogue` is in another package and has to use it. **Before modules,
that made it part of the library's interface whether its author liked it or not.** Now the module
decides: `exports com.example.library.api` and nothing else.

The program that uses it is a second module, which says what it needs with `requires`:

```java
// src/com.example.app/module-info.java
module com.example.app {
    requires com.example.library;
}
```

```java
// src/com.example.app/com/example/app/Main.java
package com.example.app;

import com.example.library.api.Catalogue;

public class Main {
    public static void main(String[] args) {
        Catalogue catalogue = new Catalogue();
        System.out.println(catalogue.titleOf("978-0-13-468599-1"));
    }
}
```

Five files, under a `src` directory with one directory per module, named after it:

```
ana@vm:~/modules$ find src -name "*.java" | sort
src/com.example.app/com/example/app/Main.java
src/com.example.app/module-info.java
src/com.example.library/com/example/library/api/Catalogue.java
src/com.example.library/com/example/library/internal/Index.java
src/com.example.library/module-info.java
```

## Compiling and running on the module path

`javac` compiles both modules in one go when it is told where their sources are, with
`--module-source-path`, and which modules to build, with `-m`. `java` then runs a class **in a module**,
named as `module/class`, finding the modules on the **module path** rather than the class path:

```
ana@vm:~/modules$ javac -d out --module-source-path src -m com.example.library,com.example.app
ana@vm:~/modules$ find out -name "*.class" | sort
out/com.example.app/com/example/app/Main.class
out/com.example.app/module-info.class
out/com.example.library/com/example/library/api/Catalogue.class
out/com.example.library/com/example/library/internal/Index.class
out/com.example.library/module-info.class
ana@vm:~/modules$ java --module-path out -m com.example.app/com.example.app.Main
Effective Java
```

The compiler wrote one directory per module, each with its own `module-info.class`. The module
declaration is compiled like any class, and the JVM reads it to know what each module exports and
requires.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Two modules. com.example.app requires com.example.library. The library exports its package com.example.library.api, which Main may use. Its package com.example.library.internal is not exported, so code in the app module cannot reach it, at compile time or by reflection.\"><defs><marker id=\"jv40-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">com.example.app</text><text x=\"170\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">requires com.example.library</text><rect x=\"40\" y=\"80\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">com.example.app.Main</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">com.example.library</text><text x=\"550\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">exports com.example.library.api</text><rect x=\"420\" y=\"80\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">com.example.library.api</text><rect x=\"420\" y=\"150\" width=\"260\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"550\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">com.example.library.internal</text><text x=\"550\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">public classes, not exported</text><path d=\"M300 100 H418\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv40-a)\"></path><text x=\"359\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">may use</text><path d=\"M170 120 V180 H360\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">x</text><text x=\"250\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused</text><text x=\"360\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">public is no longer enough: a class is reachable when it is public and its package is exported</text></svg>", "caption": "A module says which of its packages other modules may see. Everything else is inside the wall, public or not."}
```

## What the module refuses

`Shortcut` skips the API and uses `Index` directly, which on the class path would have been perfectly
legal:

```java
// src/com.example.app/com/example/app/Shortcut.java
package com.example.app;

import com.example.library.internal.Index;

public class Shortcut {
    public static void main(String[] args) {
        System.out.println(new Index().lookup("978-0-13-468599-1"));
    }
}
```

```
ana@vm:~/modules$ javac -d out --module-source-path src -m com.example.library,com.example.app
src/com.example.app/com/example/app/Shortcut.java:4: error: package com.example.library.internal does not exist
import com.example.library.internal.Index;
                                   ^
src/com.example.app/com/example/app/Shortcut.java:8: error: cannot find symbol
        System.out.println(new Index().lookup("978-0-13-468599-1"));
                               ^
  symbol:   class Index
  location: class Shortcut
2 errors
ana@vm:~/modules$ rm src/com.example.app/com/example/app/Shortcut.java
```

**To the app module the package does not exist.** It is there, on disk, compiled a moment earlier, and
`javac` answers as if it were not, because an unexported package is not part of what the library
offers. Remove the file again; it has made its point.

## A module in a jar

A module is shipped as a jar like any library, with `module-info.class` at its root. `jar` can read the
declaration back out:

```
ana@vm:~/modules$ mkdir -p lib && jar --create --file lib/library.jar -C out/com.example.library .
ana@vm:~/modules$ jar --describe-module --file lib/library.jar
com.example.library jar:file:///home/ana/modules/lib/library.jar!/module-info.class
exports com.example.library.api
requires java.base mandated
contains com.example.library.internal

```

`exports` and `contains` are the two halves: one package anybody may use and one that is the library's
own. `requires java.base mandated` is a line nobody wrote. **Every module depends on `java.base`**,
where `String`, `Object` and the collections live, so it is added to every declaration whether or not
the file says so.

The same file goes in a Maven project too, as `src/main/java/module-info.java`, and Maven then compiles
the project as a module. Lesson 18's `library` project has none, and section 05 says why that is the
usual state of things.
