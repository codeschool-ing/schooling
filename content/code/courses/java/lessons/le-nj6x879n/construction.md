---
title: What `new` does, step by step
version: 1
---

`new Loan("Effective Java")` reads as "call the constructor", and the constructor is the last of
three things that happen. **By the time the first line of a constructor runs, the object already
exists, every field has a value, and some of them have their final one.** A constructor finishes an
object; it does not create it.

Make a directory for this lesson, `~/lifecycle`, and save this in it. The constructor prints the
fields before it touches them:

```java
// Loan.java
public class Loan {
    private String title;
    private int days = 14;
    private boolean returned;

    Loan(String title) {
        System.out.println("constructor starts: title=" + this.title + " days=" + days + " returned=" + returned);
        this.title = title;
        System.out.println("constructor ends:   title=" + this.title);
    }

    public static void main(String[] args) {
        Loan loan = new Loan("Effective Java");
        System.out.println(loan.title + " for " + loan.days + " days");
    }
}
```

```
ana@vm:~/lifecycle$ javac Loan.java && java Loan
constructor starts: title=null days=14 returned=false
constructor ends:   title=Effective Java
Effective Java for 14 days
ana@vm:~/lifecycle$ javap -c Loan | grep -A6 "static void main"
  public static void main(java.lang.String[]);
    Code:
         0: new           #8                  // class Loan
         3: dup
         4: ldc           #40                 // String Effective Java
         6: invokespecial #42                 // Method "<init>":(Ljava/lang/String;)V
         9: astore_1
```

Read the first line of output: **`title=null days=14 returned=false`**, printed before the
constructor assigned anything. Three different stories in one line:

1. **The memory came first, zeroed.** The JVM reserved room for a `Loan` on the heap and set every
   field to its type's zero: `null` for a reference, `0` for a number, `false` for a `boolean`. That
   is where `returned` got its `false`, and why `title` was still `null`. Lesson 5 called these the
   default values of fields.
2. **Then the field initialisers ran.** `days = 14` is written on the field's declaration, and it
   had already happened when the constructor started.
3. **Then the constructor body ran**, and set `title`.

The bytecode shows the same order from the caller's side. `new` is an instruction of its own, which
allocates and zeroes; the constructor is a method called `<init>`, run on the result with
`invokespecial`. The `dup` between them keeps a second copy of the new reference, because the
constructor call consumes one and `astore_1` needs the other to store it in `loan`.

**There is no way to get the object between `new` and `<init>`**, which is what makes a constructor
a safe place to establish the rules an object keeps for life. Lesson 27 adds the remaining pieces of
the order, initialiser blocks and parent classes, and the one trap in it: a constructor that calls a
method a subclass has overridden.
