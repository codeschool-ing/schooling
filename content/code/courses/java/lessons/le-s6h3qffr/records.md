---
title: A class that is only its data
version: 1
---

A class written the long way has private fields, a constructor that sets them, an accessor for each
(lesson 22), and then `equals`, `hashCode` and `toString`, which lesson 24 showed are easy to get
subtly wrong. **For a class whose whole job is to carry some values, that is a page of code that says one
thing**, and every line of it is a line somebody can break in an edit. Since Java 16 there is a
shorter way to say it.

A **record** declares its fields in its header, as **components**, and the compiler writes
everything else. Two of them, in `~/records`. The ISBN is made up for the lesson:

```java
// Records.java
record Isbn(String value) {
}

record Book(Isbn isbn, String title, int year) {
}

public class Records {
    public static void main(String[] args) {
        Book a = new Book(new Isbn("9788535902771"), "Dom Casmurro", 1899);
        Book b = new Book(new Isbn("9788535902771"), "Dom Casmurro", 1899);

        System.out.println(a);
        System.out.println(a.title() + ", " + a.year());
        System.out.println(a == b);
        System.out.println(a.equals(b));
        System.out.println(a.hashCode() == b.hashCode());
    }
}
```

```
ana@vm:~/records$ javac Records.java && java Records
Book[isbn=Isbn[value=9788535902771], title=Dom Casmurro, year=1899]
Dom Casmurro, 1899
false
true
true
```

Five lines of output, five things the compiler wrote:

- **`toString` prints the record's name and every component**, and the `Isbn` inside prints itself
  the same way. No `Book@` and a hash code, which is what lesson 12's class printed.
- **The accessors are named after the components, with no `get`**: `a.title()`, not
  `a.getTitle()`.
- `a == b` is `false`, because `new` ran twice and made two objects. **`equals` is `true`, because a
  record's `equals` compares every component**, and the two books hold equal values. Their hash codes
  agree too, as lesson 32's `HashSet` and `HashMap` require.

## What the compiler wrote

```
ana@vm:~/records$ javap -p Book
Compiled from "Records.java"
final class Book extends java.lang.Record {
  private final Isbn isbn;
  private final java.lang.String title;
  private final int year;
  Book(Isbn, java.lang.String, int);
  public final java.lang.String toString();
  public final int hashCode();
  public final boolean equals(java.lang.Object);
  public Isbn isbn();
  public java.lang.String title();
  public int year();
}
```

Read it against that list:

- **`final class Book extends java.lang.Record`.** A record cannot be extended, and it extends
  `Record` the way an enum extends `Enum` (lesson 28).
- **Each component is a `private final` field.** There is no setter and there can be none, so a
  record is fixed from the moment it is built. That is what "immutable" in this lesson's title means:
  the fields cannot be reassigned.
- **One constructor taking every component, in order**, called the *canonical* constructor. Section
  03 is where you add your own code to it.
- `toString`, `hashCode` and `equals`, all generated from the components, and one accessor per
  component.

Everything on the list is there, and none of it can drift out of step with the fields. Add a
component to the header and the constructor, the accessor, `equals`, `hashCode` and `toString` all
include it on the next compile. **Two records with equal components are interchangeable**, which is
the definition of a value, and it is why a record is the natural shape for an ISBN, a date range, a
point on a map or a row read from a file.
