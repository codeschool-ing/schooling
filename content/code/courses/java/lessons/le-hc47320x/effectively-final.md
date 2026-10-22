---
title: Effectively final, the rule with no keyword
version: 1
---

Java can put a piece of code inside another and run it later. Lesson 17 introduces the first form,
the **anonymous class**, and the `java-functional` course the second, the **lambda**. Both may read
the local variables around them, with one condition, and the condition is the reason this lesson
mentions them at all. In a new directory, `~/capture`:

```java
// Capture.java
public class Capture {
    public static void main(String[] args) {
        String branch = "Centro";
        Runnable report = new Runnable() {
            public void run() {
                System.out.println("Report for " + branch);
            }
        };
        report.run();
    }
}
```

```
ana@vm:~/capture$ javac Capture.java && java Capture
Report for Centro
```

Read `new Runnable() { ... }` as "an object whose `run` method is this code". The code inside reads
`branch`, a local variable of `main`, and printed it. Now change `branch` after the object is made:

```java
// Capture.java
public class Capture {
    public static void main(String[] args) {
        String branch = "Centro";
        Runnable report = new Runnable() {
            public void run() {
                System.out.println("Report for " + branch);
            }
        };
        branch = "Norte";
        report.run();
    }
}
```

```
ana@vm:~/capture$ javac Capture.java
Capture.java:7: error: local variables referenced from an inner class must be final or effectively final
                System.out.println("Report for " + branch);
                                                   ^
1 error
```

**A variable is *effectively final* when nothing assigns it after its declaration**, even though
nobody wrote `final`. The first `Capture` qualified; the second assigned `branch` again and did not.
A lambda, the arrow form, meets exactly the same rule:

```java
// Lambda.java
public class Lambda {
    public static void main(String[] args) {
        int count = 0;
        Runnable add = () -> System.out.println(count + 1);
        count = 5;
        add.run();
    }
}
```

```
ana@vm:~/capture$ javac Lambda.java
Lambda.java:5: error: local variables referenced from a lambda expression must be final or effectively final
        Runnable add = () -> System.out.println(count + 1);
                                                ^
1 error
```

## Why the rule exists

The code inside may run long after `main` has moved on, or after it has returned and its frame is gone,
which lesson 12 drew. So the object does not keep a link to the variable; **it keeps a copy of the
value, taken when the object is made.** If the variable could change afterwards, the copy and the
variable would disagree, and `Report for Centro` would print after `branch` had become `Norte`.
Rather than let the two drift apart in silence, the compiler forbids the second assignment.

The rule is about the variable, not the object, exactly as in section 02. A captured `final`
`StringBuilder` can still be appended to from inside, because the copy is a copy of the reference.
When code inside needs a value that changes, give it an object to hold the value, and keep the
reference itself fixed.
