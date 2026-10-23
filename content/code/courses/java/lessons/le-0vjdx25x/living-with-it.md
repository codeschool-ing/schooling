---
title: Return what you mean to return
version: 1
---

Knowing the rule is half of it. The other half is writing methods so that nobody has to think about
it when they call one. **Two habits cover most cases: a method that produces something returns it,
and a method that changes its argument says so in its name.** Both are visible in one program, in
`~/byvalue/living`:

```java
// Returning.java
import java.util.Arrays;

record MinMax(int min, int max) {
}

public class Returning {
    static MinMax minMax(int[] values) {
        int min = values[0];
        int max = values[0];
        for (int v : values) {
            min = Math.min(min, v);
            max = Math.max(max, v);
        }
        return new MinMax(min, max);
    }

    static int[] sortedCopy(int[] values) {
        int[] copy = values.clone();
        Arrays.sort(copy);
        return copy;
    }

    static void sortInPlace(int[] values) {
        Arrays.sort(values);
    }

    public static void main(String[] args) {
        int[] pages = {256, 640, 180};
        System.out.println(minMax(pages));

        int[] sorted = sortedCopy(pages);
        System.out.println(Arrays.toString(sorted) + " " + Arrays.toString(pages));

        sortInPlace(pages);
        System.out.println(Arrays.toString(pages));
    }
}
```

```
ana@vm:~/byvalue/living$ javac Returning.java && java Returning
MinMax[min=180, max=640]
[180, 256, 640] [256, 640, 180]
[180, 256, 640]
```

**Two results, one return value.** A Java method returns one value, so a method that finds a minimum
and a maximum cannot hand them back through two parameters, as a language with pass by reference
might. It returns one object holding both. Lesson 29's record is the right shape for that: `MinMax`
is one line, and the caller reads `min()` and `max()` from it. The swap that section 02 could not
write becomes possible in the same way: a method that takes two values and returns a record with them
the other way round.

**Two ways to sort, named for what they do.** `sortedCopy` clones the array, sorts the clone and
returns it, and the second line shows `pages` untouched, `[256, 640, 180]`, beside the sorted copy.
`sortInPlace` sorts the caller's own array through the reference, and the third line shows `pages`
changed. Neither is wrong. What would be wrong is a method called `sorted` that quietly changed its
argument, because the caller has no way to tell from the call. The standard library follows the same
naming: `Arrays.sort` changes the array it is given, and `List.copyOf` from lesson 29 returns a new
list.

## A parameter you do not mean to reassign

Reassigning a parameter is legal, and it is the move behind every surprise in section 04: the
author thought the assignment would reach the caller. **Marking a parameter `final` makes the
compiler refuse the assignment**, which turns that mistake into an error at the line where it is
made:

```java
// Guard.java
public class Guard {
    static void replace(final StringBuilder b) {
        b.append("!");
        b = new StringBuilder("other");
    }
}
```

```
ana@vm:~/byvalue/living$ javac Guard.java
Guard.java:5: error: final parameter b may not be assigned
        b = new StringBuilder("other");
        ^
1 error
```

`b.append("!")` compiled: `final` stops the parameter being re-pointed, and says nothing about the
object it points at, as lesson 16 showed for every `final` reference. The second line was refused,
by name. Some teams put `final` on every parameter for this reason, and others find it noise and
rely on a code-review rule instead. Either way, **a method that reassigns its own parameter is
something a reader has to look at twice**, and a local variable with its own name is clearer.
