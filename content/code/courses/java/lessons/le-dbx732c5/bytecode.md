---
title: From source to bytecode
version: 1
---

The common picture of a compiler is a program that turns source code into the processor's own
instructions, the way a C compiler does. **Java's compiler does not do that.** `javac` turns source
into **bytecode**, the instruction set of a processor that exists only on paper, the Java Virtual
Machine. The `java` program is that machine, written in software, and it is what runs your
program. Every Java program you ever run goes through both steps.

Make a directory for this lesson, `~/jvm`, and save this file in it as `Hello.java`:

```java
// Hello.java
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, Java");
    }
}
```

Lesson 3 reads it line by line. For now it is enough that it prints one line, and that **the file
is named after the class it declares**, `Hello`.

## Two steps, two programs

```
ana@vm:~/jvm$ javac Hello.java
ana@vm:~/jvm$ ls -l
total 8
-rw-r--r-- 1 ana ana 415 Oct 16 19:31 Hello.class
-rw-r--r-- 1 ana ana 131 Oct 16 19:31 Hello.java
ana@vm:~/jvm$ java Hello
Hello, Java
```

`javac` printed nothing, and in Java that is what success looks like. It left a file beside the
source, `Hello.class`, 415 bytes against the source's 131. Then `java Hello` ran it. Notice what
`java` was given: **the name of a class, `Hello`, not the name of a file.** `java Hello.class` would
be asking for a class called `Hello.class`, which does not exist; lesson 2 shows that message and
the third way of running, straight from the source.

## What is inside a class file

The file is binary, and the system's `file` command recognises it by its first bytes:

```
ana@vm:~/jvm$ file Hello.class
Hello.class: compiled Java class data, version 69.0
ana@vm:~/jvm$ od -A d -t x1 -N 8 Hello.class
0000000 ca fe ba be 00 00 00 45
0000008
```

`od` printed the first eight bytes in hexadecimal. **Every class file ever written starts with
`ca fe ba be`**, a joke from the early 1990s that the format has carried ever since, and it is how
`file` knew. The last two bytes, `00 45`, are the **major version**: hexadecimal 45 is 69, and 69
means Java 25. Section 04 met that number in an error message, and section 06 changes it.

`javap`, the JDK's class file printer, shows the rest in a form a person can read. With `-c` it
prints the bytecode of each method:

```
ana@vm:~/jvm$ javap -c Hello
Compiled from "Hello.java"
public class Hello {
  public Hello();
    Code:
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return

  public static void main(java.lang.String[]);
    Code:
         0: getstatic     #7                  // Field java/lang/System.out:Ljava/io/PrintStream;
         3: ldc           #13                 // String Hello, Java
         5: invokevirtual #15                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
         8: return
}
```

Two methods, and the source declared one. The first, `public Hello()`, is a **constructor** the
compiler wrote because the class did not declare one; lesson 13 explains it. The second is `main`,
four instructions long. Read them top to bottom, as the JVM does:

1. `getstatic` fetches `System.out`, the object that writes to the terminal.
2. `ldc` loads the constant string `"Hello, Java"`.
3. `invokevirtual` calls `println` on the first with the second as its argument.
4. `return` ends the method, and with it the program.

**Nothing in there is an Intel or an ARM instruction.** The same 415 bytes run unchanged on Linux,
macOS and Windows, on any processor a JVM has been written for. That is the old slogan, *write once,
run anywhere*, and it holds for exactly this reason: what `javac` produces is for the virtual
machine, and only the virtual machine is different on each computer.

## What the JVM does with it

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"How a Java program runs. Hello.java, the source you write, goes into javac. javac writes Hello.class, bytecode that is the same file on every computer. The java command starts a JVM, which loads the class, interprets the bytecode at first, and compiles the methods that run often into machine code for this processor with its JIT compiler. Each operating system has its own JVM; the class file is shared.\"><defs><marker id=\"jv1-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"70\" width=\"150\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"91\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Hello.java</text><text x=\"91\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">source you write</text><text x=\"91\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">131 bytes of text</text><path d=\"M166 107 H222\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv1-a)\"></path><text x=\"194\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">javac</text><rect x=\"224\" y=\"70\" width=\"160\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"304\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Hello.class</text><text x=\"304\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bytecode, version 69</text><text x=\"304\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the same on every computer</text><path d=\"M384 107 H440\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv1-a)\"></path><text x=\"412\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">java</text><rect x=\"442\" y=\"20\" width=\"262\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the JVM, one process</text><rect x=\"462\" y=\"58\" width=\"222\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">loads and checks the class</text><rect x=\"462\" y=\"98\" width=\"222\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">interprets the bytecode at first</text><rect x=\"462\" y=\"138\" width=\"222\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">JIT: compiles hot methods</text><text x=\"573\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">machine code for this processor</text><path d=\"M573 88 V96 M573 128 V136\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"16\" y=\"226\" width=\"688\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one JVM per operating system and processor; one class file for all of them</text></svg>", "caption": "javac runs once, on your machine. The JVM runs every time, on whichever machine the class file lands on, and only the JVM differs between them."}
```

When `java Hello` starts, the JVM **loads** the class and **verifies** it, checking that the
bytecode cannot, for instance, jump into the middle of an instruction or read memory it was never
given. Then it runs `main` by **interpreting** the bytecode, one instruction at a time, which starts
quickly and runs slowly. While it interprets, it counts. A method called often enough is handed to
the **JIT compiler**, *just in time*, which turns that method's bytecode into the processor's own
instructions, and from then on those run instead.

That is why a Java program tends to get faster in its first seconds, and why a four-instruction
`main` never reaches the JIT at all: it runs once and the program ends. Lesson 2 watches the JVM do
this as a running process.
