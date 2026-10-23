---
title: Arrays of arrays
version: 1
---

Java has no two-dimensional array in the sense of a grid of cells in one block. **An `int[][]` is
an array whose elements are themselves arrays**, each a separate object with its own length. Most
of the time that difference is invisible, and twice in this section it is not:

```java
// Grid.java
import java.util.Arrays;

public class Grid {
    public static void main(String[] args) {
        int[][] grid = new int[3][4];
        grid[1][2] = 5;
        System.out.println(Arrays.deepToString(grid));
        System.out.println(grid.length + " " + grid[0].length);

        int[][] shelves = {{1, 2, 3}, {4}, {5, 6}};
        for (int[] shelf : shelves) {
            System.out.println(shelf.length + " " + Arrays.toString(shelf));
        }

        int total = 0;
        for (int[] shelf : shelves) {
            for (int n : shelf) {
                total += n;
            }
        }
        System.out.println("total " + total);

        int[][] jagged = new int[2][];
        System.out.println(Arrays.toString(jagged));
        jagged[0] = new int[3];
        System.out.println(Arrays.deepToString(jagged));
        System.out.println(jagged[1].length);
    }
}
```

```
ana@vm:~/arrays$ java Grid.java
[[0, 0, 0, 0], [0, 0, 5, 0], [0, 0, 0, 0]]
3 4
3 [1, 2, 3]
1 [4]
2 [5, 6]
total 21
[null, null]
[[0, 0, 0], null]
Exception in thread "main" java.lang.NullPointerException: Cannot read the array length because "<local4>[1]" is null
	at Grid.main(Grid.java:28)
```

`new int[3][4]` built an outer array of three elements and three inner arrays of four, so
`grid[1][2]` is row 1, column 2, and `deepToString` printed the rows inside one pair of brackets.
`grid.length` is the number of rows, 3, and `grid[0].length` the length of the first row, 4.

## Rows need not match

The literal `{{1, 2, 3}, {4}, {5, 6}}` built three rows of three different lengths, which is
perfectly legal and is called a **jagged** array. The two nested `for` loops walked it without
caring: the inner one asks each row for its own values, and the total came to 21.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"How a two-dimensional array is laid out. The variable shelves points at an outer array of three elements. Each element is a reference to a separate int array: the first holds 1, 2 and 3, the second holds 4, the third holds 5 and 6, so the rows have lengths 3, 1 and 2. A row that was never created, like jagged[1], is null rather than an empty array.\"><defs><marker id=\"jv9-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"100\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"71\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelves</text><text x=\"71\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">int[][]</text><path d=\"M126 120 H178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv9-a)\"></path><text x=\"215\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the outer array</text><rect x=\"180\" y=\"54\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[0]</text><rect x=\"180\" y=\"98\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[1]</text><rect x=\"180\" y=\"142\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[2]</text><path d=\"M250 72 H318\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv9-a)\"></path><rect x=\"320\" y=\"57\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"338\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><rect x=\"360\" y=\"57\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text><rect x=\"400\" y=\"57\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"418\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text><text x=\"450\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">length 3</text><path d=\"M250 116 H318\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv9-a)\"></path><rect x=\"320\" y=\"101\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"338\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><text x=\"370\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">length 1</text><path d=\"M250 160 H318\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv9-a)\"></path><rect x=\"320\" y=\"145\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"338\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">5</text><rect x=\"360\" y=\"145\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><text x=\"410\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">length 2</text><text x=\"400\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">three separate int arrays</text><rect x=\"560\" y=\"100\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">jagged[1]</text><text x=\"615\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">null</text><text x=\"615\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a row never created:</text><text x=\"615\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no array at all</text><rect x=\"16\" y=\"206\" width=\"688\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">an int[][] is an array whose elements are references to int arrays, each with its own length</text></svg>", "caption": "The array shelves from the program above. Nothing makes the rows the same length; a rectangle like grid is only rows that happen to be."}
```

`new int[2][]` goes further and creates the outer array alone, with **its rows not yet created**.
They print as `null`, and `jagged[0] = new int[3]` made only the first. Reading
`jagged[1].length` then failed, because there was no array there to have a length:

```
ana@vm:~/arrays$ javac -g Grid.java && java Grid 2>&1 | tail -2
Exception in thread "main" java.lang.NullPointerException: Cannot read the array length because "jagged[1]" is null
	at Grid.main(Grid.java:28)
```

The message names the expression that was `null`, and how it names it depends on how the class was
compiled. **Run from source, or compiled with plain `javac`, it says `"<local4>[1]"`**: the fifth
local variable of the method, counting from 0 with `args` first, because the class file kept no
variable names. `javac -g` keeps them, and the same failure says `"jagged[1]"`. Lesson 12 meets this
message again, as the exception every Java programmer sees most.
