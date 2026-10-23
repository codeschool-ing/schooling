---
title: A class describes, an object exists
version: 1
---

Every program in lessons 1 to 11 was a class with a `main` in it, and the class did nothing but hold
that method. That is a narrow use of the word. **A class is a description of a kind of thing**: the
data every one of them carries, and, from lesson 13, what each one can do. An **object** is one of
those things, made while the program runs. The class is written once; the objects are made as many
times as the program asks.

Make a directory for this lesson, `~/objects`, and save this as `Book.java`:

```java
// Book.java
class Book {
    String isbn;
    String title;
    int year;
}
```

Three **fields**: variables declared inside the class and outside any method. Every `Book` will have
its own `isbn`, its own `title` and its own `year`. There is no `main`, so this class is not a
program and `java Book` would have nothing to start. The class is not `public` either, which lesson
14 explains; for now it only means that any class in the same directory may use it.

A second file uses it:

```schooling-example
{
  "language": "java",
  "file": "Main.java",
  "parts": [
    {
      "code": "// Main.java\npublic class Main {\n    public static void main(String[] args) {",
      "note": "An ordinary program, like the ones in lessons 1 to 11."
    },
    {
      "code": "        Book first = new Book();",
      "note": "**`new Book()` makes an object** and hands back a way to reach it, which goes into the variable `first`. The variable's type is the class, `Book`."
    },
    {
      "code": "        first.title = \"Dom Casmurro\";\n        first.year = 1899;",
      "note": "A dot reaches into the object: `first.title` is the `title` field of that one book."
    },
    {
      "code": "\n        Book second = new Book();\n        second.title = \"Vidas Secas\";\n        second.year = 1938;",
      "note": "A second `new`, a second object. Its fields are its own, and setting them changes nothing in `first`."
    },
    {
      "code": "\n        System.out.println(first.title + \", \" + first.year);\n        System.out.println(second.title + \", \" + second.year);\n        System.out.println(first.isbn);",
      "note": "Nobody set `first.isbn`. **A field nobody assigned has a default**: `null` for a reference such as a `String`, `0` for an `int`."
    },
    {
      "code": "        System.out.println(first);\n        System.out.println(second);\n    }\n}",
      "note": "Printing the object itself, rather than one of its fields."
    }
  ]
}
```

Compile both, and run the one with the `main`:

```
ana@vm:~/objects$ javac Book.java Main.java
ana@vm:~/objects$ ls
Book.class
Book.java
Main.class
Main.java
ana@vm:~/objects$ java Main
Dom Casmurro, 1899
Vidas Secas, 1938
null
Book@251a69d7
Book@7344699f
```

**One class, two objects, each with its own title and year.** The third line is the `isbn` nobody
set, and it printed `null` rather than failing: a field always has a value, and the compiler supplies
one if you do not. A local variable has no such default, which lesson 5 showed as a compile error.

The last two lines are what Java prints for an object when the class has not said how to describe
itself: the class name, an `@`, and a number in hexadecimal. **The number is a hash code, not an
address**, and it differs on every run; yours will not match these. What it shows is that the two
objects are two, even though they came from the same class. Lesson 20 teaches a class to print
something more useful, by writing its own `toString`.

## What the compiler made of the class

```
ana@vm:~/objects$ javap -p Book
Compiled from "Book.java"
class Book {
  java.lang.String isbn;
  java.lang.String title;
  int year;
  Book();
}
```

The three fields, as declared, and one thing nobody wrote: `Book()`, a constructor. It is the same
compiler-written constructor lesson 1 found in `Hello`, and it is what `new Book()` calls. Lesson 13
writes constructors of its own, and shows what happens to this one when you do.

**The `.class` file holds the description and nothing else.** No book exists until a program runs
and says `new`, and when that program ends, its books are gone with it. Section 04 looks at them
while they exist.
