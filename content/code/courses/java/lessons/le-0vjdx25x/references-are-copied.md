---
title: An object's reference is copied too
version: 1
---

Here is where the common belief comes from. Pass an object to a method, let the method change it,
and the change is visible afterwards. That looks exactly like pass by reference, and many people
conclude that Java passes primitives by value and objects by reference. **It does not. Java never
passes an object at all.** Lesson 12 showed that a variable of a class type does not hold an object;
it holds a **reference**, an arrow to an object somewhere on the heap. What the method receives is a
copy of that arrow.

One `Book` and two methods, in `~/byvalue/refs`. `renew` changes the object its parameter points at;
`replace` points its parameter at a different object:

```java
// Refs.java
class Book {
    String title;
    int renewals;

    Book(String title) {
        this.title = title;
    }

    @Override
    public String toString() {
        return title + ", renewed " + renewals + " times";
    }
}

public class Refs {
    static void renew(Book b) {
        b.renewals = b.renewals + 1;
    }

    static void replace(Book b) {
        b = new Book("Iracema");
        b.renewals = 99;
    }

    public static void main(String[] args) {
        Book mine = new Book("Dom Casmurro");
        renew(mine);
        System.out.println("after renew:   " + mine);
        replace(mine);
        System.out.println("after replace: " + mine);
    }
}
```

```
ana@vm:~/byvalue/refs$ javac Refs.java && java Refs
after renew:   Dom Casmurro, renewed 1 times
after replace: Dom Casmurro, renewed 1 times
```

**`renew` reached `mine`'s book. `replace` did not**: after it, `mine` is still *Dom Casmurro*,
renewed once, and the *Iracema* with 99 renewals is nowhere. Both results follow from the one rule,
once the arrows are drawn:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two calls, drawn as frames and the heap. During renew(mine): main's frame holds the variable mine, renew's frame holds its parameter b, and both hold a copy of the same reference, so both arrows point at one Book object, Dom Casmurro, whose renewals become 1. During replace(mine): b starts as a copy of the same reference, then is assigned a new Book, Iracema with 99 renewals; only b's arrow moves, and mine still points at Dom Casmurro.\"><defs><marker id=\"jv30-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"jv30-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"340\" height=\"226\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">during renew(mine)</text><text x=\"80\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">frames</text><text x=\"260\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the heap</text><text x=\"80\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">main</text><rect x=\"40\" y=\"94\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mine</text><text x=\"80\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">renew</text><rect x=\"40\" y=\"176\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">b</text><rect x=\"190\" y=\"74\" width=\"145\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"262\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"262\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Dom Casmurro, 1</text><path d=\"M120 106 H188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv30-a)\"></path><path d=\"M120 188 H160 V118 H188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv30-a)\"></path><rect x=\"370\" y=\"10\" width=\"340\" height=\"226\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">during replace(mine)</text><text x=\"440\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">frames</text><text x=\"620\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the heap</text><text x=\"440\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">main</text><rect x=\"400\" y=\"94\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mine</text><text x=\"440\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">replace</text><rect x=\"400\" y=\"176\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">b</text><rect x=\"550\" y=\"74\" width=\"145\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"622\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Dom Casmurro, 1</text><path d=\"M480 106 H548\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv30-a)\"></path><rect x=\"550\" y=\"160\" width=\"145\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"622\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"622\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Iracema, 99</text><path d=\"M480 188 H548\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv30-b)\"></path><rect x=\"10\" y=\"248\" width=\"340\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"180\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">two copies of one reference, one object</text><rect x=\"370\" y=\"248\" width=\"340\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">b moved; mine never did</text></svg>", "caption": "A parameter is a copy of the caller's variable. When the variable holds a reference, the copy points at the same object, so changes to the object are shared. Reassigning the copy moves one arrow, its own."}
```

**During `renew`, there are two arrows and one object.** `mine` holds a reference, and calling
`renew(mine)` copied that reference into `b`, exactly as section 02 copied 1 into `a`. Two copies of
one arrow point at the same `Book`, so `b.renewals = b.renewals + 1` changed the one object both
arrows reach, and `main` sees the change when it follows its own arrow.

**During `replace`, `b` starts as a copy of the same arrow and then is pointed somewhere else.**
`b = new Book("Iracema")` changes what `replace`'s own variable holds, which is its own slot in its
own frame, and `main`'s `mine` is a different variable that nobody touched. The new book is built,
given 99 renewals, and becomes garbage when `replace` returns, since nothing points at it any more
(lesson 19).

The bytecode says the same thing in its own words:

```
ana@vm:~/byvalue/refs$ javap -c Refs | grep -A 7 "void replace"
  static void replace(Book);
    Code:
         0: new           #8                  // class Book
         3: dup
         4: ldc           #13                 // String Iracema
         6: invokespecial #15                 // Method Book."<init>":(Ljava/lang/String;)V
         9: astore_0
        10: aload_0
```

`new`, `dup`, `ldc` and `invokespecial` build the new `Book`. Then **`astore_0` stores the reference
into slot 0, which is the parameter `b`**: an ordinary store into `replace`'s own frame, the same
kind of instruction as section 02's `istore_0`. A reference is a value like an `int` is a value, and
it travels the same way.

## The sentence to keep

**Java passes everything by value. For an object, the value is a reference.** So a method can change
the object you gave it, because it has an arrow to that object, and it can never change which object
your variable points at, because it has only a copy of your arrow. People sometimes call this "pass
by reference value" or "pass by sharing", and those are names for the same sentence.

Two tests tell the two models apart, and section 04 runs both. If Java passed objects by reference,
`replace` above would have changed `mine`, and a method could swap two objects for its caller. Neither
happens.
