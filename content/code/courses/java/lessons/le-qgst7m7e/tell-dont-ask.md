---
title: Tell, don't ask
version: 1
---

Private fields with a getter each can still spread a class's knowledge all over a program. The
fields are safe; the **rules** about them are written in every caller that reads them. "Tell, don't
ask" is the habit that moves a rule back: instead of asking an object for its data and deciding
something with it, you tell the object what you need and let it decide.

## Asking

A loan with getters, and a caller that works out the late fee:

```java
// AskLoan.java
import java.time.LocalDate;

public class AskLoan {
    private final String title;
    private final LocalDate due;

    public AskLoan(String title, LocalDate due) {
        this.title = title;
        this.due = due;
    }

    public String getTitle() {
        return title;
    }

    public LocalDate getDue() {
        return due;
    }
}
```

```java
// AskDemo.java
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

public class AskDemo {
    public static void main(String[] args) {
        AskLoan loan = new AskLoan("Iracema", LocalDate.of(2026, 10, 9));
        LocalDate today = LocalDate.of(2026, 10, 12);
        long late = ChronoUnit.DAYS.between(loan.getDue(), today);
        long fee = late > 0 ? late * 50 : 0;
        System.out.println(loan.getTitle() + ": " + fee + " cents");
    }
}
```

```
ana@vm:~/encap$ javac AskLoan.java AskDemo.java && java AskDemo
Iracema: 150 cents
```

Three days late, fifty cents a day, 150 cents. The answer is right. The problem is where it was
worked out: **the fee rule is written in `AskDemo`**, and so is the guard that stops a loan returned
early from earning a negative fee. The receipt printer, the reminder e-mail and the member's account
page all need the same number, and each will write the same three lines, until one of them forgets
the `late > 0`.

## Telling

```schooling-example
{
  "language": "java",
  "file": "Loan.java",
  "parts": [
    {
      "code": "import java.time.LocalDate;\nimport java.time.temporal.ChronoUnit;\n\npublic class Loan {\n    private static final long FEE_PER_DAY_CENTS = 50;\n\n    private final String title;\n    private final LocalDate due;",
      "note": "**The rule's number lives in the class it belongs to**, as a constant: fifty cents a day. The fee is a count of cents in a `long`, never a `double`, for the reason lesson 8 gives."
    },
    {
      "code": "\n    public Loan(String title, LocalDate due) {\n        this.title = title;\n        this.due = due;\n    }",
      "note": "The constructor stores the two facts a loan is made of. There are no getters at all, because nothing outside needs the raw dates."
    },
    {
      "code": "\n    public long lateFeeCents(LocalDate today) {\n        long late = ChronoUnit.DAYS.between(due, today);\n        return late > 0 ? late * FEE_PER_DAY_CENTS : 0;\n    }",
      "note": "**The question the callers actually had, answered where the data is.** Days late times the daily fee, and zero for a loan that is not late yet, so a negative fee cannot be produced by anyone."
    },
    {
      "code": "\n    public String describe(LocalDate today) {\n        return title + \": \" + lateFeeCents(today) + \" cents\";\n    }\n}",
      "note": "A method built on the other one. The caller hands in today's date, so the class never reads the clock itself, and the same loan gives the same answer in a test on any day."
    }
  ]
}
```

```java
// TellDemo.java
import java.time.LocalDate;

public class TellDemo {
    public static void main(String[] args) {
        Loan loan = new Loan("Iracema", LocalDate.of(2026, 10, 9));
        System.out.println(loan.describe(LocalDate.of(2026, 10, 12)));
        System.out.println(loan.describe(LocalDate.of(2026, 10, 5)));
    }
}
```

```
ana@vm:~/encap$ javac Loan.java TellDemo.java && java TellDemo
Iracema: 150 cents
Iracema: 0 cents
```

The same 150 cents, and a loan checked before its due date gives 0. **Now the rule exists once**, in
the class that owns the dates, and every caller asks `lateFeeCents` instead of repeating it. The
dates themselves never leave the object, which is encapsulation doing the job it was meant for: the
day the library charges more for a weekend, one method changes.

## Where this stops

Not every class should hide its data. A class whose whole purpose is to carry values from one place
to another has nothing to decide: a row read from a file, say, or an answer sent over the network.
Wrapping it in behaviour would invent rules it does not have. **For data that is only
data, lesson 29's `record` is the right tool**, and its accessors are the honest kind: they exist
because reading the values is the point.

The question to ask of a getter is who calls it, and what they do with the answer. If every caller
does the same sum with it, the sum belongs inside, and the getter may not need to exist at all.
