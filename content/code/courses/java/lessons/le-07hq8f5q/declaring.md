---
title: Declaring a variable, and giving it a value before you read it
version: 1
---

A variable is a name for a place that holds one value of one type. Declaring it says the name and
the type; assigning it puts a value there. In Java the two can happen on one line, `int daysLate =
3;`, or on two. **What Java will not allow is reading a local variable before it has certainly been
given a value**, and "certainly" is checked by the compiler, path by path, before the program ever
runs.

## "Might not have been initialized"

A fine of 50 cents a day, in `~/scope`, with a mistake in it:

```java
// Fine.java
public class Fine {
    public static void main(String[] args) {
        int daysLate = 3;
        int fine;
        if (daysLate > 0) {
            fine = daysLate * 50;
        }
        System.out.println(fine);
    }
}
```

```
ana@vm:~/scope$ javac Fine.java
Fine.java:9: error: variable fine might not have been initialized
        System.out.println(fine);
                           ^
1 error
```

Reading the program, you can see that `daysLate` is 3 and the `if` will run. **The compiler does not
reason about values**, only about paths through the code. There is a path on which the `if` does not
run, and on that path `fine` is printed with nothing ever put in it. Java calls the rule **definite
assignment**, and the fix is to give `fine` a value on every path: `int fine = 0;` at the
declaration, or an `else` that assigns it, which lesson 10 shows.

This is a feature you will be glad of. In C, the same program compiles and prints whatever happened
to be in that memory, which differs between runs and machines. In Java a local variable that has not
been assigned **cannot be read at all**, so the bug is caught where it is written.

## Fields get a default, locals do not

A variable declared inside a method is a **local variable**, and the rule above is for those. A
variable declared in a class, outside any method, is a **field**, and fields are given a default
value when they are created. Lesson 13 is about fields. Here, `static` fields show the defaults
without needing an object, which lesson 15 explains:

```java
// Defaults.java
public class Defaults {
    static int loans;
    static double balance;
    static boolean blocked;
    static char grade;
    static String name;

    public static void main(String[] args) {
        System.out.println(loans);
        System.out.println(balance);
        System.out.println(blocked);
        System.out.println(grade + 0);
        System.out.println(name);
    }
}
```

```
ana@vm:~/scope$ java Defaults.java
0
0.0
false
0
null
```

| field type | default |
|---|---|
| `int`, `long`, `short`, `byte` | `0` |
| `double`, `float` | `0.0` |
| `boolean` | `false` |
| `char` | the character with code 0, printed above as a number |
| any object type, such as `String` | `null` |

**A default is a value nobody chose.** A `balance` of `0.0` and a `name` of `null` look exactly like
real data to the code that reads them. The difference between the two rules is not an accident: a
field may be read by any method of its class, at any time, and the compiler cannot follow every path
to it, so it settles for a known starting value. A local is visible only inside its own method, where
the compiler can check every path, and does.
