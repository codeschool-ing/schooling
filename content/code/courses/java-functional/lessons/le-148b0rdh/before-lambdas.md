---
title: What a lambda replaces
version: 1
---

**A lambda is a way to hand a piece of behaviour to a method without writing a class around it.**
Before Java 8, released in 2014, the only way to give `sort` a rule for comparing two things was an
object whose class had a `compare` method, and the shortest way to write one was an anonymous class
(lesson 17 of `java`). Here is the same sort written both ways:

```java
// BeforeLambdas.java: one sort, written the way Java 7 wrote it and the way Java 8 does
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class BeforeLambdas {
    public static void main(String[] args) {
        List<String> titles = new ArrayList<>(List.of("Dune", "Emma", "Ulysses", "It", "Beloved"));
        titles.sort(new Comparator<String>() {
            @Override
            public int compare(String a, String b) {
                return Integer.compare(a.length(), b.length());
            }
        });
        System.out.println("anonymous class: " + titles);

        List<String> again = new ArrayList<>(List.of("Dune", "Emma", "Ulysses", "It", "Beloved"));
        again.sort((a, b) -> Integer.compare(a.length(), b.length()));
        System.out.println("lambda:          " + again);
    }
}
```

```
ana@vm:~/fp/lambdas$ java BeforeLambdas.java
anonymous class: [It, Dune, Emma, Ulysses, Beloved]
lambda:          [It, Dune, Emma, Ulysses, Beloved]
```

The two lines of output are identical, and so is the one line that decides the order:
`Integer.compare(a.length(), b.length())`. **Everything else in the anonymous class was
ceremony**: the `new`, the interface's name, the generic type, the `@Override`, the method's
signature and its braces. The lambda keeps the parameters, an arrow and the body. The compiler
works out the rest from the place the lambda is written, because `sort` wants a `Comparator<String>`
and that interface has exactly one method to implement. Lesson 2 gives that kind of interface its
name.

Read the output for one more thing: `Dune` and `Emma` have the same length and stayed in the order
they were given. `List.sort` is **stable**, so elements that compare as equal keep their places.

## Not a shorter anonymous class

It is tempting to read the arrow as a shorthand the compiler expands back into an anonymous class.
The class files say otherwise:

```
ana@vm:~/fp/lambdas$ javac -d out BeforeLambdas.java
ana@vm:~/fp/lambdas$ ls out
BeforeLambdas$1.class
BeforeLambdas.class
ana@vm:~/fp/lambdas$ javap -p out/BeforeLambdas.class
Compiled from "BeforeLambdas.java"
public class BeforeLambdas {
  public BeforeLambdas();
  public static void main(java.lang.String[]);
  private static int lambda$main$0(java.lang.String, java.lang.String);
}
ana@vm:~/fp/lambdas$ javap -c -p out/BeforeLambdas.class | grep invokedynamic
        41: invokedynamic #47,  0             // InvokeDynamic #0:makeConcatWithConstants:(Ljava/lang/String;)Ljava/lang/String;
        71: invokedynamic #57,  0             // InvokeDynamic #1:compare:()Ljava/util/Comparator;
        88: invokedynamic #61,  0             // InvokeDynamic #2:makeConcatWithConstants:(Ljava/lang/String;)Ljava/lang/String;
```

**The anonymous class became a file of its own, `BeforeLambdas$1.class`. The lambda did not.**
`javap` lists what is inside the class, and the lambda's body is there as a private static method
the compiler named `lambda$main$0`. Where the lambda is used, the bytecode says `invokedynamic`: an
instruction that asks the JVM, the first time it runs, to build an object implementing `Comparator`
around that method. That is the middle one of the three, the one that says
`compare:()Ljava/util/Comparator;`. The other two are the two `+` that join strings in the
`println` lines, which the compiler has also turned into `invokedynamic` since Java 9: the
instruction is a general way to let the JVM decide how to build something, and lambdas were its
first big customer.

Three consequences follow, and the rest of this lesson and the next are about them:

- **a lambda is an object of an interface type**, built at run time, so it can be stored in a
  variable, passed and returned like any other object;
- **it has no identity of its own you should depend on**: no class name you chose, no fields, and
  no meaningful `this` of its own, which section 06 shows;
- **it costs less than an anonymous class**: no extra file to load, and a lambda that uses nothing
  from around it is built once and reused.

## What it replaced, in practice

Anonymous classes were everywhere a library wanted behaviour: a `Comparator` for sorting, a
`Runnable` for a thread, a listener for a button. Each of those is still there, with the same
interfaces, and each now takes a lambda. Nothing was removed from the language to make room; what
changed is that **passing a rule became as short as passing a value**, and APIs were then written
to take rules everywhere. The Stream API of lessons 6 to 9 is the largest of them, and it would be
unreadable with anonymous classes.
