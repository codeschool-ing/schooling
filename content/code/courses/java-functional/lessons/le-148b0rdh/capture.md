---
title: What a lambda may use from around it
version: 1
---

**A lambda can read the variables in scope where it is written: its own parameters, the fields of
the object around it, and the local variables of the method it is in.** The last of those comes
with a rule, and the rule is the most common compiler error a lambda produces.

## Capturing a value

```java
// Capture.java: a lambda that uses a parameter, a local and a field
import java.util.function.Supplier;

public class Capture {
    private final String shop = "Livraria Lumen";

    Supplier<String> greeter(String visitor) {
        String greeting = "Welcome";
        return () -> greeting + ", " + visitor + ", to " + this.shop;
    }

    public static void main(String[] args) {
        Supplier<String> greet = new Capture().greeter("Ana");
        System.out.println(greet.get());
    }
}
```

```
ana@vm:~/fp/lambdas$ java Capture.java
Welcome, Ana, to Livraria Lumen
```

`greeter` returned before `greet.get()` ran, and with it went its local variables, `greeting` and
`visitor`. The lambda still printed both. **When the lambda was created, it copied their values
into itself.** That is what capturing means, and it is why the rule below exists.

## Effectively final

```java
// Counter.java: a lambda that tries to change a local variable
import java.util.List;

public class Counter {
    public static void main(String[] args) {
        int count = 0;
        List.of("a", "b", "c").forEach(s -> count++);
        System.out.println(count);
    }
}
```

```
ana@vm:~/fp/lambdas$ javac -d out Counter.java
Counter.java:7: error: local variables referenced from a lambda expression must be final or effectively final
        List.of("a", "b", "c").forEach(s -> count++);
                                            ^
1 error
```

**A local variable a lambda uses must never change, before or after the lambda is written.** It
need not say `final`; it has to be one that could. The specification calls that **effectively
final**, and the compiler checks it for every local a lambda reads. The rule falls straight out of
copying: the lambda holds a copy of `count`, so an increment inside it would change the copy and
leave the variable alone, and an assignment outside it would leave the copy stale. Java refuses
both rather than pick one.

The rule also covers a change the lambda never makes:

```java
// Reassigned.java: the lambda reads, and somebody else writes
public class Reassigned {
    public static void main(String[] args) {
        String greeting = "Hi";
        greeting = "Hello";
        Runnable say = () -> System.out.println(greeting);
        say.run();
    }
}
```

```
ana@vm:~/fp/lambdas$ javac -d out Reassigned.java
Reassigned.java:6: error: local variables referenced from a lambda expression must be final or effectively final
        Runnable say = () -> System.out.println(greeting);
                                                ^
1 error
```

`greeting` was assigned twice, so it is not effectively final, and the lambda may not read it. The
fix is to give the lambda a variable that is assigned once, such as `String finalGreeting =
greeting;` above the lambda.

**Fields are not covered by the rule.** `this.shop` above was read through `this`, and the lambda
captured `this`, which never changes; the field itself may change as often as you like, and the
lambda sees the latest value when it runs. That freedom is exactly what makes a field shared
between two threads dangerous, and lessons 11 to 14 are about that danger. Counting inside a
`forEach` is better done without a lambda changing anything at all, which lesson 7's `count()` and
`reduce` do.

## `this` means the object around the lambda

An anonymous class is a class, so inside it `this` is the anonymous object. A lambda is not, so
`this` means what it means in the method around it:

```java
// WhoIsThis.java: `this` inside a lambda and inside an anonymous class
public class WhoIsThis {
    @Override
    public String toString() {
        return "the WhoIsThis object";
    }

    void show() {
        Runnable lambda = () -> System.out.println("lambda sees:    " + this);
        Runnable anonymous = new Runnable() {
            @Override
            public void run() {
                System.out.println("anonymous sees: " + this);
            }

            @Override
            public String toString() {
                return "the anonymous Runnable";
            }
        };
        lambda.run();
        anonymous.run();
    }

    public static void main(String[] args) {
        new WhoIsThis().show();
    }
}
```

```
ana@vm:~/fp/lambdas$ java WhoIsThis.java
lambda sees:    the WhoIsThis object
anonymous sees: the anonymous Runnable
```

**Inside a lambda, `this` is the enclosing object.** The same goes for names. An anonymous class's
method may call its parameter anything, because the class is a new scope; a lambda's parameter may
not reuse the name of a local variable already in scope:

```java
// Shadow.java: a lambda parameter with a name already taken
import java.util.function.Function;

public class Shadow {
    public static void main(String[] args) {
        String s = "outer";
        Function<String, Integer> length = s -> s.length();
        System.out.println(length.apply(s));
    }
}
```

```
ana@vm:~/fp/lambdas$ javac -d out Shadow.java
Shadow.java:7: error: variable s is already defined in method main(String[])
        Function<String, Integer> length = s -> s.length();
                                           ^
1 error
```

Both rules come from the fact the class files showed in section 04: **a lambda is not a new scope
with a class around it**, only a body that runs somewhere else.
