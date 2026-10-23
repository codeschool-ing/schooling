---
title: Compiling into a directory, and running from one
version: 1
---

Lesson 1 compiled `Hello.java` and left `Hello.class` beside it. That works for one file and turns
into clutter by the third. **Real projects keep source and compiled classes apart**, and then `java`
has to be told where the classes are. That telling is the **class path**, and most "it compiles but
will not run" problems are a class path that points somewhere else.

This lesson's program takes the names it greets from the command line. Save it in a new directory,
`~/life`:

```schooling-example
{
  "language": "java",
  "file": "Greet.java",
  "parts": [
    {
      "code": "public class Greet {\n    public static void main(String[] args) {",
      "note": "**`args` holds the words typed after the class name**, one string each. `java -cp out Greet Ana Bruno` hands `main` an array of two."
    },
    {
      "code": "        if (args.length == 0) {\n            System.err.println(\"usage: java Greet NAME...\");\n            System.exit(2);\n        }",
      "note": "**With no names, it complains and stops.** `System.err` is the error stream, separate from normal output, and `System.exit(2)` ends the JVM with status 2, which the shell can read."
    },
    {
      "code": "        for (String name : args) {\n            System.out.println(\"Hello, \" + name);\n        }\n    }\n}",
      "note": "One line per name, on standard output. The `for` loop over an array is lesson 11's subject; here it reads as *for each name in args*."
    }
  ]
}
```

## `-d` for the classes, `-cp` for finding them

```
ana@vm:~/life$ javac -d out Greet.java
ana@vm:~/life$ ls; ls out
Greet.java
out
Greet.class
ana@vm:~/life$ java -cp out Greet Ana Bruno
Hello, Ana
Hello, Bruno
```

`javac -d out` wrote the class into `out`, creating the directory because it did not exist, and the
source directory kept only the source. `java -cp out Greet` reads in that order: **look for classes
in `out`, start the class called `Greet`, and pass it what follows**. `-cp` is short for
`-classpath`, and its value can name several directories and `.jar` files, separated by `:` on
Linux and macOS and by `;` on Windows. Lesson 18 puts a whole project on it.

## The number a program ends with

A program says two things when it finishes: what it printed, and a whole number called its **exit
status**. Zero means success and anything else means failure, by a convention far older than Java.
The shell keeps the last status in `$?`:

```
ana@vm:~/life$ java -cp out Greet; echo $?
usage: java Greet NAME...
2
ana@vm:~/life$ java -cp out Greet Ana > hello.txt; echo $?; cat hello.txt
0
Hello, Ana
```

With no names, `Greet` printed its usage line and ended with 2, the number it passed to
`System.exit`. With a name, `main` returned normally and the JVM ended with 0. The second line also
shows why `System.err` exists. **`>` redirected standard output into `hello.txt`**, and the error
stream would still have reached the screen: a usage message is not data, so it should not land in
the file somebody is collecting.

A program that never calls `System.exit` ends with 0 when `main` returns, and with 1 when an
exception escapes `main`, which lesson 36 shows. Scripts and build tools decide what to do next from
this number alone, so a Java program meant to be run by other programs should choose it on purpose.

## Three ways to ask for the wrong class

These three mistakes print the same first line, and the difference is in the name it quotes:

```
ana@vm:~/life$ java Greet Ana
Error: Could not find or load main class Greet
Caused by: java.lang.ClassNotFoundException: Greet
ana@vm:~/life$ java -cp out Greet.class
Error: Could not find or load main class Greet.class
Caused by: java.lang.ClassNotFoundException: Greet.class
ana@vm:~/life$ java -cp out greet Ana
Error: Could not find or load main class greet
Caused by: java.lang.ClassNotFoundException: greet
```

1. **No `-cp`.** The class path defaults to the current directory, and `Greet.class` is in `out`,
   not here. The name `Greet` is right and the place is wrong.
2. **`Greet.class`.** `java` takes a class name, and it read the dot as a package separator: it went
   looking for a class `class` inside a package `Greet`. The fix is to drop the extension.
3. **`greet`.** Class names are case-sensitive, even on a file system that is not, and no class is
   called `greet`.

So when you see `Could not find or load main class`, **compare the quoted name with the class's real
name first, and only then look at the class path**. If the name is exactly right, the class path is
wrong.
