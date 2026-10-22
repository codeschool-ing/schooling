---
title: What an abstract class still has, and when to write one
version: 1
---

"Cannot be instantiated" is easy to read as "is not really a class". **An abstract class is a full
class that is missing a few bodies**: it has fields, constructors, private methods and concrete
ones, and every subclass object carries all of it. `javap` shows `Loanable` as the compiler left it:

```
ana@vm:~/abstract/fees$ javap -p Loanable
Compiled from "Loanable.java"
public abstract class Loanable {
  private final java.lang.String title;
  protected Loanable(java.lang.String);
  public final int lateFeeCents(int);
  protected abstract int dailyFeeCents();
  protected int maximumFeeCents();
  public java.lang.String title();
}
```

A private field, a constructor, three methods with bodies and one without, marked `abstract`. The
class itself is `public abstract class`, and that one word is the whole difference in the file.

## A constructor nobody can call with `new`

`Loanable` has a constructor, and `new Loanable(...)` is forbidden. The constructor exists for its
subclasses: **every `Book` and `Dvd` runs it through `super(title)`**, which is how `title` gets its
value whichever subclass is created. Declaring it `protected` says that out loud, since nothing but a
subclass can use it anyway.

There is one more way to get a `Loanable`, and it is lesson 17's. An anonymous class can extend an
abstract class as easily as it implements an interface, supplying the missing bodies in its braces.
Save this in `~/abstract/fees` too:

```java
// Special.java
public class Special {
    public static void main(String[] args) {
        Loanable map = new Loanable("Map of Lisbon, 1755") {
            @Override
            protected int dailyFeeCents() {
                return 500;
            }
        };
        System.out.println(map.title() + ": " + map.lateFeeCents(10) + " cents");
        System.out.println(map.getClass().getName() + " extends " + map.getClass().getSuperclass().getName());
    }
}
```

```
ana@vm:~/abstract/fees$ javac Special.java && java Special
Map of Lisbon, 1755: 2000 cents
Special$1 extends Loanable
```

`new Loanable("Map of Lisbon, 1755") { ... }` passed the title to the constructor, wrote
`dailyFeeCents()` in the braces, and created the one object of that class. Ten days at 5.00 would be
5000 cents, and the inherited maximum held it to 2000. The class is called `Special$1`, and its
superclass is `Loanable`: still not an object of the abstract class itself, but of a nameless
concrete subclass made on the spot.

## Abstract class or not

Write an abstract class when **several classes share state and code, and the shared code needs
something only they can supply**. `Loanable` fits: every item has a title, and the fee rule needs a
daily rate. Two other shapes are more common than people expect, and neither needs one:

- **Every subclass is the same apart from data.** If a book and a DVD differed only in their daily
  fee, that number could be a field set by a constructor, and one concrete class would do. An abstract
  method earns its place when the subclasses run different *code*.
- **Only behaviour is shared, no state.** A promise of methods with no fields behind them is what
  an **interface** is for, and a class can implement several interfaces while it can extend only one
  class. Lesson 23 is about interfaces, and Java's own library uses the two together: the interface
  `List` is the promise, and the abstract class `AbstractList` is a partial implementation for
  anybody writing a list of their own.

**The test is the sentence from lesson 20, with one word added**: every `Dvd` *is a kind of*
`Loanable`, and a `Loanable` that is no particular kind of thing makes no sense. When both halves are
true, the class is abstract.
