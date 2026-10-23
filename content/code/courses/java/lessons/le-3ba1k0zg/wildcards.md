---
title: Wildcards, and the list that is not a list of numbers
version: 1
---

An `Integer` is a `Number`, so the common belief is that a `List<Integer>` is a `List<Number>`. **It
is not, and the compiler says so**:

```java
// Invariant.java
import java.util.List;

public class Invariant {
    static double total(List<Number> amounts) {
        double sum = 0;
        for (Number n : amounts) {
            sum += n.doubleValue();
        }
        return sum;
    }

    public static void main(String[] args) {
        List<Integer> fines = List.of(2, 5, 3);
        System.out.println(total(fines));
    }
}
```

```
ana@vm:~/generics$ javac Invariant.java
Invariant.java:15: error: incompatible types: List<Integer> cannot be converted to List<Number>
        System.out.println(total(fines));
                                 ^
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
1 error
```

The refusal protects something. If a `List<Integer>` could be passed as a `List<Number>`, the method
receiving it could call `amounts.add(2.5)`, which is a perfectly good `Number`, and the caller's list
of integers would then hold a `Double`. **Generic types are invariant**: `List<Integer>` and
`List<Number>` are two unrelated types, whatever the relation between `Integer` and `Number`.

But `total` never adds anything. It only reads, and reading numbers out of a list of integers is
safe. A **wildcard** is how a method says that.

## `? extends` to read, `? super` to write

```java
// Wild.java
import java.util.ArrayList;
import java.util.List;

public class Wild {
    static double total(List<? extends Number> amounts) {
        double sum = 0;
        for (Number n : amounts) {
            sum += n.doubleValue();
        }
        return sum;
    }

    static <T> void copy(List<? super T> to, List<? extends T> from) {
        for (T item : from) {
            to.add(item);
        }
    }

    public static void main(String[] args) {
        List<Integer> fines = List.of(2, 5, 3);
        List<Double> fees = List.of(1.5, 0.25);
        System.out.println(total(fines));
        System.out.println(total(fees));

        List<Number> all = new ArrayList<>();
        copy(all, fines);
        copy(all, fees);
        System.out.println(all);
    }
}
```

```
ana@vm:~/generics$ javac Wild.java && java Wild
10.0
1.75
[2, 5, 3, 1.5, 0.25]
```

**`List<? extends Number>` means "a list of some type that is a `Number`"**, without saying which.
`total` accepted a `List<Integer>` and a `List<Double>`, and could read each element as a `Number`.
What it cannot do is add to that list, because it does not know which type the list really holds;
`amounts.add(1)` would not compile.

`copy` needs both directions. It reads `T`s out of `from` and writes them into `to`, so `from` is
`? extends T`, anything that produces `T`s, and `to` is `? super T`, anything that accepts them. With
`T` inferred as `Integer` and then `Double`, a `List<Number>` accepted both, and printed
`[2, 5, 3, 1.5, 0.25]`.

The rule has a mnemonic, **PECS: producer `extends`, consumer `super`**. A parameter the method reads
from is a producer; a parameter it writes into is a consumer. A parameter it does both with gets no
wildcard at all, just `List<T>`.

| the parameter is | write | the method may |
|---|---|---|
| read from | `List<? extends T>` | take elements out as `T` |
| written into | `List<? super T>` | put `T`s in |
| read and written | `List<T>` | both, for exactly one `T` |
| neither, only counted or cleared | `List<?>` | call `size`, `clear`, `isEmpty` |

You meet these in the JDK's own signatures more than you write them: `Collections.copy` is declared
almost exactly like `copy` above, and `addAll` takes a `Collection<? extends E>`.
