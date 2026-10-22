---
title: Constructors, so an object is never half built
version: 1
---

Section 02 ended on a trap: a field nobody set is `null`, and nothing says whether that was meant.
`UseBook` made a book and then set its title and its year in two more lines, and a program that
forgot one of them would have a book with no title and no complaint. **A constructor is the code
that runs while `new` makes the object**, and if it takes the values as parameters, there is no way
to make the object without them.

Section 04 has a `Book` of its own, so it works in a new directory, `~/ctors`:

```java
// Book.java
class Book {
    String isbn;
    String title;
    int year;

    Book(String isbn, String title, int year) {
        this.isbn = isbn;
        this.title = title;
        this.year = year;
    }

    Book(String isbn, String title) {
        this(isbn, title, 0);
    }
}
```

A constructor looks like a method with two differences: **its name is the class's name, and it
declares no return type**, not even `void`. This class has two. The first takes all three values
and stores them, using `this` exactly as `rename` did in section 03. The second takes two and
passes them on to the first with `this(...)`, adding 0 for the year, so the storing is written once.
A call to another constructor with `this(...)` has to be the constructor's first statement.

```java
// Main.java
public class Main {
    public static void main(String[] args) {
        Book a = new Book("978-85-359-0277-1", "Dom Casmurro", 1899);
        Book b = new Book("978-85-01-01234-5", "Untitled draft");
        System.out.println(a.title + ", " + a.year);
        System.out.println(b.title + ", " + b.year);
    }
}
```

```
ana@vm:~/ctors$ javac Main.java && java Main
Dom Casmurro, 1899
Untitled draft, 0
ana@vm:~/ctors$ javap -p Book
Compiled from "Book.java"
class Book {
  java.lang.String isbn;
  java.lang.String title;
  int year;
  Book(java.lang.String, java.lang.String, int);
  Book(java.lang.String, java.lang.String);
}
```

`new Book(...)` chose a constructor by the arguments it was given, three or two. And look at what
`javap` lists: the two constructors written in the file, and **no `Book()`**.

## The free constructor goes when you write one

Lessons 1 and 12 found a constructor nobody wrote, `Book()`, which the compiler adds to a class that
declares none. Declare any constructor and the compiler adds nothing, so code that relied on the old
one stops compiling:

```java
// OldMain.java
public class OldMain {
    public static void main(String[] args) {
        Book empty = new Book();
    }
}
```

```
ana@vm:~/ctors$ javac OldMain.java
OldMain.java:4: error: no suitable constructor found for Book(no arguments)
        Book empty = new Book();
                     ^
    constructor Book.Book(String,String,int) is not applicable
      (actual and formal argument lists differ in length)
    constructor Book.Book(String,String) is not applicable
      (actual and formal argument lists differ in length)
1 error
```

**That error is the point of the constructor, not a side effect.** A book without an ISBN and a
title can no longer be made by accident. The message lists every constructor the class has and why
each one does not fit, which makes it the quickest way to learn what a class expects.

## The parameter that hides the field

Forget `this` in a constructor and the program compiles, runs, and loses the value:

```java
// Copy.java
class Copy {
    String barcode;

    Copy(String barcode) {
        barcode = barcode;
    }
}
```

```java
// CopyMain.java
public class CopyMain {
    public static void main(String[] args) {
        Copy c = new Copy("BC-0001");
        System.out.println(c.barcode);
    }
}
```

```
ana@vm:~/ctors$ javac CopyMain.java && java CopyMain
null
```

Inside the constructor the parameter `barcode` hides the field `barcode`, so `barcode = barcode`
assigns the parameter to itself. The field keeps its default, `null`, and `javac` printed no
warning. **When a parameter has a field's name, write `this.` on the field side, every time.**
Lesson 16 shows a way to make the compiler refuse a constructor that leaves a field unset, and lesson
27 gives the whole order in which an object's fields, initialisers and constructors run.
