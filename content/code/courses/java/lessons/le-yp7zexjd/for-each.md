---
title: The enhanced `for`, and what it cannot do
version: 1
---

Lesson 9 met `for (int n : stock)`, the loop over every element of an array. Its name is the
**enhanced `for`**, and people call it for-each, which describes it better. It works on arrays and on
every collection in the library, `List` included, which lesson 31 introduces:

```java
// Each.java
import java.util.Arrays;
import java.util.List;

public class Each {
    public static void main(String[] args) {
        String[] titles = {"Dom Casmurro", "Iracema", "Macunaíma"};
        for (String t : titles) {
            System.out.println(t.length() + " " + t);
        }

        List<String> shelf = List.of("O Guarani", "Senhora");
        for (String t : shelf) {
            System.out.println("on the shelf: " + t);
        }

        int[] fines = {10, 20, 30};
        for (int f : fines) {
            f = f * 2;
        }
        System.out.println(Arrays.toString(fines));

        for (int i = 0; i < fines.length; i++) {
            fines[i] = fines[i] * 2;
        }
        System.out.println(Arrays.toString(fines));
    }
}
```

```
ana@vm:~/loops$ java Each.java
12 Dom Casmurro
7 Iracema
9 Macunaíma
on the shelf: O Guarani
on the shelf: Senhora
[10, 20, 30]
[20, 40, 60]
```

**Read the colon as "in"**: for each `String t` in `titles`. The loop takes care of the position,
the test and the step, which removes every place an off-by-one could hide. On the `List` it works
the same way and needs nothing different, because the loop asks the collection for its elements one
at a time; lesson 34 shows the object it asks, the `Iterator`.

## It hands you a copy of each value

The third loop tried to double every fine and **changed nothing**: the array printed
`[10, 20, 30]` afterwards. The variable `f` holds a copy of the current element, and `f = f * 2`
changed the copy. The array was never touched, and the compiler did not complain, because assigning
to a local variable is legal.

To change elements in place you need their positions, and the loop that has positions is the
counting `for`. The fourth loop wrote through `fines[i]` and printed `[20, 40, 60]`. So the rule for
choosing between them is short: **for-each to read, the counting `for` to write**, or whenever the
position itself matters, as in printing `place 3 of 5`.

With an array of objects the same rule holds with one twist: `t = "x"` inside the loop would replace
only the copy of the reference, but calling a method that changes the object would change the real
one. Lesson 30 is about that difference.
