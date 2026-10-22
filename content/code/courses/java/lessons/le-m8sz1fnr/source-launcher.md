---
title: Running a source file directly
version: 1
---

Two commands for a program you change every minute is one too many, and since Java 11 `java` can
take a `.java` file instead of a class name. **It compiles the file in memory, runs it, and writes
nothing to disk.** This is the source-file mode, and many of the programs before lesson 18 run this
way, because those lessons are about the program and not about where its classes go.

In a fresh directory, `~/launch`, with the same `Greet.java`:

```
ana@vm:~/launch$ java Greet.java Ana
Hello, Ana
ana@vm:~/launch$ ls
Greet.java
```

The program ran, and `ls` shows no `Greet.class`. The compiled class lived in the JVM's memory and
went when the process ended. What `java` does here is the two steps of section 02 in one process:
it calls the compiler, which is itself written in Java and ships inside the JDK, and then runs the
result. **Nothing about the program changes**: the same `args`, the same exit status, the same
output. What changes is the cost of starting, which `time` measures:

```
ana@vm:~/launch$ time java Greet.java Ana
Hello, Ana

real	0m1.093s
user	0m0.785s
sys	0m0.120s
ana@vm:~/launch$ javac Greet.java && time java Greet Ana
Hello, Ana

real	0m0.206s
user	0m0.028s
sys	0m0.009s
```

1.093 seconds from source against 0.206 from a compiled class, on this machine and on this run; the
numbers move a little every time. **The difference is the compiler
starting up**, every time, which is nothing for a program you are editing and a real cost for one
that runs a thousand times a day.

## A program in several files

Until Java 22, source-file mode had one limit that mattered: everything had to be in that one file.
Now `java` compiles the other classes the program uses, as long as their files sit in the same
directory, named after their classes. Two small files make the point:

```java
// Main.java
public class Main {
    public static void main(String[] args) {
        System.out.println(Shout.loud("hello from two files"));
    }
}
```

```java
// Shout.java
public class Shout {
    static String loud(String text) {
        return text.toUpperCase() + "!";
    }
}
```

```
ana@vm:~/launch$ java Main.java
HELLO FROM TWO FILES!
ana@vm:~/launch$ ls
Greet.java
Main.java
Shout.java
```

`java Main.java` compiled `Main`, saw that it uses a class called `Shout`, found `Shout.java` beside
it, and compiled that too. **This works on 25 and not on 21**: Java 22 added it, and
on 21, which was not tried here, source-file mode compiles only the file you name and stops at
`Shout`. The file you name is the one whose `main` runs, and the others are found
by need. A file nobody uses is never compiled at all, even one that would not compile:

```
ana@vm:~/launch$ echo 'class Broken {' > Broken.java; java Main.java
HELLO FROM TWO FILES!
ana@vm:~/launch$ rm Broken.java
```

`Broken.java` is missing its closing brace, and `java Main.java` never looked at it.

## A Java program as a script

On Linux and macOS a text file can be made executable, and its first line, starting with `#!`, names
the program that should run it. `java` accepts such a file when it is told which release the source
is written for. One line builds one from `Greet.java`:

```
ana@vm:~/launch$ (echo '#!/usr/bin/java --source 25'; cat Greet.java) > greet
ana@vm:~/launch$ chmod +x greet && ./greet Ana
Hello, Ana
ana@vm:~/launch$ head -3 greet
#!/usr/bin/java --source 25
public class Greet {
    public static void main(String[] args) {
```

The file is called `greet`, with no `.java`, and **that is the rule rather than a matter of taste**.
`--source 25` is what tells `java` that this extensionless file is source code. A file ending in
`.java` is compiled as ordinary Java, and in ordinary Java `#` is not a character at all:

```
ana@vm:~/launch$ cp greet greet.java && java greet.java Ana
greet.java:1: error: illegal character: '#'
#!/usr/bin/java --source 25
^
greet.java:1: error: class, interface, annotation type, enum, record, method or field expected
#!/usr/bin/java --source 25
  ^
2 errors
error: compilation failed
```

A script like this is a fine tool for something you run by hand, and the wrong shape
for anything bigger, because every run compiles it again.

| you have | you type | compiles to disk |
|---|---|---|
| a class in `out` | `java -cp out Greet Ana` | already done, by `javac -d out` |
| one or more source files | `java Greet.java Ana` | nothing |
| an executable script | `./greet Ana` | nothing |
