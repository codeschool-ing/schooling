---
title: Why private is the sensible default
version: 1
---

The obvious reason to make a field private is secrecy, and it is the wrong one: anybody who can read
the source can read the field's name. **The reason is that a class can only keep a promise about data
that nobody else can change.** A library's rule is simple. A loan may be renewed twice, and the third
request is refused. In a new directory, `~/loans`, here is that rule with an open field:

```java
// OpenLoan.java
class OpenLoan {
    int renewals;

    boolean renew() {
        if (renewals == 2) {
            return false;
        }
        renewals = renewals + 1;
        return true;
    }
}
```

`renew()` enforces the rule correctly, and nothing makes anybody call it:

```java
// OpenMain.java
public class OpenMain {
    public static void main(String[] args) {
        OpenLoan loan = new OpenLoan();
        System.out.println(loan.renew() + " " + loan.renew() + " " + loan.renew());
        loan.renewals = 0;
        System.out.println(loan.renew() + " " + loan.renewals);
        loan.renewals = 7;
        System.out.println(loan.renew() + " " + loan.renewals);
    }
}
```

```
ana@vm:~/loans$ javac OpenMain.java && java OpenMain
true true false
true 1
true 8
```

The first line is the rule working: two renewals, then a refusal. Then one assignment set the count
back to zero and the loan could be renewed again, and another set it to 7, after which `renew()`
said `true` and the count reached 8. **The check `renewals == 2` never fires once the count has
jumped past 2**, so the loan can now be renewed for ever. Nothing failed, nothing printed a warning,
and the rule is broken in every program that has one stray assignment, anywhere.

## The same class, with the field closed

```java
// Loan.java
class Loan {
    private int renewals;

    boolean renew() {
        if (renewals == 2) {
            return false;
        }
        renewals = renewals + 1;
        return true;
    }

    int renewals() {
        return renewals;
    }
}
```

Two changes. The field is `private`, and a method `renewals()` lets other classes **read** the count
without being able to write it. A program that uses the loan the way it is meant to be used works as
before:

```java
// LoanMain.java
public class LoanMain {
    public static void main(String[] args) {
        Loan loan = new Loan();
        System.out.println(loan.renew() + " " + loan.renew() + " " + loan.renew());
        System.out.println(loan.renewals());
    }
}
```

And one that tries the shortcut does not compile:

```java
// Cheat.java
public class Cheat {
    public static void main(String[] args) {
        Loan loan = new Loan();
        loan.renewals = 0;
    }
}
```

```
ana@vm:~/loans$ javac LoanMain.java && java LoanMain
true true false
2
ana@vm:~/loans$ javac Cheat.java
Cheat.java:5: error: renewals has private access in Loan
        loan.renewals = 0;
            ^
1 error
```

**Now the only code that can change `renewals` is the code inside `Loan`**, and all of it is on the
screen at once. To know whether the rule holds you read one class, not the whole program. That is
what *encapsulation* means, and lesson 22 takes it further.

## Start from private, and open what you must

The rule of thumb is to declare every field `private` and every method as closed as it can be, then
open a member only when another class has a reason to use it. A modifier that is too strict costs
one compile error, at the moment somebody needs more, which is the moment to think about it. A
modifier that is too loose costs nothing on the day it is written, and is very hard to tighten later,
because by then other code depends on it, and some of that code is not yours to change.
