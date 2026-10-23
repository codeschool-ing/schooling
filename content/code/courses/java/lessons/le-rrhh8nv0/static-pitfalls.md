---
title: What goes wrong with static
version: 1
---

`static` is easy to add and hard to take away, because everything that touches a static member comes
to rely on there being exactly one. Three things go wrong often enough to be worth seeing once.

## Shared by mistake

A library with two branches wants to know how many books each has on loan:

```java
// Branch.java
class Branch {
    static int booksOnLoan = 0;
    String name;

    Branch(String name) {
        this.name = name;
    }

    void lend() {
        booksOnLoan = booksOnLoan + 1;
    }
}
```

```java
// Branches.java
public class Branches {
    public static void main(String[] args) {
        Branch centro = new Branch("Centro");
        Branch norte = new Branch("Norte");
        centro.lend();
        centro.lend();
        norte.lend();
        System.out.println(centro.name + ": " + centro.booksOnLoan);
        System.out.println(norte.name + ": " + norte.booksOnLoan);
    }
}
```

```
ana@vm:~/static$ javac Branches.java && java Branches
Centro: 3
Norte: 3
```

Centro lent two and Norte one, and both say 3. **One word, `static`, turned a count per branch into
a count for the library**, and nothing failed: the numbers are plausible and wrong. Reading the field
through `centro.` and `norte.` hid it, which is the habit section 02 warned against; `Branch.booksOnLoan`
would have looked like what it is. Removing `static` gives each branch its own count.

Static mutable state has a second cost that a small program cannot show. Everything in the program
shares it, so any code anywhere can change it, and a test of one class can leave a value behind that
changes the next test. Shared counters exist, and `Member.created` is a fair one, but **a static
field that changes is the first thing to suspect when two parts of a program disagree.**

## Constants, and the copy the compiler keeps

A value that never changes is the safe use of static: `static final`, one copy, unchangeable.
`final` is lesson 16, and here it is enough that the field cannot be assigned again. Constants are
named in capitals by convention, as lesson 3 said:

```java
// Limits.java
class Limits {
    static final int MAX_LOANS = 3;
}
```

```java
// LimitMain.java
public class LimitMain {
    public static void main(String[] args) {
        System.out.println("A member may borrow " + Limits.MAX_LOANS + " books");
    }
}
```

The library raises the limit to 5, and somebody edits `Limits.java` and compiles only that file:

```java
// Limits.java
class Limits {
    static final int MAX_LOANS = 5;
}
```

```
ana@vm:~/static$ javac LimitMain.java Limits.java && java LimitMain
A member may borrow 3 books
ana@vm:~/static$ javac Limits.java && java LimitMain
A member may borrow 3 books
ana@vm:~/static$ javap -c LimitMain | grep -A4 "main("
  public static void main(java.lang.String[]);
    Code:
         0: getstatic     #7                  // Field java/lang/System.out:Ljava/io/PrintStream;
         3: ldc           #15                 // String A member may borrow 3 books
         5: invokevirtual #17                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
ana@vm:~/static$ javac LimitMain.java Limits.java && java LimitMain
A member may borrow 5 books
```

`Limits.class` now says 5, and `LimitMain` still printed 3. `javap` shows why: `LimitMain` never
reads `Limits.MAX_LOANS` at all. **A `static final` field of a primitive or `String` type, given a
value the compiler can work out, is a compile-time constant.** `javac` copies its value into every
class that uses it. Here it went further and built the whole sentence at compile time, `3` included.
Only compiling `LimitMain` again picked up the 5. Maven, from lesson 18, recompiles what depends on a
changed file, which is one of the reasons projects are built by a tool rather than one `javac` at a
time.

## Static imports

`import static` lets a file use another class's static members without the class name:

```java
// Imports.java
import static java.lang.Math.PI;
import static java.lang.Math.max;

public class Imports {
    public static void main(String[] args) {
        System.out.println(max(3, 7));
        System.out.println(PI);
    }
}
```

```
ana@vm:~/static$ javac Imports.java && java Imports
7
3.141592653589793
```

It saves typing, and it costs the reader the one clue `Math.` gave about where `max` lives. Use it for
a few names that are read constantly and recognised at once, and spell the class out everywhere else.
