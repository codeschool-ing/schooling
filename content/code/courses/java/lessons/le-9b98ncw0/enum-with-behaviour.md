---
title: Constants that carry data and behaviour
version: 1
---

Section 02's `Genre` was four names. Real values carry more than a name: a kind of loan has a length
in days and a late fee, and code that needs those tends to grow a `switch` in every method that asks.
**Because an enum is a class, each constant can carry its own fields and answer its own methods**,
and the `switch` disappears into the type.

A library lends books on three terms. Money is in integer cents, as everywhere on this platform:

```schooling-example
{
  "language": "java",
  "file": "Loans.java",
  "parts": [
    {
      "code": "enum LoanType {\n    STANDARD(14, 50),\n    SHORT(3, 200),\n    REFERENCE(0, 0) {\n        @Override\n        long feeCents(int daysLate) {\n            throw new UnsupportedOperationException(\"reference books stay in the library\");\n        }\n    };",
      "note": "**Each constant is written with arguments, and each argument list is a constructor call.** `STANDARD(14, 50)` builds the `STANDARD` object with a 14-day loan and 50 cents a day late. `REFERENCE` adds a body in braces: a constant-specific class body, which overrides a method for that one constant. The semicolon after the last constant ends the list, and is required once anything follows it."
    },
    {
      "code": "\n    private final int days;\n    private final int centsPerDay;",
      "note": "**Fields, as in any class.** `private final`, because a constant is shared by the whole program and nothing should be able to change it."
    },
    {
      "code": "\n    LoanType(int days, int centsPerDay) {\n        this.days = days;\n        this.centsPerDay = centsPerDay;\n    }",
      "note": "**The constructor is private by rule**, written with no modifier or with `private`, and never called with `new`. The JVM calls it once per constant, from the class initialiser."
    },
    {
      "code": "\n    int days() {\n        return days;\n    }",
      "note": "An ordinary method, which every constant answers from its own fields."
    },
    {
      "code": "\n    long feeCents(int daysLate) {\n        return (long) daysLate * centsPerDay;\n    }\n}",
      "note": "**A method with a default answer**, which `REFERENCE` replaces. The `(long)` cast makes the multiplication happen in `long`, so a large number of days cannot overflow an `int` (lesson 6)."
    },
    {
      "code": "\npublic class Loans {\n    public static void main(String[] args) {\n        for (LoanType t : LoanType.values()) {\n            System.out.println(t + \": \" + t.days() + \" days\");\n        }\n        System.out.println(\"SHORT, 4 days late: \" + LoanType.SHORT.feeCents(4) + \" cents\");\n        System.out.println(LoanType.SHORT.getClass());\n        System.out.println(LoanType.REFERENCE.getClass());\n        LoanType.REFERENCE.feeCents(1);\n    }\n}",
      "note": "`main` lists the constants, charges a late fee, prints the class of two constants, and finally asks `REFERENCE` for a fee."
    }
  ]
}
```

In `~/enums/loans`:

```
ana@vm:~/enums/loans$ javac Loans.java && java Loans
STANDARD: 14 days
SHORT: 3 days
REFERENCE: 0 days
SHORT, 4 days late: 800 cents
class LoanType
class LoanType$1
Exception in thread "main" java.lang.UnsupportedOperationException: reference books stay in the library
	at LoanType$1.feeCents(Loans.java:7)
	at Loans.main(Loans.java:36)
ana@vm:~/enums/loans$ ls *.class
LoanType$1.class
LoanType.class
Loans.class
```

**`SHORT.feeCents(4)` is 800**, four days at 200 cents, computed from fields the constant was built
with. A new kind of loan is one more line in the list, with its numbers, and no method anywhere
else has to change. Compare that with the alternative: `int days(String type)` with a `switch`
inside, `long feeCents(String type, int daysLate)` with another, and a new type that has to be
added to both.

## One constant, its own class

`STANDARD` and `SHORT` are objects of `LoanType`. **`REFERENCE` is an object of `LoanType$1`**, an
anonymous subclass the compiler made for its body, and `ls` found its class file. The `$1` naming is
lesson 17's, for anonymous classes, and the stack trace names it too: the exception was thrown in
`LoanType$1.feeCents`, line 7, which is the `throw` inside `REFERENCE`'s braces.

This is the place for behaviour that is different for one or two constants. When **every** constant
would need its own body, it usually means the data belongs in fields instead, as `days` and
`centsPerDay` do here.

A reference book cannot be lent, so asking for its late fee is a mistake, and the method refuses
with an exception rather than returning 0. A 0 would be read as "no fee", and a report summing the
fees of every loan would be wrong without saying so. Lesson 36 is about exceptions; here it is
enough that the refusal is loud.

## What an enum cannot do

An enum cannot extend another class, because it already extends `java.lang.Enum`, and nothing can
extend an enum, because it is `final` (section 02's `javap`). It **can** implement interfaces, which
is lesson 23's subject, and that is how an enum takes part in a design that has other
implementations too.
