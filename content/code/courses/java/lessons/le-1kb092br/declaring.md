---
title: An array is a row of boxes of one type
version: 1
---

An array holds a fixed number of values of one type, side by side, each reached by its position.
**Its length is decided when it is created and never changes afterwards**: there is no adding a
sixth element to an array of five. Lesson 31 shows the list that grows; this lesson is the
structure underneath it. Make a directory for this lesson, `~/arrays`, and save this as
`Declaring.java`:

```java
// Declaring.java
import java.util.Arrays;

public class Declaring {
    public static void main(String[] args) {
        int[] copies = new int[5];
        String[] titles = new String[3];
        double[] fines = new double[2];
        boolean[] lent = new boolean[2];
        System.out.println(Arrays.toString(copies));
        System.out.println(Arrays.toString(titles));
        System.out.println(Arrays.toString(fines) + " " + Arrays.toString(lent));

        int[] years = {1899, 1881, 1943};
        System.out.println(years.length);
        System.out.println(years[0] + " " + years[years.length - 1]);
        System.out.println(years);

        years[1] = 1880;
        System.out.println(Arrays.toString(years));
        System.out.println(years[3]);
    }
}
```

```
ana@vm:~/arrays$ java Declaring.java
[0, 0, 0, 0, 0]
[null, null, null]
[0.0, 0.0] [false, false]
3
1899 1943
[I@25b485ba
[1899, 1880, 1943]
Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: Index 3 out of bounds for length 3
	at Declaring.main(Declaring.java:21)
```

`int[] copies` declares a variable that can hold an array of `int`s, and `new int[5]` creates one
with five places. **A new array is never empty in the sense of holding nothing**: every place
starts at its type's default, `0` for numbers, `false` for `boolean`, and `null`, meaning no object
at all, for a `String` or any other class. The second form, `{1899, 1881, 1943}`, creates the array
and fills it in one go, and the compiler counts the length for you.

## Positions start at 0

`years[0]` is the first element and `years[years.length - 1]` the last, which printed `1899 1943`.
`length` is a field and not a method, so it takes no brackets, unlike a `String`'s `length()` in
lesson 7. Assigning to `years[1]` replaced 1881 with 1880 in place.

Then `years[3]` asked for a fourth element of a three-element array, and the program stopped:
`ArrayIndexOutOfBoundsException: Index 3 out of bounds for length 3`, at line 21. **Java checks every
index on every access**, so a wrong one is an exception at the line that made the mistake, not a read
of whatever memory happened to lie past the end, as it would be in C.

## Printing an array

`System.out.println(years)` printed `[I@25b485ba`, which is not a bug but is no use to a reader. An
array is an object, and an object printed without a method of its own to describe it shows its
type's code name, `[I` for an array of `int`, then `@` and a number derived from its identity. **That
number differs on every run**, and yours will not match. `Arrays.toString` is the method that prints
the elements, and the `java.util.Arrays` class it belongs to is where the other array tools of the
next section live.
