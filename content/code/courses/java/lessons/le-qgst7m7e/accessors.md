---
title: Getters, setters and the check that lives in them
version: 1
---

The usual complaint about getters and setters is that they are ceremony: two methods to write for
every field, doing nothing a public field would not do. **When a setter does nothing but assign, the
complaint is fair.** The point of an accessor is the line a public field has no room for, and the
quickest way to see it is a class that has no accessors at all.

## A public field accepts anything

Save both files in a new directory, `~/encap`:

```java
// OpenBook.java
public class OpenBook {
    public String title;
    public int year;
}
```

```java
// OpenDemo.java
public class OpenDemo {
    public static void main(String[] args) {
        OpenBook book = new OpenBook();
        book.title = "Dom Casmurro";
        book.year = -1899;
        System.out.println(book.title + " (" + book.year + ")");
    }
}
```

```
ana@vm:~/encap$ javac OpenBook.java OpenDemo.java && java OpenDemo
Dom Casmurro (-1899)
```

A book published in the year minus 1899, and **nothing objected**: not the compiler, not the JVM,
not the program. The mistake will surface somewhere else, later, in whatever code first trusts the
year, and that code will have no idea who wrote it. With a public field, `OpenBook` cannot even know
the moment its year changes, because no code of its own runs when it does.

## The same book, with the field private

```java
// Book.java
public class Book {
    private final String title;
    private int year;

    public Book(String title, int year) {
        this.title = title;
        this.year = checkYear(year);
    }

    public String getTitle() {
        return title;
    }

    public int getYear() {
        return year;
    }

    public void setYear(int year) {
        this.year = checkYear(year);
    }

    private static int checkYear(int year) {
        if (year < 1450 || year > 2100) {
            throw new IllegalArgumentException("year out of range: " + year);
        }
        return year;
    }
}
```

Four things changed, and each one is doing work:

- **Both fields are `private`**, so the only code that can write `year` is inside `Book`.
- `title` is also `final` and has a getter and no setter: once a book is built, its title is fixed.
  Leaving out a setter is a decision, and the most common one a class makes.
- `getYear()` and `setYear(int)` follow the JavaBeans naming that every Java tool expects: `get`
  plus the field's name with a capital, `set` for the writer, and `is` instead of `get` for a
  `boolean`, as in `isAvailable()`.
- **Every write goes through `checkYear`**, the constructor's included. A check in the setter alone
  would leave `new Book("x", -1899)` as a way round it.

`BookDemo` builds a valid book and then tries the bad year:

```java
// BookDemo.java
public class BookDemo {
    public static void main(String[] args) {
        Book book = new Book("Dom Casmurro", 1899);
        System.out.println(book.getTitle() + " (" + book.getYear() + ")");
        book.setYear(-1899);
        System.out.println("never printed");
    }
}
```

```
ana@vm:~/encap$ javac Book.java BookDemo.java && java BookDemo; echo $?
Dom Casmurro (1899)
Exception in thread "main" java.lang.IllegalArgumentException: year out of range: -1899
	at Book.checkYear(Book.java:25)
	at Book.setYear(Book.java:20)
	at BookDemo.main(BookDemo.java:6)
1
```

**The bad value now stops the program on the line that wrote it**: the last line of the stack trace
is `BookDemo.java:6`, the `setYear(-1899)` call, and `never printed` was never printed. Lesson 36
reads a stack trace properly. What matters here is where it points, which is at the culprit rather
than at the victim.

And going round the setter is not an option any more:

```java
// Sneaky.java
public class Sneaky {
    public static void main(String[] args) {
        Book book = new Book("Dom Casmurro", 1899);
        book.year = -1899;
    }
}
```

```
ana@vm:~/encap$ javac Sneaky.java
Sneaky.java:5: error: year has private access in Book
        book.year = -1899;
            ^
1 error
```

## When a plain setter is still worth writing

A setter with no check, `this.year = year;` and nothing else, buys less today. It still buys a
place: the day the rule arrives, the check goes into one method and every caller gets it, where a
public field would mean finding and changing every line that writes it. Inside one small program
that cost is small. In a library other teams compile against it is a broken build for each of them.

**Write the getter when somebody needs to read the value. Write the setter only when somebody truly
needs to change it**, and put the rule in it. A class with a getter and a setter for every field,
none of them checking anything, has the cost of encapsulation and none of the protection.
