---
title: The object that walks a collection
version: 1
---

Lessons 32 and 33 put elements into collections, and every one of them came out again through a
`for-each` loop or a `toString`. Neither of those reads the collection itself. **Both ask the
collection for an `Iterator`**, a small object whose only job is to hand over the elements one at a
time, and the loop talks to that object. Seeing it directly explains the error in section 03, and
the cure in section 04.

## Two methods and a promise

An `Iterator<E>` has two methods that matter. `hasNext()` answers whether there is another element,
and `next()` returns it and moves on. Every list and set in lesson 32 has an `iterator()` method that
makes a fresh one, positioned before the first element; a map has none of its own and lends one
through `keySet()`, `values()` or `entrySet()`. Save this in a new directory, `~/iter`:

```java
// Walk.java
import java.util.Iterator;
import java.util.List;

public class Walk {
    public static void main(String[] args) {
        List<String> shelf = List.of("Dune", "Emma", "Ulysses");

        Iterator<String> it = shelf.iterator();
        while (it.hasNext()) {
            String title = it.next();
            System.out.println("next     " + title);
        }
        System.out.println("hasNext  " + it.hasNext());
        it.next();
    }
}
```

```
ana@vm:~/iter$ java Walk.java
next     Dune
next     Emma
next     Ulysses
hasNext  false
Exception in thread "main" java.util.NoSuchElementException
	at java.base/java.util.ImmutableCollections$ListItr.next(ImmutableCollections.java:401)
	at Walk.main(Walk.java:15)
```

The `while` loop is the whole protocol: ask, take, repeat. Once the last title was taken, `hasNext`
answered `false`, and calling `next()` anyway threw `NoSuchElementException`. **The iterator keeps
its own position, and nothing resets it**; to walk the shelf again, ask the list for a new iterator.

Notice where the exception came from: `ImmutableCollections$ListItr.next`. That is the class of the
iterator `List.of` made, a class nobody imports by name. **Each collection supplies its own iterator
class**, written for its own structure, and that is how one loop syntax walks an array-backed list,
a chain of nodes and a hash table alike.

## What a `for-each` loop compiles to

The common belief is that `for-each` is a feature the JVM understands. It is not; `javac` rewrites
it into the loop above. This file uses one, and `javap -c` shows what the compiler made of it:

```java
// Shelf.java
import java.util.List;

public class Shelf {
    static int letters(List<String> titles) {
        int n = 0;
        for (String t : titles) {
            n += t.length();
        }
        return n;
    }

    public static void main(String[] args) {
        System.out.println(letters(List.of("Dune", "Emma", "Ulysses")));
    }
}
```

```
ana@vm:~/iter$ javac Shelf.java && java Shelf
15
ana@vm:~/iter$ javap -c Shelf | grep -E "invoke(interface|virtual)"
         3: invokeinterface #7,  1            // InterfaceMethod java/util/List.iterator:()Ljava/util/Iterator;
        10: invokeinterface #13,  1           // InterfaceMethod java/util/Iterator.hasNext:()Z
        19: invokeinterface #19,  1           // InterfaceMethod java/util/Iterator.next:()Ljava/lang/Object;
        30: invokevirtual #25                 // Method java/lang/String.length:()I
        15: invokevirtual #51                 // Method java/io/PrintStream.println:(I)V
```

**Three interface calls: `List.iterator`, then `Iterator.hasNext` and `Iterator.next`**, at bytecode
offsets 3, 10 and 19 of `letters`. The fourth line is the call to `length` in the loop's body, and
the last one belongs to `main`. There is no instruction for "for each" anywhere: the JVM saw
lesson 1's ordinary calls.

That rewriting is also the rule for which loops compile. **A `for-each` works on an array or on
anything that implements `Iterable`**, the interface with the one method `iterator()`. Every list and
set from lesson 32 implements it, and a class of yours can too, which is how a `for (Loan l : member)`
loop could be made to work.
