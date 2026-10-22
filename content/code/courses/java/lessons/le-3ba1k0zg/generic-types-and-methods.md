---
title: Writing a generic class and a generic method
version: 1
---

`List<E>` is not magic reserved for the JDK. **Any class can take a type parameter**, a name in
angle brackets after the class's own name, and use it wherever a type would go. The convention is a
single capital letter: `T` for a type, `E` for an element, `K` and `V` for a key and a value.

The smallest useful example is a box that holds one thing of a type chosen by whoever uses it:

```java
// Box.java
public class Box<T> {
    private T item;

    public void put(T item) {
        this.item = item;
    }

    public T take() {
        return item;
    }
}
```

Inside the class, `T` stands for a type nobody has chosen yet. **Each use of `Box` chooses it**:
`Box<String>` is a box of strings, `Box<Book>` a box of books, and the compiler checks every `put`
and `take` against the choice. The class was written once.

A method can have type parameters of its own, and `UseBox` declares one that also says what it needs
from the type:

```schooling-example
{
  "language": "java",
  "file": "UseBox.java",
  "parts": [
    {
      "code": "import java.util.List;\n\npublic class UseBox {\n    static <T extends Comparable<T>> T max(List<T> items) {",
      "note": "**A generic method declares its own type parameter**, in angle brackets before the return type. `T extends Comparable<T>` is a **bound**: `T` may be any type whose objects can be compared with each other."
    },
    {
      "code": "        T best = items.get(0);\n        for (T item : items) {\n            if (item.compareTo(best) > 0) {\n                best = item;\n            }\n        }\n        return best;\n    }",
      "note": "**The bound is what makes `compareTo` callable.** Without it, `T` could be anything and the compiler would only allow `Object`'s methods on `item`."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        Box<String> box = new Box<>();\n        box.put(\"Dune\");\n        String title = box.take();\n        System.out.println(title.length());",
      "note": "**`Box<String>` fixes `T` as `String` for this one box.** `take()` then returns a `String`, with no cast written, and `length()` is available on it. The `<>` on the right is the diamond: the compiler copies the type from the left."
    },
    {
      "code": "\n        System.out.println(max(List.of(\"Dune\", \"Ulysses\", \"Emma\")));\n        System.out.println(max(List.of(1965, 1815, 1922)));\n    }\n}",
      "note": "**At each call the compiler infers `T`**: `String` for the first, `Integer` for the second. Both are `Comparable` with themselves, so both calls compile, and one method serves the two types."
    }
  ]
}
```

```
ana@vm:~/generics$ javac Box.java UseBox.java && java UseBox
4
Ulysses
1965
```

`4` is the length of `Dune`, `Ulysses` comes last alphabetically, and `1965` is the largest year.
**One `max`, two element types, and no cast anywhere.**

## A bound is a requirement the compiler enforces

The bound `T extends Comparable<T>` is a promise the caller has to keep. A record of members that
cannot be compared does not keep it:

```java
// NoOrder.java
import java.util.List;

public class NoOrder {
    record Member(String name) {}

    static <T extends Comparable<T>> T max(List<T> items) {
        return items.get(0);
    }

    public static void main(String[] args) {
        System.out.println(max(List.of(new Member("Ana"), new Member("Bruno"))));
    }
}
```

```
ana@vm:~/generics$ javac NoOrder.java
NoOrder.java:12: error: method max in class NoOrder cannot be applied to given types;
        System.out.println(max(List.of(new Member("Ana"), new Member("Bruno"))));
                           ^
  required: List<T>
  found:    List<Member>
  reason: inference variable E has incompatible bounds
    upper bounds: Comparable<T>,Object
    lower bounds: Member
  where T,E are type-variables:
    T extends Comparable<T> declared in method <T>max(List<T>)
    E extends Object declared in method <E>of(E,E)
1 error
```

The message is long because it reports an inference that failed, and it reads from the bottom up.
**`Member` was the type found, and it is not a `Comparable`**, so no `T` satisfies both what
`List.of` produced and what `max` requires. The fix belongs to `Member`: implement
`Comparable<Member>`, as lesson 23 did for `Book`, or pass a `Comparator` to a version of `max` that
takes one. The `extends` in a bound means "is a subtype of", and it is written `extends` even when
the bound is an interface.
