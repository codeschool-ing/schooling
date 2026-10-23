---
title: Choosing, and two lists that refuse
version: 1
---

Both an array and an `ArrayList` are numbered slots in memory, so the choice is not about speed of
reading: `get(i)` and `array[i]` both go straight to a slot. **It is about whether the size is known
and fixed, and whether the elements are primitives.**

| use | when |
|---|---|
| an array, `int[]`, `double[]` | the size is fixed when it is created and the elements are primitives: the twelve months of a year, the pixels of an image, a million readings from a sensor |
| an `ArrayList` | everything else: the size changes, or it is not known in advance, or the elements are objects that other code will pass around as a `List` |

The primitive case matters because of section 02's boxing. An `int[]` of a million readings is one
object holding four million bytes of numbers. A `List<Integer>` of the same readings is a list
holding a million references to a million `Integer` objects, each with a header of its own. Code that
moves a lot of numbers keeps them in arrays.

Everything else leans the other way. **Methods in the standard library and in most code you will call
take and return `List`, not arrays**, a list can grow, and it prints itself. Lesson 32 compares
`ArrayList` with the other kinds of `List`, `Set` and `Map`.

## Two lists that look ordinary

Two methods build a `List` quickly, and neither builds an `ArrayList` you can grow. In
`~/lists/views`:

```java
// Views.java
import java.util.Arrays;
import java.util.List;

public class Views {
    public static void main(String[] args) {
        String[] shelf = {"Dom Casmurro", "Iracema"};
        List<String> view = Arrays.asList(shelf);
        view.set(0, "O Cortiço");
        System.out.println(Arrays.toString(shelf));

        List<String> fixed = List.of("Dom Casmurro", "Iracema");
        try {
            fixed.set(0, "O Cortiço");
        } catch (UnsupportedOperationException e) {
            System.out.println("List.of refused set: " + e);
        }

        view.add("Memórias Póstumas");
    }
}
```

```
ana@vm:~/lists/views$ javac Views.java && java Views
[O Cortiço, Iracema]
List.of refused set: java.lang.UnsupportedOperationException
Exception in thread "main" java.lang.UnsupportedOperationException
	at java.base/java.util.AbstractList.add(AbstractList.java:155)
	at java.base/java.util.AbstractList.add(AbstractList.java:113)
	at Views.main(Views.java:19)
```

**`Arrays.asList` does not copy the array; it wraps it.** `view.set(0, …)` wrote through to `shelf`,
and the array printed *O Cortiço* although nobody touched it directly. The list is a view of the
array, so it can change elements and can never change size: `view.add` failed at the last line with
`UnsupportedOperationException`, because an array cannot grow.

**`List.of` builds a list that cannot be changed at all.** Not its size, not its elements: `set` was
refused as well as `add` would be. It is what lesson 29's `List.copyOf` returns too, and it is the
right thing to hand out when callers should read and not write.

Both look like any other `List`, and the type does not say which methods will work. That is a
weakness of the `List` interface, which has methods for changing a list whether or not a particular
list allows it. **When a method needs a list it can add to, it makes one**: `new
ArrayList<>(List.of(...))`, as section 02's `pages` did, gives an ordinary growing list with those
elements in it.
