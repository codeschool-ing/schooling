---
title: A runtime with only what the program needs
version: 1
---

Modules gave the JDK a second use that has nothing to do with walls. **Once every piece of the JDK is a
module that says what it requires, a tool can work out exactly which pieces a program needs**, and
build a Java runtime with those and nothing else. That tool is `jlink`, and it only works for a program
that is itself made of modules.

## The JDK is sixty-nine modules

```
ana@vm:~/modules$ java --list-modules | wc -l
69
ana@vm:~/modules$ java --list-modules | head -5
java.base@25.0.4.1
java.compiler@25.0.4.1
java.datatransfer@25.0.4.1
java.desktop@25.0.4.1
java.instrument@25.0.4.1
ana@vm:~/modules$ jdeps --module-path out -s -m com.example.app
com.example.app -> com.example.library
com.example.app -> java.base
```

The installed JDK carries 69 modules, each listed with its version. `java.base` is the one everything
needs; `java.desktop` is windows and graphics, `java.sql` is databases, `java.compiler` is `javac`'s
own interface. A program uses a handful of them.

`jdeps`, from lesson 1's table, reads compiled classes and reports what they depend on. With `-s` it
gives one line per dependency between modules: the app needs the library and `java.base`, and that is
all. **Nothing guessed it**: `jdeps` read the bytecode and the `requires` lines.

## Linking a runtime

```
ana@vm:~/modules$ jlink --module-path out --add-modules com.example.app --output image
ana@vm:~/modules$ image/bin/java --list-modules
com.example.app
com.example.library
java.base@25.0.4.1
ana@vm:~/modules$ image/bin/java -m com.example.app/com.example.app.Main
Effective Java
ana@vm:~/modules$ du -sh image /usr/lib/jvm/java-25-openjdk-amd64
60M	image
331M	/usr/lib/jvm/java-25-openjdk-amd64
```

`jlink` started from the app module, followed every `requires` down to `java.base`, and wrote a
directory, `image`, holding a `bin/java` that knows three modules. **It runs the program on its own**,
with no JDK installed beside it, and it is 60 MB against the 331 MB of the JDK it came from.

That is what `jlink` is for: shipping a program with its own runtime inside, in a container image or
an installer, without the compiler, the tools and the fifty-odd modules it never loads. Of the 60 MB,
the two modules of this lesson are the five class files `find` listed in section 02; the rest is the
JVM and `java.base`.

Two limits, both real. **`jlink` refuses a program that is not modular**, because it needs the
`requires` lines to know where to stop; a class-path application gets a smaller runtime only by naming
the JDK modules by hand with `--add-modules`, after asking `jdeps` which ones. And the image is built
for one operating system and processor: this one runs on Linux on x86-64, and a Mac needs its own,
linked from a Mac JDK.
