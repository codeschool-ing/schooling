---
title: Fields, and the value they start with
version: 1
---

A **field** is a variable that belongs to an object. Lesson 12 declared three on `Book` and set them
from `main`, one assignment at a time. Two things about fields were left unsaid there, and both
separate them from the local variables of lesson 5: **a field always starts with a value**, and
**each object has its own copy**.

Make a directory for sections 02 and 03, `~/members`, and save a library member with fields of five
different types:

```java
// Member.java
class Member {
    String name;
    int loans;
    double fines;
    boolean blocked;
    char tier;
    int maxLoans = 3;
}
```

The first five fields are declared and nothing more. The sixth, `maxLoans`, carries an **initialiser**,
`= 3`, which runs for every new member. A program that makes two members and prints what it finds:

```java
// Defaults.java
public class Defaults {
    public static void main(String[] args) {
        Member m = new Member();
        System.out.println(m.name);
        System.out.println(m.loans);
        System.out.println(m.fines);
        System.out.println(m.blocked);
        System.out.println((int) m.tier);
        System.out.println(m.maxLoans);

        Member other = new Member();
        other.maxLoans = 5;
        System.out.println(m.maxLoans + " " + other.maxLoans);
    }
}
```

```
ana@vm:~/members$ javac Defaults.java && java Defaults
null
0
0.0
false
0
3
3 5
```

**Every type has its default, and it is the zero of that type**:

| field type | default | printed as |
|---|---|---|
| any reference, such as `String` | `null` | `null` |
| `int`, `long`, `short`, `byte` | zero | `0` |
| `double`, `float` | zero | `0.0` |
| `boolean` | `false` | `false` |
| `char` | the character with code 0 | nothing visible, so the program printed its code |

The `(int)` before `m.tier` is a cast, from lesson 6. Printed as a character, code 0 is invisible,
and the line would have looked empty. As a number it shows what is really there.

**An initialiser beats the default, and assignment beats the initialiser.** `maxLoans` started at 3
for both members, because the initialiser ran for each. Then `other.maxLoans = 5` changed one of
them, and the last line shows that `m` kept its 3. The two members share the class and nothing else.

## Why fields get a default and locals do not

A local variable lives inside one method, and the compiler can read that whole method to check that
every path assigns it before it is read; lesson 5 showed the error when one does not. A field can be
set from anywhere, by any method, at any time, so no such check is possible. The JVM therefore
**clears the memory of every new object to zero** before anything else runs, and the zero of each
type is the table above. It is a safety rule, and it is also a trap: a `null` that nobody meant to
leave there looks exactly like a `null` somebody chose. Section 04 gives the class a way to make
sure every field is set.
