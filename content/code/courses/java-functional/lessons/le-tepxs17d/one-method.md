---
title: One abstract method
version: 1
---

**A functional interface is an interface with exactly one abstract method, and any such interface
can be written as a lambda.** That is the whole definition. `Comparator` in lesson 1 qualified
because it has one method to implement, `compare`; `Runnable` qualifies because it has `run`. Java
did not add a new kind of type for lambdas in 2014. It agreed to accept a lambda wherever one of
these interfaces was expected, including the ones written long before.

Your own interfaces qualify the same way:

```java
// OneMethod.java: an interface of our own, written as a lambda
@FunctionalInterface
interface PriceRule {
    long apply(long cents);

    default String describe(long cents) {
        return cents + " -> " + apply(cents);
    }
}

public class OneMethod {
    public static void main(String[] args) {
        PriceRule tenOff = cents -> cents - cents / 10;
        PriceRule shipping = cents -> cents + 1500;
        System.out.println(tenOff.describe(8990));
        System.out.println(shipping.describe(8990));
    }
}
```

```
ana@vm:~/fp/interfaces$ java OneMethod.java
8990 -> 8091
8990 -> 10490
```

`PriceRule` has one abstract method, `apply`, so each lambda became a `PriceRule` whose `apply` is
the lambda's body. **The default method does not count**: it already has a body, so there is
nothing for a lambda to fill in, and every lambda-made `PriceRule` gets `describe` for free. Prices
are in cents, as `long`, for the reason the `java` course gave about floating point.

## The annotation is a promise the compiler checks

`@FunctionalInterface` changes nothing about how the interface works. It asks the compiler to
**refuse the interface if it ever stops having exactly one abstract method**, which is the day
somebody adds a second one and every lambda in the codebase breaks at once. Here is that day:

```java
// TwoMethods.java: a second abstract method breaks the promise
@FunctionalInterface
interface PriceRule {
    long apply(long cents);

    String label();
}

public class TwoMethods {
    public static void main(String[] args) {
        PriceRule tenOff = cents -> cents - cents / 10;
    }
}
```

```
ana@vm:~/fp/interfaces$ javac -d out TwoMethods.java
TwoMethods.java:2: error: Unexpected @FunctionalInterface annotation
@FunctionalInterface
^
  PriceRule is not a functional interface
    multiple non-overriding abstract methods found in interface PriceRule
TwoMethods.java:11: error: incompatible types: PriceRule is not a functional interface
        PriceRule tenOff = cents -> cents - cents / 10;
                           ^
    multiple non-overriding abstract methods found in interface PriceRule
2 errors
```

Two errors, in two places. The first is the annotation doing its job, at the interface, where the
mistake was made. The second is at the lambda, which no longer has one method to become. **Without
the annotation, only the second error appears**, in a file somebody else owns, and the person who
added `label()` never sees it. That is the case for writing it on every interface you mean to be
used with lambdas.

## What else may be in one

The rule counts abstract methods, and three kinds of method are not counted:

- **`default` methods**, which have a body, like `describe` above;
- **`static` methods**, which belong to the interface and not to an object;
- **methods that `Object` already has**, such as `equals` and `toString`. Every object inherits a
  body for those, so declaring them in an interface adds nothing to implement. `Comparator` declares
  `equals` and is still functional for this reason.

So a functional interface can be large. `Comparator` has one abstract method and, in Java 25, more
than a dozen default and static methods around it; lesson 5 uses several of them to build an order
out of smaller ones.
