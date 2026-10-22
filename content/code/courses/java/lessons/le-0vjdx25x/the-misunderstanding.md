---
title: Six beliefs, six experiments
version: 1
---

The misunderstanding rarely announces itself as a theory. It shows up as a method that was expected
to change something and did not, or one that was not expected to and did. **Each of the six
experiments below tests a belief somebody holds**, and each result follows from section 03's
sentence: everything is passed by value, and for an object the value is a reference. In
`~/byvalue/myths`:

```java
// Myths.java
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class Myths {
    static void shout(String s) {
        s = s.toUpperCase();
    }

    static void increment(Integer n) {
        n++;
    }

    static void swap(String a, String b) {
        String t = a;
        a = b;
        b = t;
    }

    static void zero(int[] numbers) {
        numbers[0] = 0;
    }

    static void forget(List<String> list) {
        list = new ArrayList<>();
    }

    static void empty(List<String> list) {
        list.clear();
    }

    public static void main(String[] args) {
        String name = "ana";
        shout(name);
        System.out.println("1 " + name);

        Integer count = 5;
        increment(count);
        System.out.println("2 " + count);

        String first = "A";
        String second = "B";
        swap(first, second);
        System.out.println("3 " + first + second);

        int[] numbers = {7, 8, 9};
        zero(numbers);
        System.out.println("4 " + Arrays.toString(numbers));

        List<String> titles = new ArrayList<>(List.of("Dom Casmurro"));
        forget(titles);
        System.out.println("5 " + titles);
        empty(titles);
        System.out.println("6 " + titles);
    }
}
```

```
ana@vm:~/byvalue/myths$ javac Myths.java && java Myths
1 ana
2 5
3 AB
4 [0, 8, 9]
5 [Dom Casmurro]
6 []
```

Line by line, with the belief each line tests:

| line | the belief | what happened, and why |
|---|---|---|
| `1 ana` | "a String is an object, so `shout` changes it" | `toUpperCase` returns a **new** string (lesson 7), and `s = …` points `shout`'s own copy at it. The caller's string was never changed, because no string ever is |
| `2 5` | "`Integer` is an object, so `n++` reaches the caller" | `Integer` is immutable too. `n++` unboxes, adds and boxes a **new** `Integer`, then reassigns `n`, which is `increment`'s copy |
| `3 AB` | "objects are passed by reference, so swapping two works" | the decisive test. By reference, `first` and `second` would have swapped. `swap` swapped its own two copies |
| `4 [0, 8, 9]` | "an array is copied when it is passed" | an array is an object, and only the reference was copied. `numbers[0] = 0` wrote into the one array both arrows reach |
| `5 [Dom Casmurro]` | "`forget` empties the caller's list" | `list = new ArrayList<>()` re-pointed the copy, like section 03's `replace` |
| `6 []` | "a method cannot change the caller's list" | `empty` called a method **on the object**, through its copy of the arrow, and the object changed |

**Lines 1, 2, 3 and 5 are assignments to a parameter, and none reached the caller. Lines 4 and 6
went through the reference to change the object, and both did.** That is the whole of it: assigning
a parameter changes a copy; calling a method on it, or writing to a field or an element of it,
changes the object both copies point at.

## Why strings and wrappers feel like exceptions

`String` and `Integer` look like they break the rule, in the other direction: they are objects, and
yet no method seems able to change them. The rule is the same; what differs is the class. **They are
immutable, so there is no method that changes them**, and the only way to get a different string is
a new string. A method receiving one can only re-point its own copy, which the caller never sees. A
`StringBuilder` is mutable, and section 05 has a method that changes one through its
parameter.

## Why the name matters

"Java passes objects by reference" is not a harmless shorthand. Languages that really pass by
reference have syntax for it, `ref` in C# and `&` in C++, and in them a `swap` method works. A
programmer who believes Java does the same writes the `forget` method above expecting it to clear
the caller's list, and gets line 5. **Java has no syntax for pass by reference because it has no
pass by reference.** When a method needs to give the caller something new, it returns it, and that
is section 05.
