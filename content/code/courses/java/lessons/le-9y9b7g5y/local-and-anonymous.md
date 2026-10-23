---
title: Classes with no name, and classes inside a method
version: 1
---

The last two kinds of nested class are declared **inside a method**. A **local class** has a name
that only that method can use. An **anonymous class** has no name at all: it is declared and
instantiated in one expression, at the place it is needed, and it is how Java code passed a piece of
behaviour to a method for nearly twenty years.

## An anonymous class: behaviour as an argument

`Arrays.sort` puts an array in order. With strings, the order is by character code, and every
capital letter comes before every small one, which puts a title that starts with a small letter at
the end. To sort differently you hand `sort` an object that compares two strings your way, a
`Comparator`. Writing a named class for one comparison is a lot of ceremony, so this one is
anonymous:

```java
// Sorting.java
import java.util.Arrays;
import java.util.Comparator;

public class Sorting {
    public static void main(String[] args) {
        String[] titles = {"Head First Java", "effective Java", "Modern Java in Action"};
        Arrays.sort(titles);
        System.out.println(Arrays.toString(titles));

        Comparator<String> ignoringCase = new Comparator<String>() {
            @Override
            public int compare(String a, String b) {
                return a.compareToIgnoreCase(b);
            }
        };
        Arrays.sort(titles, ignoringCase);
        System.out.println(Arrays.toString(titles));
        System.out.println(ignoringCase.getClass().getName());
    }
}
```

```
ana@vm:~/nested$ javac Sorting.java && java Sorting
[Head First Java, Modern Java in Action, effective Java]
[effective Java, Head First Java, Modern Java in Action]
Sorting$1
ana@vm:~/nested$ ls Sorting*
Sorting$1.class
Sorting.class
Sorting.java
```

The first sort put `effective Java` last, because `e` comes after every capital. The second used
the anonymous comparator and put it first.

**`new Comparator<String>() { ... }` reads as "a new object of a class that implements
`Comparator<String>` and has this body".** `Comparator` is an interface, so it cannot be instantiated
on its own; the braces after the parentheses supply the missing method, `compare`, and the
expression creates the one object of that class there and then. Lesson 23 is about interfaces, and
`@Override` is lesson 24's; for now it is enough that `compare` is the method `sort` calls.

The class has no name in the source, so the compiler gave it one: **`Sorting$1`**, the first
anonymous class in `Sorting`. That is what `getClass().getName()` printed and what `ls` found on
disk. A second anonymous class in the same file would be `Sorting$2`.

**This is the code a lambda replaced.** Since Java 8 the same comparator is one line,
`(a, b) -> a.compareToIgnoreCase(b)`, and the course after this one, `java-functional`, starts there.
You will still read anonymous classes in older code, and the rules below apply to lambdas unchanged.

## A local class, and what it may capture

A local class is declared among the statements of a method, and it can use that method's local
variables:

```java
// Overdue.java
public class Overdue {
    public static void main(String[] args) {
        int days = 14;
        class Notice {
            String text(String title) {
                return title + " is due back in " + days + " days";
            }
        }
        Notice notice = new Notice();
        System.out.println(notice.text("Effective Java"));
    }
}
```

```
ana@vm:~/nested$ javac Overdue.java && java Overdue
Effective Java is due back in 14 days
ana@vm:~/nested$ ls Overdue*
Overdue$1Notice.class
Overdue.class
Overdue.java
```

`Notice` read `days`, a local variable of `main`. The class file is `Overdue$1Notice`: a number
because two methods could each declare a local `Notice`, then the name.

Now change `days` after it has been set, by adding one line, `days = 21;`, just before the notice is
created:

```
ana@vm:~/nested$ sed -i '/Notice notice = new Notice/i\        days = 21;' Overdue.java
ana@vm:~/nested$ javac Overdue.java
Overdue.java:7: error: local variables referenced from an inner class must be final or effectively final
                return title + " is due back in " + days + " days";
                                                    ^
1 error
```

The error points at the use inside the class, not at the assignment. **A local or anonymous class may
read a local variable only if that variable never changes after it is first set**, which Java calls
*effectively final*: final in fact, whether or not the word `final` is written. Lesson 16 gives the
term its own section.

The reason is the hidden field again. The class does not reach back into `main`'s variables while it
runs; when the object is created, **the compiler copies the variable's value into a field of the
object**, the way section 03 copied the owner into `this$0`. A copy taken of something that later
changed would be a second, stale version of it, and Java refuses rather than let the two disagree. If
the value genuinely has to change, put it in a field of an object, which both sides can share.

## The four kinds, side by side

| kind | declared | tied to an outer object | typical use |
|---|---|---|---|
| static nested | in a class, with `static` | no | a helper type that belongs to one class: `Map.Entry`, a builder |
| inner | in a class, without `static` | yes, through `this$0` | an object that only makes sense with its owner: a card and its member |
| local | among a method's statements | yes, when the method is an instance method | a small helper used by one method |
| anonymous | in an expression, with `new` | as local | one object with one job, passed as an argument |
