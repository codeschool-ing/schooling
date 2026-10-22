---
title: A swap that does nothing
version: 1
---

One question sits under a whole family of Java bugs, the ones where a method changed something it
should not have, or failed to change something it should. **When you call a method and hand it a variable, what does
the method receive?** There are two possible answers in programming languages generally. *By
value*: the method gets a copy of what the variable holds, and nothing it does to its copy can reach
your variable. *By reference*: the method gets your variable itself, and assigning to its parameter
assigns to yours.

**Java has exactly one of the two, for everything: by value.** This section shows it with numbers,
where nobody doubts it. Section 03 shows it with objects, where most people do.

The classic test is a method that swaps its two arguments. In a language that passes by reference
it works; in one that passes by value it cannot. In `~/byvalue`:

```java
// Swap.java
public class Swap {
    static void swap(int a, int b) {
        int t = a;
        a = b;
        b = t;
        System.out.println("inside swap: a=" + a + " b=" + b);
    }

    static void addOne(int n) {
        n = n + 1;
    }

    public static void main(String[] args) {
        int x = 1;
        int y = 2;
        swap(x, y);
        System.out.println("after swap:  x=" + x + " y=" + y);
        addOne(x);
        System.out.println("after addOne: x=" + x);
    }
}
```

```
ana@vm:~/byvalue$ javac Swap.java && java Swap
inside swap: a=2 b=1
after swap:  x=1 y=2
after addOne: x=1
```

**Inside `swap`, the two values changed places. Outside, nothing happened.** `x` is still 1 and `y`
still 2, and `addOne(x)` left `x` at 1 as well. `swap` had two variables of its own, `a` and `b`,
which started life as copies of `x` and `y`, and everything it did, it did to its copies. When it
returned, its copies were thrown away with it.

## Where the copies live

Lesson 5 said that a method's local variables live in its **frame**, created when the method is
called and discarded when it returns. **Parameters are local variables of the method**, filled in by
the caller. The bytecode shows the handover. First `main`, as far as the call:

```
ana@vm:~/byvalue$ javap -c Swap | sed -n 32,40p
  public static void main(java.lang.String[]);
    Code:
         0: iconst_1
         1: istore_1
         2: iconst_2
         3: istore_2
         4: iload_1
         5: iload_2
         6: invokestatic  #23                 // Method swap:(II)V
```

`istore_1` and `istore_2` put 1 and 2 into `main`'s local slots 1 and 2, which are `x` and `y`
(slot 0 is `args`). Then **`iload_1` and `iload_2` push the two values**, not the variables, and
`invokestatic` calls `swap` with them. Inside `swap`:

```
ana@vm:~/byvalue$ javap -c Swap | sed -n 9,16p
  static void swap(int, int);
    Code:
         0: iload_0
         1: istore_2
         2: iload_1
         3: istore_0
         4: iload_2
         5: istore_1
```

`swap`'s parameters are **its own** slots 0 and 1, and its `t` is slot 2. The six instructions shuffle
values between those three slots and touch nothing else. No JVM instruction lets `swap` reach
`main`'s slot 1: **a method can read and write its own frame and nobody else's.** That is pass by value, as the machine does it.

Nobody is surprised by this with an `int`. What surprises people is that **objects follow exactly
the same rule**, and the next section is the reason it does not look that way.
