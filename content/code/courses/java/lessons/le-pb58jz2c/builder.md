---
title: The builder
version: 1
---

A loan needs a book and a member, and may have a period other than the usual 21 days and a note.
Constructors handle that badly. Either there is one constructor taking all four, and every caller
passes `21` and `""` for the parts it does not care about, or there are four constructors, one per
combination, and the next optional field doubles them. **A builder collects the parts one call at a
time, by name, and checks them together when you ask for the result.**

## The loan and its builder

In the same `~/fluent`:

```schooling-example
{
  "language": "java",
  "file": "Loan.java",
  "parts": [
    {
      "code": "public class Loan {\n    private final String book;\n    private final String member;\n    private final int days;\n    private final String note;",
      "note": "**The loan itself is immutable**: four `final` fields and no setters. Once built, nothing changes it."
    },
    {
      "code": "\n    private Loan(Builder b) {\n        this.book = b.book;\n        this.member = b.member;\n        this.days = b.days;\n        this.note = b.note;\n    }",
      "note": "The constructor is `private`, and its only argument is a builder. The one way to make a `Loan` is through the builder, so the checks in `build()` cannot be skipped."
    },
    {
      "code": "\n    public static Builder of(String book) {\n        return new Builder(book);\n    }",
      "note": "The entry point. The book is required, so it is the argument here and cannot be forgotten."
    },
    {
      "code": "\n    @Override\n    public String toString() {\n        return book + \" to \" + member + \" for \" + days + \" days\" + (note.isEmpty() ? \"\" : \" (\" + note + \")\");\n    }",
      "note": "How a loan prints, with the note only when there is one."
    },
    {
      "code": "\n    public static class Builder {\n        private final String book;\n        private String member;\n        private int days = 21;\n        private String note = \"\";\n\n        private Builder(String book) {\n            this.book = book;\n        }",
      "note": "**The builder is a static nested class** (lesson 17), holding the same fields as the loan, but not `final`. The two optional ones start at their defaults: 21 days and no note."
    },
    {
      "code": "\n        public Builder to(String member) {\n            this.member = member;\n            return this;\n        }\n\n        public Builder days(int days) {\n            this.days = days;\n            return this;\n        }\n\n        public Builder note(String note) {\n            this.note = note;\n            return this;\n        }",
      "note": "One method per optional part, each returning `this`. The caller sets the parts it cares about, in any order, and skips the rest."
    },
    {
      "code": "\n        public Loan build() {\n            if (member == null) {\n                throw new IllegalStateException(\"a loan needs a member: \" + book);\n            }\n            if (days < 1 || days > 60) {\n                throw new IllegalStateException(\"days out of range: \" + days);\n            }\n            return new Loan(this);\n        }\n    }\n}",
      "note": "**`build()` is where every rule is checked, once, with all the parts in view.** A loan without a member, or for an impossible period, never comes into existence."
    }
  ]
}
```

The builder's methods read like a description of the loan, and its rule-keeping happens in one
place. Two loans and one mistake:

```java
// Lending.java
public class Lending {
    public static void main(String[] args) {
        Loan plain = Loan.of("Iracema").to("Ana").build();
        Loan dvd = Loan.of("Central do Brasil").to("Bruno").days(7).note("DVD").build();
        System.out.println(plain);
        System.out.println(dvd);
        Loan broken = Loan.of("O Guarani").days(14).build();
    }
}
```

```
ana@vm:~/fluent$ javac Loan.java Lending.java && java Lending
Iracema to Ana for 21 days
Central do Brasil to Bruno for 7 days (DVD)
Exception in thread "main" java.lang.IllegalStateException: a loan needs a member: O Guarani
	at Loan$Builder.build(Loan.java:50)
	at Lending.main(Lending.java:8)
ana@vm:~/fluent$ ls Loan*.class
Loan$Builder.class
Loan.class
```

The first loan took the defaults; the second set two optional parts by name, and there is no doubt
which number is the period. The third forgot `to(...)`, and **the mistake stopped the program at
`build()`**, with a message naming the book, before any half-made loan could be stored or printed.
The stack trace names the builder as `Loan$Builder`, and `ls` shows why: a nested class compiles to
a class file of its own, named after the outer class with a `$` in between, as lesson 17 showed.

## When a builder is worth it

A builder is a second class with every field written twice, so it has to earn its place:

| situation | what to write |
|---|---|
| two or three fields, all required | a constructor, or lesson 29's `record` |
| several optional fields with sensible defaults | a builder |
| rules that involve more than one field at once | a builder, with the rules in `build()` |
| an object that must never change after it is made | either, with no setters on the result |

The builder in the JDK you are most likely to meet is `StringBuilder`, whose `toString()` plays the
part of `build()`. The `java-back` course meets many more, because HTTP requests and database
queries have exactly this shape: a few required parts and a long tail of optional ones.
