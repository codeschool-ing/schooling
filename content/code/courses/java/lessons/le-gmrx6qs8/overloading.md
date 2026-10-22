---
title: Overloading, decided by the compiler
version: 1
---

**Overloading is several methods in one class with the same name and different parameter lists.**
`println` is the one everybody has met: there is a `println(int)`, a `println(String)`, a
`println(double)` and seven more, and you never had to say which you meant. The compiler chose, from
the types of the arguments, and wrote its choice into the class file. Nothing about it happens at
run time, and that is the fact the rest of this lesson leans on.

## Six calls, six methods

In `~/overload`:

```java
// Printer.java
public class Printer {
    static void show(int x) {
        System.out.println("int " + x);
    }

    static void show(long x) {
        System.out.println("long " + x);
    }

    static void show(Integer x) {
        System.out.println("Integer " + x);
    }

    static void show(Object x) {
        System.out.println("Object " + x);
    }

    static void show(int... xs) {
        System.out.println("varargs of " + xs.length);
    }

    public static void main(String[] args) {
        byte small = 5;
        show(5);
        show(5L);
        show(small);
        show(Integer.valueOf(5));
        show("five");
        show(1, 2, 3);
    }
}
```

```
ana@vm:~/overload$ javac Printer.java && java Printer
int 5
long 5
int 5
Integer 5
Object five
varargs of 3
```

Read the output against the arguments:

| call | argument's type | method chosen | why |
|---|---|---|---|
| `show(5)` | `int` | `show(int)` | an exact match |
| `show(5L)` | `long` | `show(long)` | an exact match |
| `show(small)` | `byte` | `show(int)` | no `show(byte)`; a `byte` widens to `int`, the nearest wider type |
| `show(Integer.valueOf(5))` | `Integer` | `show(Integer)` | an exact match |
| `show("five")` | `String` | `show(Object)` | a `String` is an `Object`, and nothing nearer exists |
| `show(1, 2, 3)` | three `int`s | `show(int...)` | only the varargs method takes three arguments |

**The parameter types are what tell overloads apart**: the name, the number of parameters, and
their types in order, together called the method's **signature**. The return type is not part of
it, so two methods that differ only in what they return are not two overloads at all:

```java
// Twice.java
public class Twice {
    int count() {
        return 1;
    }

    long count() {
        return 1L;
    }
}
```

```
ana@vm:~/overload$ javac Twice.java
Twice.java:7: error: method count() is already defined in class Twice
    long count() {
         ^
1 error
```

## When more than one would fit

`show(5)` matched `show(int)` exactly. Take the exact match away and an `int` could still reach
three of the others: widened to `long`, boxed into an `Integer`, or packed into an `int...`. The
compiler ranks the three, and `Ranking` asks it twice:

```java
// Ranking.java
public class Ranking {
    static void widen(long x) {
        System.out.println("widen: long");
    }

    static void widen(Integer x) {
        System.out.println("widen: Integer");
    }

    static void box(Integer x) {
        System.out.println("box: Integer");
    }

    static void box(int... xs) {
        System.out.println("box: varargs");
    }

    public static void main(String[] args) {
        widen(5);
        box(5);
    }
}
```

```
ana@vm:~/overload$ javac Ranking.java && java Ranking
widen: long
box: Integer
```

**Widening beats boxing, and boxing beats varargs.** `widen(5)` chose `long` over `Integer`, and
`box(5)` chose `Integer` over `int...`. The order is history rather than taste. Boxing arrived in
Java 5, and a program written for Java 1.4 that called `widen(5)` had always reached `widen(long)`;
ranking boxing lower kept that program doing what it had always done. Varargs arrived in the same
release and went to the bottom for the same reason.

## When two fit equally well

```java
// Ambiguous.java
public class Ambiguous {
    static void lend(Integer copies, Object note) {
    }

    static void lend(Object copies, Integer note) {
    }

    public static void main(String[] args) {
        lend(1, 2);
    }
}
```

```
ana@vm:~/overload$ javac Ambiguous.java
Ambiguous.java:10: error: reference to lend is ambiguous
        lend(1, 2);
        ^
  both method lend(Integer,Object) in Ambiguous and method lend(Object,Integer) in Ambiguous match
1 error
```

`lend(1, 2)` can reach either method by boxing one argument and widening the other to `Object`, and
neither path is better than the other. **The compiler does not toss a coin; it refuses**, and names
both candidates. The fix is the caller's: a cast such as `lend((Integer) 1, (Object) 2)` or, more
honestly, two methods with different names. When overloads need casts to be called, the names are
doing too little work.
