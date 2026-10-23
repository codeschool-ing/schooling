---
title: Overriding, decided by the object
version: 1
---

**Overriding is a subclass replacing a method it inherited**, with the same name and the same
parameter types. Overloading added methods beside each other in one class; overriding puts a new
body in place of an old one, one level down. Which body runs is decided by the object, while the
program runs, which lesson 25 takes apart.

## An override, and the annotation that checks it

In `~/overload/override`, a parent class:

```java
// Item.java
public class Item {
    protected final String title;

    public Item(String title) {
        this.title = title;
    }

    public String describe() {
        return "item " + title;
    }

    public Item copy() {
        return new Item(title);
    }
}
```

And a subclass that overrides both of its methods:

```schooling-example
{
  "language": "java",
  "file": "Book.java",
  "parts": [
    {
      "code": "public class Book extends Item {\n    public Book(String title) {\n        super(title);\n    }",
      "note": "`Book` extends `Item` and passes the title up to `Item`'s constructor with `super`, as lesson 20 showed."
    },
    {
      "code": "\n    @Override\n    public String describe() {\n        return \"book \" + title;\n    }",
      "note": "**An override: same name, same parameters, same return type.** `@Override` asks the compiler to confirm that `Item` really has a `describe()` for this one to replace."
    },
    {
      "code": "\n    @Override\n    public Book copy() {\n        return new Book(title);\n    }\n}",
      "note": "**A covariant return.** `Item.copy()` returns an `Item`; the override may narrow that to `Book`, because a `Book` is an `Item` and every caller of the old signature still gets what it was promised."
    }
  ]
}
```

The rules for an override are short, and the compiler enforces each one:

| | the override must | example |
|---|---|---|
| name and parameters | be exactly the same | `describe()`, no parameters |
| return type | be the same, or a subtype of it | `Book copy()` for `Item copy()` |
| access | be the same, or wider | `public` stays `public` |
| `static`, `final` and `private` methods | cannot be overridden at all | lesson 25 shows what happens instead |

## One letter wrong

Now a subclass whose author meant to override `describe` and typed `descibe`:

```java
// Typo.java
public class Typo extends Item {
    public Typo(String title) {
        super(title);
    }

    public String descibe() {
        return "typo " + title;
    }
}
```

```java
// Counter.java
public class Counter {
    public static void main(String[] args) {
        Book copy = new Book("Iracema").copy();
        System.out.println(copy.describe());
        Item typo = new Typo("Dom Casmurro");
        System.out.println(typo.describe());
    }
}
```

```
ana@vm:~/overload/override$ javac *.java && java Counter
book Iracema
item Dom Casmurro
```

The book's override ran and printed `book Iracema`. The typo did not fail anywhere. **`descibe` is a
new method that nobody calls**, so `Typo` inherited `Item`'s `describe` untouched and printed
`item Dom Casmurro`. The compiler had no way to know the author's intent, because adding a new
method is perfectly legal.

`@Override` is how the intent gets written down:

```java
// Typo.java
public class Typo extends Item {
    public Typo(String title) {
        super(title);
    }

    @Override
    public String descibe() {
        return "typo " + title;
    }
}
```

```
ana@vm:~/overload/override$ javac Typo.java
Typo.java:7: error: method does not override or implement a method from a supertype
    @Override
    ^
1 error
```

**With the annotation, the typo is a compile error on the right line.** That is the whole purpose of
`@Override`: it changes nothing about the code that runs, and it turns "I meant to replace a method"
from a hope into something the compiler checks. Put it on every override. Lesson 39 looks at annotations as a
whole.

## Narrowing access is refused

```java
// Quiet.java
public class Quiet extends Item {
    public Quiet(String title) {
        super(title);
    }

    @Override
    protected String describe() {
        return "quiet " + title;
    }
}
```

```
ana@vm:~/overload/override$ javac Quiet.java
Quiet.java:8: error: describe() in Quiet cannot override describe() in Item
    protected String describe() {
                     ^
  attempting to assign weaker access privileges; was public
1 error
```

An override may make a method more visible and never less. Code holding an `Item` is entitled to
call `describe()`, because `Item` says it is public; if a subclass could make it `protected`, that
promise would break for every `Item` that turned out to be a `Quiet`. So the compiler refuses, and
says what the access used to be: `was public`.
