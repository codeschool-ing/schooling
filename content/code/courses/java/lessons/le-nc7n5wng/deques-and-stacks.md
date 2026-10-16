---
title: A deque, and the stack it replaces
version: 1
---

A **deque**, a *double-ended queue*, is open at both ends: you can add and remove at the head and at
the tail. That makes it a queue when you use one end for each job, and a **stack** when you use one
end for both, last in, first out, like a pile of returned books where you shelve the top one first.

Java has a class called `Stack`, and the common belief is that it is the one to use for a stack. It
is not, and the program below shows why. **The JDK's own documentation recommends `Deque` for
stacks**, and `ArrayDeque` is the class that implements it.

The example is an undo history, the textbook use of a stack: the last action is the first one
undone.

```java
// Undo.java
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Stack;

public class Undo {
    public static void main(String[] args) {
        Deque<String> undo = new ArrayDeque<>();
        undo.push("lend Dune");
        undo.push("lend Emma");
        undo.push("return Dune");
        System.out.println("deque  " + undo);
        System.out.println("pop    " + undo.pop());
        System.out.println("peek   " + undo.peek());

        Stack<String> old = new Stack<>();
        old.push("lend Dune");
        old.push("lend Emma");
        old.push("return Dune");
        System.out.println("stack  " + old);
        System.out.println("pop    " + old.pop());
        old.add(0, "slipped in at the bottom");
        System.out.println("get(0) " + old.get(0));
        System.out.println("stack  " + old);

        Deque<String> both = new ArrayDeque<>();
        both.offerLast("from the back");
        both.offerFirst("from the front");
        System.out.println("both   " + both + "  first " + both.peekFirst() + "  last " + both.peekLast());
    }
}
```

```
ana@vm:~/queues$ java Undo.java
deque  [return Dune, lend Emma, lend Dune]
pop    return Dune
peek   lend Emma
stack  [lend Dune, lend Emma, return Dune]
pop    return Dune
get(0) slipped in at the bottom
stack  [slipped in at the bottom, lend Dune, lend Emma]
both   [from the front, from the back]  first from the front  last from the back
```

## The deque as a stack

`push` puts an element at the head and `pop` takes it from the head, so the most recent action
comes out first: `pop` gave `return Dune`, and `peek` then showed `lend Emma`. **The deque prints
from the head**, newest first, which is the order the actions would be undone in.

The names are the stack's own, and each is another name for a deque method: `push` is `addFirst`,
`pop` is `removeFirst`, `peek` is `peekFirst`. Like the queue methods of section 02, `pop` throws on
an empty deque and `peek` answers `null`.

The last line used both ends at once: `offerLast` put an element at the tail and `offerFirst` one at
the head. A deque that does that is neither a queue nor a stack, and some problems want exactly
that, such as keeping the most recent hundred entries by adding at one end and dropping at the
other.

## What is wrong with `Stack`

`Stack` dates from Java 1.0, in 1996, before the collections framework existed, and it was built by
extending `Vector`, the list of that era. **A `Stack` is therefore a list**, and the program used
that against it:

- `old.add(0, "slipped in at the bottom")` put an element under the others, which no stack allows,
  and the compiler said nothing, because `add(int, E)` is a `Vector` method `Stack` inherited.
- `old.get(0)` read the bottom element directly, by position.
- The `Stack` printed bottom first, `[lend Dune, lend Emma, return Dune]`, the opposite of the
  deque, because it prints as the `Vector` it is.

That is lesson 20's warning about inheritance, shipped in the JDK: `Stack` is-a `Vector` in the
code and is not one in meaning, so every list operation is a way to break the stack. `Vector`'s
methods are also `synchronized`, which makes each call pay for locking whether or not two threads
ever touch the stack. The class stays for compatibility with code written in the 1990s.

**For a stack, declare a `Deque` and create an `ArrayDeque`.** A `Deque` still has `addLast`,
which a careful stack never calls, but it has no `get(i)` and no `add(i, e)` reaching into the
middle, and the class does no locking.
