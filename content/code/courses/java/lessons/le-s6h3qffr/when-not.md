---
title: When a record is the wrong tool
version: 1
---

Once records are familiar, every class starts to look like one. **A record is right for a value,
and wrong for a thing that changes while it keeps being the same thing.** The difference shows in
what the compiler will not let a record do.

A loan has a book and a member, and a due date that moves when the member renews it. The obvious
attempt adds the due date as an ordinary field:

```java
// Loan.java
record Loan(String isbn, String member) {
    private String dueDate;
}
```

```
ana@vm:~/records/not$ javac Loan.java
Loan.java:3: error: field declaration must be static
    private String dueDate;
                   ^
  (consider replacing field with record component)
1 error
```

**A record has no instance fields beyond its components**, and the message suggests the only way
in: make it a component. Static fields are allowed, and so are methods, static and instance, nested
types and implemented interfaces. What a record may not have is state that is not in its header,
because `equals`, `hashCode` and `toString` are built from the header, and a hidden field would make
two "equal" loans different.

Nor can a record join a class hierarchy:

```java
// Special.java
record Item(String title) {
}

record Book(String title, int pages) extends Item {
}
```

```
ana@vm:~/records/not$ javac Special.java
Special.java:5: error: '{' expected
record Book(String title, int pages) extends Item {
                                    ^
1 error
```

The compiler stops at `extends`, because a record already extends `java.lang.Record` and the syntax
has no room for anything else. **A record can implement interfaces, which section 04 used, and can
neither extend nor be extended**, since it is `final`.

## A value, or a thing with a life

Put the loan back together as a component, `record Loan(String isbn, String member, LocalDate
dueDate)`, and it compiles. Renewing it now means making a new `Loan` with a later date, and the old
one still exists, unchanged. Two loans with the same book, member and date are `equals`, so the
library cannot tell this week's loan from an identical one taken last year and returned.

For an ISBN that is exactly right: two equal ISBNs *are* the same ISBN. For a loan it is wrong,
because a loan has an **identity** that outlives its values. It is the same loan before and after a
renewal, and a different loan from last year's even if every field matches. That calls for lesson
22's class: private fields, methods that change them while keeping the rules, and an id of its own.

A short test settles most cases:

| ask | record | class |
|---|---|---|
| are two with equal fields the same thing? | yes: an ISBN, a date range, a price | no: a loan, a member, an account |
| does it change after it is built? | never; a change is a new value | yes, through its own methods |
| does it need a superclass? | it cannot have one | it may |

Frameworks that build objects for you, such as the database mappers `java-back` meets, often want an
object they can create empty and fill in field by field. A record cannot be that object; the two are
built for different jobs. Use records for the data that travels between
the pieces, and classes for the things the pieces keep.
