---
title: Dynamic dispatch, in the class file
version: 1
---

Section 02 said the object decides which override runs. That decision has to be made somewhere,
by something, and it is not the compiler: `javac` compiled `Desk` once, and the same compiled loop
ran three different methods. **The choice is made by the JVM, at each call, from the object's
class.** That is dynamic dispatch, also called late binding, and the class file shows where it
happens.

## What the compiler wrote

In the same `~/binding`, a method that takes any `Item`:

```java
// Say.java
public class Say {
    static String say(Item item) {
        return item.describe();
    }

    public static void main(String[] args) {
        System.out.println(say(new Book("978-85-359-0277-2")));
        System.out.println(say(new Dvd()));
    }
}
```

```
ana@vm:~/binding$ javac Say.java && java Say
a book
a DVD
ana@vm:~/binding$ javap -c Say | grep -A4 "say(Item)"
  static java.lang.String say(Item);
    Code:
         0: aload_0
         1: invokevirtual #7                  // Method Item.describe:()Ljava/lang/String;
         4: areturn
```

Line 1 of `say` is the call, and the compiler wrote down exactly what it knew: **`invokevirtual`,
of `Item.describe`**. It did not write `Book.describe` or `Dvd.describe`; it could not have, since
`say` is compiled once and called with both. The instruction names a method by the declared type
and leaves the body open. `java Say` then ran the book's override and the DVD's from that one line.

## What the JVM does with it

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dynamic dispatch. The call site in the class file says invokevirtual Item.describe. At run time the JVM looks at the object the reference points to, finds its class, and looks describe up in that class's table of virtual methods. Item's table maps describe to Item.describe; Book's maps describe to Book.describe and also has isbn; Dvd's maps describe to Dvd.describe. For a Book object the call runs Book.describe.\"><defs><marker id=\"jv25-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">invokevirtual Item.describe</text><text x=\"150\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">written once, by the compiler</text><rect x=\"20\" y=\"130\" width=\"260\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the object on the stack is a Book</text><text x=\"150\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its class is read at the call</text><path d=\"M150 84 L150 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv25-a)\"></path><rect x=\"380\" y=\"20\" width=\"320\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Item's method table</text><text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">describe()  →  Item.describe</text><rect x=\"380\" y=\"82\" width=\"320\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book's method table</text><text x=\"540\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">describe()  →  Book.describe</text><text x=\"540\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">isbn()  →  Book.isbn</text><rect x=\"380\" y=\"166\" width=\"320\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Dvd's method table</text><text x=\"540\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">describe()  →  Dvd.describe</text><path d=\"M280 158 L378 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv25-a)\"></path><rect x=\"20\" y=\"220\" width=\"260\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Book.describe runs</text><text x=\"150\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">same instruction, other objects, other bodies</text><path d=\"M150 186 L150 218\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "The compiler names the method; the object's class picks the body. Each class has a table of its overridable methods, and an override replaces one entry."}
```

When `invokevirtual` runs, the JVM takes the object the reference points to, reads its class, and
looks the method up starting from that class and moving towards `Object`, taking the first body it
finds. **HotSpot does not search every time**: each class carries a table of its overridable
methods, built when the class is loaded, where an override simply replaces the parent's entry. The
call becomes one look-up in the table of the object's class.

The four instructions that call a method each say how that choice is made:

| instruction | used for | the body is chosen |
|---|---|---|
| `invokevirtual` | an ordinary instance method of a class | by the object's class, at run time |
| `invokeinterface` | a method called through an interface type, like lesson 23's `Lendable` | by the object's class, at run time |
| `invokestatic` | a `static` method | by the compiler, from the class named in the call |
| `invokespecial` | a constructor, and calls written as `super.m()` | by the compiler: exactly the one named |

Dispatch costs little in practice. The JIT compiler of lesson 1 watches each call site, and where it
has only ever seen one class, it can call that body directly, or copy it inline, and keep a cheap
check in case another class turns up later. So designing with small overridable methods is not a
performance decision; it is a design decision, and a cheap one.
