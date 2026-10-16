---
title: The variable holds a reference, not the object
version: 1
---

The natural reading of `Book a = new Book();` is that `a` is a book. **It is not.** `a` holds a
**reference**: a value that leads to one object, the way an address leads to a house. The object is
somewhere else. Almost every surprise in Java's object model comes from forgetting that, and this
program produces three of them:

```java
// Refs.java
public class Refs {
    public static void main(String[] args) {
        Book a = new Book();
        a.title = "Dom Casmurro";
        Book b = a;
        b.title = "Memorial de Aires";
        System.out.println(a.title);
        System.out.println(a == b);

        Book c = new Book();
        c.title = "Memorial de Aires";
        System.out.println(a == c);
        System.out.println(a.title.equals(c.title));

        Book none = null;
        System.out.println(none.title);
    }
}
```

It uses the `Book` class from section 02, which `javac` finds in the same directory:

```
ana@vm:~/objects$ javac Refs.java && java Refs
Memorial de Aires
true
false
true
Exception in thread "main" java.lang.NullPointerException: Cannot read field "title" because "<local4>" is null
	at Refs.main(Refs.java:17)
```

## Assignment copies the reference

`Book b = a;` did not copy the book. It copied the reference, so `a` and `b` lead to **the same
object**, and setting `b.title` changed what `a.title` reads. The first line printed is the title
set through `b`. There was only ever one `new` before that line, so there was only ever one book.

## `==` asks whether two references lead to one object

`a == b` is `true` because both lead to the same object. `a == c` is `false` even though `c` holds
the same title: `c` came from a second `new`, so it is a second object. **For references, `==`
compares identity, never contents.** To compare contents you ask the objects, with a method;
`a.title.equals(c.title)` compared the two strings character by character and said `true`. Lesson 7
met the same rule for strings, and lesson 24 writes an `equals` for `Book` itself.

## `null` is a reference to nothing

`none` holds `null`, the reference that leads nowhere, and `none.title` asks for a field of an object
that does not exist. The JVM stops with a `NullPointerException`. **Read its message to the end**:
it names the field it tried to read, `title`, and the variable that was `null`.

Here the variable is called `<local4>`, which is not a name anybody wrote. By default `javac` keeps
no local variable names in the class file, so the JVM can only number them: `args` is 0, `a` 1, `b`
2, `c` 3 and `none` 4. Compile with `-g` and the names are kept:

```
ana@vm:~/objects$ javac -g Refs.java && java Refs
Memorial de Aires
true
false
true
Exception in thread "main" java.lang.NullPointerException: Cannot read field "title" because "none" is null
	at Refs.main(Refs.java:17)
```

Maven compiles with that information by default, from lesson 18 on, so the messages you meet at work
name the variable. The last line, `Refs.java:17`, is the line of the source that failed in both
runs. Lesson 36 reads stack traces properly.
