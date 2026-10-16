---
title: `super`, and the class every class extends
version: 1
---

Section 02's `Dvd` replaced `loanDays()` outright. More often a subclass wants the parent's
behaviour **plus** something: the same description, with the running time on the end. Rewriting
`Item.describe()` inside `Dvd` would copy it, and the copy would drift. **`super.method()` calls the
superclass's version from inside an override**, so the subclass adds to it instead.

Replace `Dvd.java` with this version, which overrides `describe()` as well:

```java
// Dvd.java
public class Dvd extends Item {
    private final int minutes;

    public Dvd(String title, int year, int minutes) {
        super(title, year);
        this.minutes = minutes;
    }

    @Override
    public int loanDays() {
        return 7;
    }

    @Override
    public String describe() {
        return super.describe() + ", " + minutes + " minutes";
    }
}
```

`super.describe()` runs `Item`'s `describe()` on this same DVD object, and the result gets
`, 153 minutes` added to it. Notice what `super.describe()` itself still calls: `loanDays()`, and on a
DVD that is the overriding one, so the line will say 7 days. `super` chooses which `describe()` runs,
and does not change which object it runs on.

## Every class has a parent

`Item` says nothing about a superclass. **A class that does not say `extends` extends
`java.lang.Object`**, so every class in Java sits under one root. A short program walks up from
`Book`, then tries three things `Book` never declared:

```java
// Chain.java
public class Chain {
    public static void main(String[] args) {
        Class<?> c = Book.class;
        while (c != null) {
            System.out.println(c.getName());
            c = c.getSuperclass();
        }
        Book a = new Book("Effective Java", 2018, "Joshua Bloch");
        Book b = new Book("Effective Java", 2018, "Joshua Bloch");
        System.out.println(a.equals(b) + " " + (a.hashCode() == b.hashCode()));
        System.out.println(a);
        System.out.println(new Dvd("Metropolis", 1927, 153).describe());
    }
}
```

```
ana@vm:~/inherit$ javac *.java && java Chain
Book
Item
java.lang.Object
false false
Book@7ad041f3
Metropolis (1927), 7 days, 153 minutes
```

The first three lines are the chain: `Book`, `Item`, `java.lang.Object`, and then `getSuperclass()`
returned `null`, because `Object` has no parent. Everything `Object` declares, every object has. Three
of those methods matter in every lesson from here on, and two of them just misbehaved:

| method | what `Object`'s version does | what it did here |
|---|---|---|
| `toString()` | the class name, `@`, and a number derived from the object's identity | printed `Book@7ad041f3`; the number differs on every run |
| `equals(Object)` | the same as `==`: true only for the very same object | `a.equals(b)` was `false` for two books with identical fields |
| `hashCode()` | a number derived from the object's identity | different for `a` and `b` |

**Two `Book` objects with the same title, year and author are not equal, as far as `Object` is
concerned.** That is the right default for something like a member card, where identity is the
point, and the wrong one for a value like an ISBN. A class that means value equality has to override
`equals` and `hashCode` together, and lesson 24 shows what goes wrong when only one is done, or when
it is done with the wrong signature. Lesson 29's records write all three for you. The last line is
the new `Dvd`, describing itself with its own days and its parent's words.
