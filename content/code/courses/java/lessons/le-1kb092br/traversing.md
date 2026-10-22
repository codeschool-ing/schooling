---
title: Walking an array, and the tools in `Arrays`
version: 1
---

Most work on an array visits every element once. Java has two loops for it, and **which one to use
depends on whether you need the position or only the value**. Lesson 11 takes loops apart properly;
here they appear as the two shapes an array asks for:

```java
// Traversing.java
import java.util.Arrays;

public class Traversing {
    public static void main(String[] args) {
        int[] stock = {4, 0, 7, 2, 9};

        int total = 0;
        for (int i = 0; i < stock.length; i++) {
            total += stock[i];
        }
        System.out.println("total " + total);

        int most = stock[0];
        for (int n : stock) {
            most = Math.max(most, n);
        }
        System.out.println("most " + most);

        int[] sorted = Arrays.copyOf(stock, stock.length);
        Arrays.sort(sorted);
        System.out.println(Arrays.toString(sorted) + " " + Arrays.toString(stock));
        System.out.println(Arrays.binarySearch(sorted, 2));
        System.out.println(Arrays.binarySearch(stock, 2));

        int[] alias = stock;
        alias[0] = 100;
        System.out.println(stock[0]);

        int[] copy = Arrays.copyOf(stock, stock.length);
        System.out.println((copy == stock) + " " + Arrays.equals(copy, stock));
        Arrays.fill(copy, 1);
        System.out.println(Arrays.toString(copy));
        System.out.println(Arrays.toString(Arrays.copyOf(stock, 7)));
    }
}
```

```
ana@vm:~/arrays$ java Traversing.java
total 22
most 9
[0, 2, 4, 7, 9] [4, 0, 7, 2, 9]
1
-1
100
false true
[1, 1, 1, 1, 1]
[100, 0, 7, 2, 9, 0, 0]
```

## Two loops

The first loop counts `i` from 0 while it stays below `stock.length`, and reads `stock[i]` each
time: it has the position and could write to it. **The second, `for (int n : stock)`, hands over
each value in turn and no position at all.** It cannot go out of bounds and cannot get the
`<` wrong, which makes it the right choice whenever the position does not matter, as with the
largest value, `most 9`.

## The `Arrays` class

| call | printed | |
|---|---|---|
| `Arrays.copyOf(stock, stock.length)` | a new array | a copy, so sorting it left `stock` alone |
| `Arrays.sort(sorted)` | `[0, 2, 4, 7, 9]` | sorts in place, smallest first |
| `Arrays.binarySearch(sorted, 2)` | `1` | the position of 2 in the sorted copy |
| `Arrays.binarySearch(stock, 2)` | `-1` | **a wrong answer: `stock` is not sorted**, and 2 is right there at index 3 |
| `Arrays.equals(copy, stock)` | `true` | same length, same elements in the same order |
| `Arrays.fill(copy, 1)` | `[1, 1, 1, 1, 1]` | every place set to one value |
| `Arrays.copyOf(stock, 7)` | two extra zeros | a longer copy is padded with the default |

`binarySearch` halves the range on every step, which makes it fast on a large array and **only
correct on a sorted one**. On an unsorted array it does not fail, it answers, and the answer is a
negative number meaning "not here". Nothing warns you.

## A second variable is not a second array

`int[] alias = stock;` did not copy anything. It made a second variable that refers to **the same
array**, so `alias[0] = 100` changed what `stock[0]` printed. `copyOf` makes a real copy, and the two
comparisons on it show the difference between the operators: `copy == stock` asks whether they are
the same array and said `false`; `Arrays.equals` compares the contents and said `true`. It is
lesson 7's `==` against `equals` for strings, met again, and lesson 30 is about why it is so.
