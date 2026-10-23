---
title: A class that cannot be instantiated
version: 1
---

Lesson 20's `Item` was an ordinary class, so `new Item("Untitled", 2020)` compiled, and gave the
library an object that is neither a book nor a DVD, lent for a default fourteen days nobody chose.
**Some classes exist only to be extended**, and Java lets them say so: an `abstract` class cannot be
instantiated, and an `abstract` method is one it declares and leaves for each subclass to write.

Make a directory for this lesson, `~/abstract`, and save four files in it. The superclass, now
abstract, with `loanDays()` declared and not written:

```java
// Item.java
public abstract class Item {
    private final String title;

    protected Item(String title) {
        this.title = title;
    }

    public String title() {
        return title;
    }

    public abstract int loanDays();

    public String describe() {
        return title + ", " + loanDays() + " days";
    }
}
```

A subclass that writes it, one that forgets, and a program that tries the forbidden thing:

```java
// Book.java
public class Book extends Item {
    public Book(String title) {
        super(title);
    }

    @Override
    public int loanDays() {
        return 14;
    }
}
```
```java
// Magazine.java
public class Magazine extends Item {
    public Magazine(String title) {
        super(title);
    }
}
```
```java
// Desk.java
public class Desk {
    public static void main(String[] args) {
        Item item = new Book("Effective Java");
        System.out.println(item.describe());
        Item mystery = new Item("Untitled");
    }
}
```

```
ana@vm:~/abstract$ javac Item.java Book.java Desk.java
Desk.java:6: error: Item is abstract; cannot be instantiated
        Item mystery = new Item("Untitled");
                       ^
1 error
```

**`Item is abstract; cannot be instantiated`.** The variable `item` has the type `Item`, which is
allowed and useful, and holds a `Book`, which is concrete. What may not exist is an object whose
class is `Item` itself. Then the class that forgot:

```
ana@vm:~/abstract$ javac Magazine.java
Magazine.java:2: error: Magazine is not abstract and does not override abstract method loanDays() in Item
public class Magazine extends Item {
       ^
1 error
```

**`Magazine is not abstract and does not override abstract method loanDays() in Item`**: the
compiler names the method still missing, and the two ways out are in the sentence. Write
`loanDays()`, or declare `Magazine` abstract as well and leave it to *its* subclasses. A concrete
class must have a body for every method, inherited or its own, and the compiler checks that before
any object can be made.

The program itself is fine once the forbidden line goes. Delete it and compile again:

```
ana@vm:~/abstract$ sed -i '/Item mystery/d' Desk.java && javac Item.java Book.java Desk.java && java Desk
Effective Java, 14 days
```

`describe()` is a concrete method of the abstract class, and it calls `loanDays()`, which `Item`
never wrote. **That is the point of an abstract method: code in the superclass may call it, and every
object it will ever run on is guaranteed to have one.** An abstract method has no body and ends in a
semicolon, and a class that has one must itself be declared `abstract`.
