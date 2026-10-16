---
title: When the setup fails
version: 1
---

**Each message below was produced on purpose on the machine this course was recorded on, and each
one names exactly what is wrong once you know where to look.** They are in the order you would meet
them: the package, the version, then the first files. This section is for the moment something
does not work, so it shows each message before explaining it.

## `Unable to locate package openjdk-25-jdk`

`apt` answers with that line on an Ubuntu older than 24.04, whose archive stops at an earlier Java.
*This one was not run for the course, because the machine it was recorded on is 24.04.* The cure is
the system, not the package: `cat /etc/os-release` says which Ubuntu you have, and anything before
24.04 is a reason to take the virtual machine path from the previous section rather than to hunt
for Java 25 somewhere else.

## A class file version the runtime does not know

A machine that had Java 21 before this course has two JDKs side by side, and the commands do not
always come from the same one:

```
ana@vm:~/fp/lambdas$ javac -d out Hello.java
ana@vm:~/fp/lambdas$ ls /usr/lib/jvm
java-1.21.0-openjdk-amd64
java-1.25.0-openjdk-amd64
java-21-openjdk-amd64
java-25-openjdk-amd64
openjdk-21
openjdk-25
ana@vm:~/fp/lambdas$ /usr/lib/jvm/java-21-openjdk-amd64/bin/java -cp out Hello
Error: LinkageError occurred while loading main class Hello
	java.lang.UnsupportedClassVersionError: Hello has been compiled by a more recent version of the Java Runtime (class file version 69.0), this version of the Java Runtime only recognizes class file versions up to 65.0
```

The file was compiled by `javac` 25 and run by a `java` from the Java 21 folder. **Every release
stamps its class files with a number**: 65 is Java 21, 69 is Java 25, and a runtime refuses a number
newer than its own. The message says both numbers, which is the whole diagnosis. On Ubuntu,
`sudo update-alternatives --config java` lists the installed Java versions and lets you pick 25,
and the same command with `javac` does the compiler; `java -version` and `javac -version` should
then agree.

## Maven on the wrong Java

```
ana@vm:~/fp/lambdas$ JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 mvn -B -v
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 21.0.12.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-21-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.18.44-fc-v139", arch: "amd64", family: "unix"
```

**Maven does not use the `java` on your `PATH` when `JAVA_HOME` is set**; it uses the Java that
variable names. A guide for another project that told you to put `export JAVA_HOME=...` in
`~/.bashrc` leaves exactly this behind. The third line says it: Maven found 21. Delete that line
from `~/.bashrc`, or point it at `/usr/lib/jvm/java-25-openjdk-amd64`, open a new terminal and
check `mvn -B -v` again.

## `Could not find or load main class`

```
ana@vm:~/fp/lambdas$ java Helo.java
Error: Could not find or load main class Helo.java
Caused by: java.lang.ClassNotFoundException: Helo.java
```

The file is `Hello.java` and the command said `Helo.java`. When the name after `java` is not a file
that exists, **the launcher stops treating it as a file and tries it as the name of a compiled
class**, which is why the message is about a class and not about a missing file. `ls` shows what is
really in the folder.

## `should be declared in a file named`

The source-file mode is lenient about names, and `javac` is not. A copy of the first program saved
as `Greeting.java`:

```
ana@vm:~/fp/lambdas$ javac Greeting.java
Greeting.java:2: error: class Hello is public, should be declared in a file named Hello.java
public class Hello {
       ^
1 error
```

**A `public` class lives in a file of the same name**, and `javac` enforces it. The source-file
mode ran the same file without a word, because it compiles in memory and never writes a class file
whose name could disagree. Rename the file, or the class, before a project ever reaches Maven,
where every file goes through `javac`.

## `illegal character: '\u201c'`

A program pasted from a word processor or a chat window often carries typographic quotes, `“` and
`”`, where Java wants the plain `"`:

```java
// Quotes.java: a program pasted from a chat window
public class Quotes {
    public static void main(String[] args) {
        System.out.println(“Hello”);
    }
}
```

```
ana@vm:~/fp/lambdas$ java Quotes.java
Quotes.java:4: error: illegal character: '\u201c'
        System.out.println(“Hello”);
                           ^
Quotes.java:4: error: illegal character: '\u201d'
        System.out.println(“Hello”);
                                 ^
Quotes.java:4: error: not a statement
        System.out.println(“Hello”);
                            ^
3 errors
error: compilation failed
```

Three errors, and only the first is real: once the compiler rejected the two quotes, what was left
between them stopped being a string, and `not a statement` followed from that. **Fix the first
error a compiler reports and compile again** before reading the rest. Here, retype the quotes in
your editor.
