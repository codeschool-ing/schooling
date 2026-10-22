---
title: Wrappers, boxing, and the two ways it bites
version: 1
---

Each primitive has a **wrapper class**: `Integer` for `int`, `Long` for `long`, `Double` for
`double`, `Character` for `char`, `Boolean` for `boolean`, and so on. A wrapper is an object holding
one primitive value. Wrappers exist because a large part of Java works only with objects: the
collections of lessons 31 to 35 hold objects and never primitives, so a list of numbers is a list of
`Integer`.

**Java converts between the two by itself.** Putting an `int` where an `Integer` is expected is
**boxing**, and taking the `int` back out is **unboxing**. The compiler writes both conversions for
you, which is convenient, and it hides two traps that every Java programmer meets once.

## `==` on two `Integer`s

```java
// Boxing.java
public class Boxing {
    public static void main(String[] args) {
        Integer a = 127;
        Integer b = 127;
        System.out.println(a == b);
        Integer c = 128;
        Integer d = 128;
        System.out.println(c == d);
        System.out.println(c.equals(d));
        int sum = c + d;
        System.out.println(sum);
    }
}
```

```
ana@vm:~/types$ java Boxing.java
true
false
true
256
```

`127 == 127` was `true` and `128 == 128` was `false`. **On objects, `==` asks whether two
references point at the same object, not whether the values are equal.** `Integer` keeps a small
cache of ready-made objects for the values from -128 to 127, and boxing a value in that range hands
out the cached one, so `a` and `b` are the same object. 128 is outside the cache, so `c` and `d`
are two different objects holding the same number, and `==` says so.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Boxing 127 twice: variables a and b both point at one Integer object holding 127, taken from the cache, so a == b is true. Boxing 128 twice: c and d point at two separate Integer objects that both hold 128, so c == d is false while c.equals(d) is true.\"><defs><marker id=\"jv4-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">values from -128 to 127</text><rect x=\"40\" y=\"60\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a</text><rect x=\"40\" y=\"120\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">b</text><rect x=\"200\" y=\"78\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Integer 127</text><text x=\"265\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">from the cache</text><path d=\"M100 75 L198 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv4-a)\"></path><path d=\"M100 135 L198 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv4-a)\"></path><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a == b is true: one object</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">values outside the cache</text><rect x=\"400\" y=\"60\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c</text><rect x=\"560\" y=\"54\" width=\"130\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Integer 128</text><path d=\"M460 75 L558 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv4-a)\"></path><rect x=\"400\" y=\"120\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">d</text><rect x=\"560\" y=\"114\" width=\"130\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Integer 128</text><path d=\"M460 135 L558 135\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv4-a)\"></path><text x=\"540\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">c == d is false: two objects</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c.equals(d) is true: same value</text><path d=\"M360 16 V214\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\" fill=\"none\"></path></svg>", "caption": "== on objects compares arrows, not contents. Inside the cache, two boxings of the same value share one object; outside it, each boxing makes a new one."}
```

`c.equals(d)` compares the values and said `true`, and that is the method to use. `c + d` printed
256 because arithmetic unboxes both sides first. The rule to keep is the one lesson 7 repeats for
strings: **compare objects with `equals`, and keep `==` for primitives**. The cache makes the wrong
choice pass every test that uses small numbers, which is why it is dangerous rather than merely
wrong.

## Unboxing `null`

A wrapper is an object, so a wrapper variable can hold `null`, meaning no object at all. A primitive
cannot. Unbox a `null` and there is nothing to take the value out of:

```java
// Missing.java
public class Missing {
    public static void main(String[] args) {
        Integer copiesLeft = null;
        int copies = copiesLeft;
        System.out.println(copies);
    }
}
```

```
ana@vm:~/types$ java Missing.java; echo $?
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "java.lang.Integer.intValue()" because "<local1>" is null
	at Missing.main(Missing.java:5)
1
ana@vm:~/types$ javac -g Missing.java && java Missing
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "java.lang.Integer.intValue()" because "copiesLeft" is null
	at Missing.main(Missing.java:5)
```

**A `NullPointerException`, on a line with no method call in sight.** The message names the call
anyway: to turn `copiesLeft` into an `int`, the compiler wrote a call to `intValue()`, and calling a
method on `null` is exactly what this exception reports. The first run, from source, named the
variable `<local1>`, the first local variable of `main`. Compiled with `javac -g`, which keeps the
names of local variables in the class file, the second run named it `copiesLeft`.

So where a value can be missing, a wrapper can say so with `null`, and every place that unboxes it is
a place it can fail. Where a value is always there, a primitive cannot be `null` at all. **Use the
primitive unless you need the object**, and lesson 30 returns to what a variable holding an object
really holds.
