---
title: Three habits that keep a failure visible
version: 1
---

An exception is the program telling somebody that it could not do what it was asked. Most of the
damage done with exceptions is done by code that stops that message from arriving, and **the worst
failure is the one that produces a plausible wrong answer and no message at all**. Three habits
prevent most of it.

## Never swallow an exception

The ledger below lists the fines three members owe, in cents. The second line has a typo: the letter
`O` where a zero should be. The `catch` block is empty, which is the shortest way to make a compiler
error about a checked exception go away, and here it is catching an unchecked one for no reason at
all:

```java
// Fines.java
import java.util.List;

public class Fines {
    public static void main(String[] args) {
        List<String> lines = List.of("ana 250", "rui 1O0", "eva 100");
        int total = 0;
        for (String line : lines) {
            try {
                total += Integer.parseInt(line.split(" ")[1]);
            } catch (NumberFormatException e) {
            }
        }
        System.out.println("fines owed, in cents: " + total);
    }
}
```

```
ana@vm:~/hierarchy$ javac Fines.java FinesLoud.java Flow.java && java Fines
fines owed, in cents: 350
```

**350 cents, printed with complete confidence.** Rui's fine vanished, nothing on the screen says so,
and the program ended as if all were well. A person reading the total has no way to know it is wrong, and
the next program to use it inherits the mistake. An empty `catch` turns a failure that had a name, a
message and a line number into a wrong number.

If a failure really may be ignored, the block says so in a comment that gives the reason, so the next
reader can disagree with it. "It is not fatal" is not a reason; what would go wrong, and why that
is acceptable here, is.

## Wrap with context, and keep the cause

The second habit is to add what only this layer knows. `Integer.parseInt` knows the string it was
given. It does not know the string came from line 2 of a fines ledger. The loop does, so the loop
catches, adds that, and throws again with the original as the cause:

```java
// FinesLoud.java
import java.util.List;

public class FinesLoud {
    public static void main(String[] args) {
        List<String> lines = List.of("ana 250", "rui 1O0", "eva 100");
        int total = 0;
        for (int i = 0; i < lines.size(); i++) {
            String field = lines.get(i).split(" ")[1];
            try {
                total += Integer.parseInt(field);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException(
                        "line " + (i + 1) + ": the fine is not a number of cents: " + field, e);
            }
        }
        System.out.println("fines owed, in cents: " + total);
    }
}
```

```
ana@vm:~/hierarchy$ java FinesLoud
Exception in thread "main" java.lang.IllegalArgumentException: line 2: the fine is not a number of cents: 1O0
	at FinesLoud.main(FinesLoud.java:13)
Caused by: java.lang.NumberFormatException: For input string: "1O0"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at FinesLoud.main(FinesLoud.java:11)
```

The top line is now enough to fix the data without opening the code: **which line, which field, what
it should have been, and the value that was there**. The `Caused by:` keeps the JDK's own report,
`For input string: "1O0"`, for whoever needs it. Throwing stops the loop, so no total is printed at
all, which is right: no total is better than a wrong one.

Wrapping is for adding information. A `catch` that throws a new exception with the same message and
no cause is worse than no `catch`, because it throws away the original's stack trace.

## Exceptions are not control flow

The third habit is about the opposite mistake: throwing on purpose, as a way to leave a loop.

```java
// Flow.java
public class Flow {
    public static void main(String[] args) {
        int[] fines = {250, 100, 75};
        int total = 0;
        try {
            for (int i = 0; ; i++) {
                total += fines[i];
            }
        } catch (ArrayIndexOutOfBoundsException e) {
            System.out.println("total " + total);
        }
    }
}
```

```
ana@vm:~/hierarchy$ java Flow
total 425
```

The answer is right, 425. The code still hides its intent: the loop has no condition, and the reader
has to find the `catch` to learn where it ends. And the `catch` cannot tell the end it expected from a
real bug: if a later change indexed `fines[i + 1]`, the same exception would fire one element early
and print a wrong total with no complaint. **An exception says something unexpected happened**, and a
loop reaching the end of an array is the most expected thing in the program. `for (int fine : fines)`
from lesson 11 says it in one line.

The same goes for using an exception to answer an ordinary question: whether a string is a number is
asked by validating the input where it enters the program, and an exception is what happens when
something gets past that check.
