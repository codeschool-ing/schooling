---
title: `break`, `continue` and labels
version: 1
---

Two statements change a loop's course from inside its body. **`break` leaves the loop at once.
`continue` skips the rest of this pass and goes on with the next.** Each acts on the innermost loop
around it, and that innermost loop is exactly where nested searches go wrong:

```java
// Search.java
public class Search {
    public static void main(String[] args) {
        int[] years = {1899, 1881, 1928, 1943};
        for (int y : years) {
            if (y < 1900) {
                continue;
            }
            System.out.println("20th century: " + y);
        }

        String[][] shelves = {
            {"Iracema", "O Guarani"},
            {"Dom Casmurro", "Quincas Borba"},
            {"Macunaíma"}
        };
        String wanted = "Dom Casmurro";

        for (int s = 0; s < shelves.length; s++) {
            for (int p = 0; p < shelves[s].length; p++) {
                if (shelves[s][p].equals(wanted)) {
                    System.out.println("break: found at " + s + "/" + p);
                    break;
                }
            }
            System.out.println("break: finished shelf " + s);
        }

        search:
        for (int s = 0; s < shelves.length; s++) {
            for (int p = 0; p < shelves[s].length; p++) {
                if (shelves[s][p].equals(wanted)) {
                    System.out.println("break search: found at " + s + "/" + p);
                    break search;
                }
            }
            System.out.println("break search: finished shelf " + s);
        }

        int copies = 0;
        while (true) {
            copies++;
            if (copies * 70 >= 300) {
                break;
            }
        }
        System.out.println(copies + " copies of 70 pages cover 300");
    }
}
```

```
ana@vm:~/loops$ java Search.java
20th century: 1928
20th century: 1943
break: finished shelf 0
break: found at 1/0
break: finished shelf 1
break: finished shelf 2
break search: finished shelf 0
break search: found at 1/0
5 copies of 70 pages cover 300
```

## `continue`

The first loop printed only the years from 1900 on. For 1899 and 1881 the `continue` jumped straight
to the next pass, past the `println`. It is a way to say "not this one" at the top of a body instead
of wrapping the rest of it in an `if`, and a short guard like this one is where it reads best.

## `break` leaves one loop, the innermost

The second search found the book on shelf 1, and **then went on to shelf 2**. The `break` left the
inner loop, over the places on one shelf, and the outer loop over the shelves carried on as if
nothing had happened, printing `finished shelf 1` and `finished shelf 2`. In a library of two hundred
shelves, that is a search that finds the book and then checks the other hundred and ninety-eight.

## A label names the loop to leave

The third search put a **label**, `search:`, in front of the outer loop, and `break search` left that
loop by name. The output stops at `found at 1/0`: no `finished shelf 1`, no shelf 2. A label is any
name followed by a colon, written immediately before a loop, and `continue search` would work the
same way, moving to the next pass of the outer loop. Labels are rare, and that is fine; the
alternative here is a `boolean found` checked by the outer loop, or putting the search in a method
that `return`s, which lesson 13 makes possible.

## `while (true)` with a `break`

The last loop has no condition of its own. It runs until the `if` inside it breaks out: after 5
copies of 70 pages, 350 covers 300. **This shape is honest when the test can only be made in the
middle of the body**, after something has been read or computed. When the test fits in the loop's
header, put it there, where a reader looks for it.
