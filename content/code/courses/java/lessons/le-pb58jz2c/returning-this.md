---
title: A method that returns this
version: 1
---

A **fluent interface** is a class designed so that calls on it can be chained into one expression
that reads almost like a sentence. There is no special syntax behind it. **Each method returns an
object, and the next call is made on whatever came back.** When the object that comes back is the
same one, the chain keeps working on it.

## The one you already know

`StringBuilder.append` returns the builder it was called on, so in `~/fluent`:

```java
// Chains.java
public class Chains {
    public static void main(String[] args) {
        StringBuilder note = new StringBuilder()
                .append("loan ")
                .append(42)
                .append(": due ")
                .append("2026-10-12");
        System.out.println(note);
    }
}
```

```
ana@vm:~/fluent$ javac Chains.java && java Chains
loan 42: due 2026-10-12
```

Four calls, one object. Each `append` added its piece and handed back `this`, and the next `append`
was called on it. Split over separate statements, the same code would name the variable four times
and say nothing more.

## Writing one

The library's receipt adds lines, keeps a total, and returns itself from `line`:

```java
// Receipt.java
import java.util.ArrayList;
import java.util.List;

public class Receipt {
    private final List<String> lines = new ArrayList<>();
    private long totalCents;

    public Receipt line(String what, long cents) {
        lines.add(what + ": " + cents + " cents");
        totalCents += cents;
        return this;
    }

    public String print() {
        return String.join("\n", lines) + "\ntotal: " + totalCents + " cents";
    }
}
```

```java
// ReceiptDemo.java
public class ReceiptDemo {
    public static void main(String[] args) {
        String text = new Receipt()
                .line("late fee, Iracema", 150)
                .line("replacement card", 500)
                .print();
        System.out.println(text);
    }
}
```

```
ana@vm:~/fluent$ javac Receipt.java ReceiptDemo.java && java ReceiptDemo
late fee, Iracema: 150 cents
replacement card: 500 cents
total: 650 cents
```

**`return this;` is the whole technique.** `line` changes the receipt and gives back the same
receipt, so `ReceiptDemo` can call `line` again, and then `print`, which ends the chain by returning
a `String` instead. The receipt never has a name in `ReceiptDemo`: it is created, filled and printed
inside one expression.

## Where the chain breaks

A setter in the JavaBeans style of lesson 22 returns `void`, and there is nothing to call the next
method on:

```java
// Card.java
public class Card {
    private String name;
    private int number;

    public void setName(String name) {
        this.name = name;
    }

    public void setNumber(int number) {
        this.number = number;
    }
}
```

```java
// CardDemo.java
public class CardDemo {
    public static void main(String[] args) {
        Card card = new Card();
        card.setName("Ana").setNumber(1042);
    }
}
```

```
ana@vm:~/fluent$ javac Card.java CardDemo.java
CardDemo.java:5: error: void cannot be dereferenced
        card.setName("Ana").setNumber(1042);
                           ^
1 error
```

`void cannot be dereferenced` means "the expression to the left of this dot has no value". The fix is
not to make every setter return `this`: the JDK's own `java.beans` introspection recognises a setter
only when it returns `void`, and tools built on it miss the others. **Chaining is a design for a class whose whole purpose is to be configured in
one go**, like a receipt or a query, and the clearest such design is the builder in section 03.
