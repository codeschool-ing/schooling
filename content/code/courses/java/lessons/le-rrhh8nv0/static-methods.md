---
title: Methods with no object
version: 1
---

A method in lesson 13 always ran on one object: the one before the dot, which it could reach as
`this`. Some behaviour has no object to run on. Checking whether a string has the shape of an ISBN
needs the string and nothing else. **A `static` method belongs to the class, is called through the
class's name, and has no `this`.**

```java
// Isbns.java
class Isbns {
    static boolean looksValid(String isbn) {
        String digits = isbn.replace("-", "");
        return digits.length() == 13;
    }
}
```

```java
// Check.java
public class Check {
    public static void main(String[] args) {
        System.out.println(Isbns.looksValid("978-85-359-0277-1"));
        System.out.println(Isbns.looksValid("85-359-0277"));
        System.out.println(Math.max(3, 7));
    }
}
```

```
ana@vm:~/static$ javac Check.java && java Check
true
false
7
```

No `Isbns` object was ever made, and nothing about one would help: the method's whole input is its
parameter. `Math.max` is the same kind of method, from the JDK's own library, and `Math` is a class
made only of static methods and constants, which nobody ever makes an object of. (The check itself
only counts digits; a real one also verifies the last digit, which is arithmetic this lesson does not
need.)

## Why `main` is static

When `java Check` starts, the JVM has loaded a class and made no objects. It needs a method it can
call **without an object**, and that is exactly what `public static void main(String[] args)` is.
From inside a static method, though, there is no `this`, so an instance method of the same class
cannot be called by its bare name:

```java
// Greeter.java
public class Greeter {
    String greeting = "Olá";

    void greet() {
        System.out.println(greeting);
    }

    public static void main(String[] args) {
        greet();
    }
}
```

```
ana@vm:~/static$ javac Greeter.java
Greeter.java:10: error: non-static method greet() cannot be referenced from a static context
        greet();
        ^
1 error
```

**A *static context* is code that runs with no object**, and `greet()` needs one, because it reads
`greeting`, which every `Greeter` has its own copy of. The fix is to make the object first and call
the method on it:

```java
// Greeter.java
public class Greeter {
    String greeting = "Olá";

    void greet() {
        System.out.println(greeting);
    }

    public static void main(String[] args) {
        Greeter g = new Greeter();
        g.greet();
    }
}
```

```
ana@vm:~/static$ javac Greeter.java && java Greeter
Olá
```

That error is one of the first a Java programmer meets, and "make it static too" is the usual wrong
answer, because it spreads: `greet` would then need `greeting` to be static, and
soon the program has one shared copy of everything. **Ask whether the method needs an object's data.
If it does, it needs an object; if it does not, it can be static.** `looksValid` needs only its
parameter; `greet` needs a greeting. The compact source files of lesson 3, which do not exist on
Java 21, let `main` itself be an instance method, because the launcher makes the object first; the
question is the same one.
