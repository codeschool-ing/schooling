---
title: A list that grows
version: 1
---

Lesson 9's arrays are fixed at the size they are created with: `new String[3]` holds three titles,
today and forever. Most collections in a program do not know their size in advance. A member's loans,
the results of a search, the lines of a file: each grows as the program runs. **`ArrayList` is a list
that grows as you add to it**, and it is the collection most Java code reaches for first.

It lives in `java.util` and is used through the interface `List`, which lesson 32 compares with the
other kinds. In `~/lists`:

```java
// Lists.java
import java.util.ArrayList;
import java.util.List;

public class Lists {
    public static void main(String[] args) {
        List<String> titles = new ArrayList<>();
        titles.add("Dom Casmurro");
        titles.add("Iracema");
        titles.add(0, "O Cortiço");
        System.out.println(titles + ", size " + titles.size());
        System.out.println(titles.get(1));

        titles.set(1, "Memórias Póstumas");
        titles.remove("Iracema");
        System.out.println(titles + ", contains Iracema: " + titles.contains("Iracema"));

        List<Integer> pages = new ArrayList<>(List.of(10, 20, 30, 1));
        pages.remove(1);
        System.out.println(pages);
        pages.remove(Integer.valueOf(1));
        System.out.println(pages);

        System.out.println(titles.get(5));
    }
}
```

```
ana@vm:~/lists$ javac Lists.java && java Lists
[O Cortiço, Dom Casmurro, Iracema], size 3
Dom Casmurro
[O Cortiço, Memórias Póstumas], contains Iracema: false
[10, 30, 1]
[10, 30]
Exception in thread "main" java.lang.IndexOutOfBoundsException: Index 5 out of bounds for length 2
	at java.base/jdk.internal.util.Preconditions.outOfBounds(Preconditions.java:100)
	at java.base/jdk.internal.util.Preconditions.outOfBoundsCheckIndex(Preconditions.java:106)
	at java.base/jdk.internal.util.Preconditions.checkIndex(Preconditions.java:302)
	at java.base/java.util.Objects.checkIndex(Objects.java:365)
	at java.base/java.util.ArrayList.get(ArrayList.java:428)
	at Lists.main(Lists.java:24)
```

The everyday methods, as the output shows them:

| method | what it did here |
|---|---|
| `add(x)` | appended at the end |
| `add(0, x)` | inserted *O Cortiço* at index 0, moving the others along |
| `size()` | 3: how many elements there are, where an array has `length` |
| `get(i)` | the element at index `i`, counted from 0 like an array |
| `set(i, x)` | replaced the element at `i` |
| `remove(x)`, `contains(x)` | found the element with `equals` (lesson 24), and removed it or reported it |

A list prints itself readably, `[O Cortiço, Dom Casmurro, Iracema]`, where an array needs
`Arrays.toString` (lesson 9). **And a bad index is still an exception**: `get(5)` on a list of two
ended the program with `IndexOutOfBoundsException`, naming the index and the length, the same
refusal an array gives.

## The trap in a list of numbers

`List<Integer> pages` held `[10, 20, 30, 1]`, and `pages.remove(1)` removed **20**, not 1. `List` has
two methods called `remove`: `remove(int index)` and `remove(Object o)`. Given the literal `1`, an
`int`, the compiler picks the one whose parameter is already an `int`, the index, without boxing it
first. Lesson 24 called that rule overloading, and here it bites: the code reads like "remove the
number 1" and means "remove whatever sits at index 1".

**`pages.remove(Integer.valueOf(1))` passes an object**, so the compiler picks `remove(Object)`, and
the second line shows the 1 gone. With a `List<String>` the question never arises, because a string
cannot be mistaken for an index. With a list of `Integer`, write which one you mean.

## Lists hold objects

A `List<int>` does not compile; the type argument has to be a class. `List<Integer>` holds `Integer`
objects, and `pages.add(5)` boxes the 5 into one, as lesson 4 described. For a few thousand numbers
that costs nothing worth measuring. For millions it costs memory, because each number becomes an
object with a header of its own, where an `int[]` stores four bytes per number side by side. Section
04 comes back to that when choosing.
