---
title: The compact constructor, and how far immutable goes
version: 1
---

A record accepts whatever it is given. `new Isbn("banana")` would compile and run, and the bad value
would travel through the program until something far away tripped over it. **The place to refuse
bad data is the constructor**, and a record lets you add code to the one the compiler writes, in a
short form called the **compact constructor**:

```java
// Checked.java
record Isbn(String value) {
    Isbn {
        value = value.replace("-", "").strip();
        if (value.length() != 13) {
            throw new IllegalArgumentException("an ISBN-13 has 13 digits, not " + value.length());
        }
    }
}

public class Checked {
    public static void main(String[] args) {
        System.out.println(new Isbn(" 978-85-359-0277-1 "));
        System.out.println(new Isbn("978-85-359"));
    }
}
```

The compact constructor is the record's name and a block, with no parameter list, because the
parameters are the components. **It runs before the fields are assigned**, so it can do two things.
It can **normalise**: `value = value.replace("-", "").strip()` reassigns the *parameter*, and the
field gets the tidied value when the block ends. And it can **validate**, throwing before a bad
record exists at all. You never write `this.value = value`; the compiler adds that at the end.

```
ana@vm:~/records/compact$ javac Checked.java && java Checked
Isbn[value=9788535902771]
Exception in thread "main" java.lang.IllegalArgumentException: an ISBN-13 has 13 digits, not 8
	at Isbn.<init>(Checked.java:6)
	at Checked.main(Checked.java:14)
```

The first ISBN arrived with hyphens and spaces and was stored as thirteen digits. The second was
refused in the constructor, line 6, and no `Isbn` holding eight digits was ever created. **Every
`Isbn` in the program is now valid by construction**: a method that receives one does not have to
check it again, and that is the point of putting the check in the type rather than in each method
that uses it.

## Immutable is one level deep

Section 02 said a record's fields cannot be reassigned. **That says nothing about the objects the
fields point at.** A component of type `List<String>` is a final reference to a list, and lesson 16
showed that a final reference to a list still lets anybody change the list. Two shelves, one
careless and one careful:

```java
// Shelves.java
import java.util.ArrayList;
import java.util.List;

record Shelf(String name, List<String> titles) {
}

record SafeShelf(String name, List<String> titles) {
    SafeShelf {
        titles = List.copyOf(titles);
    }
}

public class Shelves {
    public static void main(String[] args) {
        List<String> titles = new ArrayList<>(List.of("Dom Casmurro"));
        Shelf shelf = new Shelf("A", titles);
        SafeShelf safe = new SafeShelf("A", titles);

        titles.add("Iracema");
        System.out.println(shelf);
        System.out.println(safe);

        safe.titles().add("O Cortiço");
    }
}
```

```
ana@vm:~/records/compact$ javac Shelves.java && java Shelves
Shelf[name=A, titles=[Dom Casmurro, Iracema]]
SafeShelf[name=A, titles=[Dom Casmurro]]
Exception in thread "main" java.lang.UnsupportedOperationException
	at java.base/java.util.ImmutableCollections.uoe(ImmutableCollections.java:159)
	at java.base/java.util.ImmutableCollections$AbstractImmutableCollection.add(ImmutableCollections.java:164)
	at Shelves.main(Shelves.java:24)
```

**`Shelf` changed after it was built.** Its constructor stored the caller's own list, so the
`titles.add("Iracema")` in `main` reached inside the record, and a value that two parts of the
program thought they shared quietly became something else. `SafeShelf` copied the list in its
compact constructor with `List.copyOf`, which makes an unmodifiable copy. The caller's later `add` did
not reach it, and when `main` tried to add through the accessor, the copy refused with
`UnsupportedOperationException` (lesson 31 meets that exception again).

**A record is as immutable as its components.** Strings, numbers, other records and enums are
immutable already. A list, a map, an array or an ordinary mutable object needs a copy on the way in,
and the compact constructor is where it goes.
