---
title: Trying a line, and the shortest program Java allows
version: 1
---

A class, a `main` and a file are a lot of ceremony for finding out what `7 / 2` is. The JDK has two
answers to that, and they are for different moments. **`jshell` runs Java one line at a time**, for
questions you can ask in a line. **A compact source file** is a whole program without the class
around it, which Java 25 allows and Java 21 does not.

## `jshell`

Type `jshell` and you get a `jshell>` prompt. Each line you type is compiled and run on the spot, and
`jshell` answers with the value it produced. To make this transcript exact, the lines were saved in a
file first and given to `jshell` on its input, which prints the same answers without echoing what
was typed. Typed by hand, each line appears after its `jshell>`:

```
ana@vm:~/syntax$ cat try.jsh
int pages = 7 / 2
pages * 3.0
String name = "Ana"
name.length()
name.toUpperCase()
/vars
/exit
ana@vm:~/syntax$ jshell --feedback normal < try.jsh
|  Welcome to JShell -- Version 25.0.4.1
|  For an introduction type: /help intro

jshell> pages ==> 3

jshell> $2 ==> 9.0

jshell> name ==> "Ana"

jshell> $4 ==> 3

jshell> $5 ==> "ANA"

jshell> |    int pages = 3
|    double $2 = 9.0
|    String name = "Ana"
|    int $4 = 3
|    String $5 = "ANA"

jshell> |  Goodbye
```

Each line got an answer of the form `name ==> value`:

- `int pages = 7 / 2` declared a variable, and its value is **3, not 3.5**: dividing one whole number
  by another gives a whole number in Java, and lesson 6 shows why.
- `pages * 3.0` was an expression with no variable to keep it, so `jshell` invented one, `$2`, and
  its value is `9.0` because `3.0` is a decimal number.
- `name.length()` and `name.toUpperCase()` called methods on a `String`, which lesson 7 is about.
- `/vars` is a `jshell` command, not Java. Commands start with `/`, and this one lists every variable
  with its type. `/exit` leaves, and `/help` lists the rest.

Two things `jshell` forgives that a `.java` file does not: **a statement needs no semicolon**, and
nothing has to be inside a class. That makes it the right place to check what an expression does
before you put it in a program, and the wrong place to write the program.

## Compact source files

Java 25 lets a source file contain a method without declaring a class around it:

```java
// Hi.java
void main() {
    IO.println("Hello from a compact source file");
}
```

```
ana@vm:~/syntax$ java Hi.java
Hello from a compact source file
ana@vm:~/syntax$ javac Hi.java && javap Hi.class
Compiled from "Hi.java"
final class Hi {
  Hi();
  void main();
}
ana@vm:~/syntax$ javac --release 21 Hi.java
Hi.java:2: error: implicitly declared classes are not supported in -source 21
void main() {
^
  (use -source 25 or higher to enable implicitly declared classes)
1 error
```

Three things are different from `Hello.java`, and `javap` shows where the class went. **The compiler
declared one for you**, named after the file, `final class Hi`, so the rule from section 03 still
holds in a new form. `main` may now drop `public`, `static` and its parameter. And `IO.println` is a
shorter way to print, from a class `IO` that Java 25 added for exactly this kind of file.

The last command shows the other half of the story. Compiled for Java 21, the same file is refused:
**compact source files are new in Java 25**, and the message says which release to ask for.

This course writes its programs the long way, with the class, `public static void main(String[]
args)` and `System.out.println`, from here to lesson 40. That is not nostalgia. Every Java codebase
you will be paid to read is written that way, every library documents itself that way, and the
`java-functional` and `java-back` courses after this one build classes that other classes use, where
the compact form does not apply. Use compact files for scripts and experiments, and know the long
form by heart.
