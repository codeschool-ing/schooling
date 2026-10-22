---
title: Methods run on one object
version: 1
---

Every change to a book in lesson 12 came from outside it: `main` reached in through the dot and set
a field. That works for three fields and stops working at thirty, because every rule about the data
ends up repeated wherever the data is touched. **A method puts the behaviour beside the data it
works on.** It is declared inside the class, and it runs on one object: the one before the dot.

Here is `Book` again, in `~/members`, with four methods:

```schooling-example
{
  "language": "java",
  "file": "Book.java",
  "parts": [
    {"code": "// Book.java\nclass Book {\n    String title;\n    int year;\n    int timesLent;", "note": "Three fields, as in lesson 12, with `timesLent` in place of the ISBN."},
    {"code": "\n    String describe() {\n        return title + \" (\" + year + \")\";\n    }", "note": "**A method declares what it gives back before its name**: `String`. `return` hands the value to the caller. Inside, `title` and `year` with no dot mean the fields of the object the method was called on."},
    {"code": "\n    boolean isOlderThan(int otherYear) {\n        return year < otherYear;\n    }", "note": "A **parameter** in the brackets: the caller must pass an `int`, and inside the method it is called `otherYear`. The result is a `boolean`."},
    {"code": "\n    void lend() {\n        timesLent = timesLent + 1;\n    }", "note": "**`void` means it gives nothing back.** It exists for what it changes: this book's `timesLent`, and no other book's."},
    {"code": "\n    void rename(String title) {\n        this.title = title;\n    }\n}", "note": "The parameter is also called `title`, and inside the method it hides the field. **`this` is the object the method runs on**, so `this.title` is the field and plain `title` is the parameter."}
  ]
}
```

And a program that calls them:

```java
// UseBook.java
public class UseBook {
    public static void main(String[] args) {
        Book b = new Book();
        b.title = "Iracema";
        b.year = 1865;

        System.out.println(b.describe());
        System.out.println(b.isOlderThan(1900));

        b.lend();
        b.lend();
        System.out.println(b.timesLent);

        b.rename("Iracema: lenda do Ceará");
        System.out.println(b.describe());
    }
}
```

```
ana@vm:~/members$ javac UseBook.java && java UseBook
Iracema (1865)
true
2
Iracema: lenda do Ceará (1865)
```

`b.describe()` ran `describe` with `b`'s book as `this`, and built its text out of that book's
fields. `b.lend()` twice moved `timesLent` from 0 to 2. `rename` changed the title, and the second
`describe` saw the change, because the method and the field belong to the same object.

## The signature is a contract the compiler checks

`javap` lists each method in the form the compiler keeps:

```
ana@vm:~/members$ javap -p Book
Compiled from "Book.java"
class Book {
  java.lang.String title;
  int year;
  int timesLent;
  Book();
  java.lang.String describe();
  boolean isOlderThan(int);
  void lend();
  void rename(java.lang.String);
}
```

**A method's name and the types of its parameters are its signature**: `isOlderThan(int)`,
`rename(java.lang.String)`. The parameter's name is not part of it, and nor is the return type. A
call must match the signature, and the result can only be used as the type the method declares.
Break either and the program does not compile:

```java
// WrongCall.java
public class WrongCall {
    public static void main(String[] args) {
        Book b = new Book();
        boolean old = b.isOlderThan("1900");
        String nothing = b.lend();
    }
}
```

```
ana@vm:~/members$ javac WrongCall.java
WrongCall.java:5: error: incompatible types: String cannot be converted to int
        boolean old = b.isOlderThan("1900");
                                    ^
WrongCall.java:6: error: incompatible types: void cannot be converted to String
        String nothing = b.lend();
                               ^
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
2 errors
```

Two errors, each with a caret under the exact place. `"1900"` is a `String`, in quotes, and the
signature asks for an `int`. `lend()` declared `void`, so it has nothing to put into `nothing`. A
caller cannot pass the wrong thing or expect a result that is not there, and that is checked once,
at compile time, for every call in the program. Lesson 24 shows what happens when two methods share
a name and differ in their parameters.
