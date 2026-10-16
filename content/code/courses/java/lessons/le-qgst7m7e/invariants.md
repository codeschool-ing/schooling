---
title: Keeping a promise the class made
version: 1
---

An **invariant** is something a class promises is always true of its objects: a shelf never holds
more books than its capacity, a loan always has a due date, a balance is never negative. Making the
fields private is how most invariants start. **It is not where they end**, because a private field
can still be handed out, and a field that holds a mutable object hands out the power to change it.

## A shelf for two that holds three

```java
// Shelf.java
import java.util.ArrayList;
import java.util.List;

public class Shelf {
    private final List<String> titles = new ArrayList<>();
    private final int capacity;

    public Shelf(int capacity) {
        this.capacity = capacity;
    }

    public void add(String title) {
        if (titles.size() == capacity) {
            throw new IllegalStateException("shelf is full: " + capacity + " books");
        }
        titles.add(title);
    }

    public List<String> getTitles() {
        return titles;
    }
}
```

`add` refuses a third book, `titles` is private and final, and the class looks sealed. Now a caller:

```java
// LeakDemo.java
public class LeakDemo {
    public static void main(String[] args) {
        Shelf shelf = new Shelf(2);
        shelf.add("Dom Casmurro");
        shelf.add("Iracema");
        shelf.getTitles().add("O Guarani");
        System.out.println(shelf.getTitles().size() + " books on a shelf for 2");
    }
}
```

```
ana@vm:~/encap$ javac Shelf.java LeakDemo.java && java LeakDemo
3 books on a shelf for 2
```

**`getTitles()` returned the list itself**, not a copy of it. `private` stopped anybody naming the
field; it did nothing about a reference to the same `ArrayList` leaving through a method. `LeakDemo`
then called `add` on that list, which is `ArrayList.add` and knows nothing of shelves or capacities.
`final` did not help either: it fixes which list the field refers to, and says nothing about what is
in it. Lesson 30 draws the two references to one object; here the result is enough, and it is a
broken promise with no exception and no stack trace pointing anywhere.

## Handing out a copy, or a view

```java
// SafeShelf.java
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class SafeShelf {
    private final List<String> titles = new ArrayList<>();
    private final int capacity;

    public SafeShelf(int capacity) {
        this.capacity = capacity;
    }

    public void add(String title) {
        if (titles.size() == capacity) {
            throw new IllegalStateException("shelf is full: " + capacity + " books");
        }
        titles.add(title);
    }

    public List<String> getTitles() {
        return List.copyOf(titles);
    }

    public List<String> view() {
        return Collections.unmodifiableList(titles);
    }
}
```

`SafeShelf` hands out the list in two ways, and they are not the same thing:

| method | what the caller gets | sees later additions | can the caller change it |
|---|---|---|---|
| `getTitles()`, with `List.copyOf` | a new list, frozen at the moment of the call | no | no |
| `view()`, with `Collections.unmodifiableList` | a read-only window onto the shelf's own list | yes | no |

`SafeDemo` takes one of each, adds a book to the shelf, and then tries the leak again:

```java
// SafeDemo.java
import java.util.List;

public class SafeDemo {
    public static void main(String[] args) {
        SafeShelf shelf = new SafeShelf(3);
        shelf.add("Dom Casmurro");
        List<String> copy = shelf.getTitles();
        List<String> view = shelf.view();
        shelf.add("Iracema");
        System.out.println("copy: " + copy);
        System.out.println("view: " + view);
        view.add("O Guarani");
    }
}
```

```
ana@vm:~/encap$ javac SafeShelf.java SafeDemo.java && java SafeDemo
copy: [Dom Casmurro]
view: [Dom Casmurro, Iracema]
Exception in thread "main" java.lang.UnsupportedOperationException
	at java.base/java.util.Collections$UnmodifiableCollection.add(Collections.java:1093)
	at SafeDemo.main(SafeDemo.java:13)
```

**The copy kept one title and the view showed two**: `Iracema` was added after both were taken, and
only the view looks through to the shelf. Then `view.add` threw `UnsupportedOperationException`, on
`SafeDemo.java:13`, the line that tried. A list from `List.copyOf` refuses the same way. Either one
keeps the promise; which to choose depends on whether the caller should see the shelf as it is now
or as it was.

## The same leak on the way in

The mirror image is a constructor that keeps a list it was given. If `Shelf` had a constructor
`Shelf(List<String> titles)` that stored the argument as its field, the caller would still hold the
same list and could add to it afterwards, past every check. **Copy what you receive as well as what
you return**: `this.titles = new ArrayList<>(titles);` in a constructor costs one line and closes
the second door. A `String`, or a record of lesson 29 made only of such values, cannot be changed once built
and needs no copy at all, which is a large part of why immutable types are pleasant to work with.
