---
title: Type erasure, or where the types go
version: 1
---

Everything in this lesson so far happened in the compiler. **At run time, the type arguments are
gone**: a `List<String>` and a `List<Integer>` are the same class, and the JVM never learns what was
in the brackets. Java chose that in 2004 so that generic code would run on JVMs and libraries that
predated generics, and the choice has consequences you can see.

```java
// Erased.java
import java.util.ArrayList;
import java.util.List;

public class Erased {
    public static void main(String[] args) {
        List<String> titles = new ArrayList<>();
        List<Integer> years = new ArrayList<>();
        System.out.println(titles.getClass());
        System.out.println(titles.getClass() == years.getClass());
    }
}
```

```
ana@vm:~/generics$ java Erased.java
class java.util.ArrayList
true
ana@vm:~/generics$ javap -c Box
Compiled from "Box.java"
public class Box<T> {
  public Box();
    Code:
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return

  public void put(T);
    Code:
         0: aload_0
         1: aload_1
         2: putfield      #7                  // Field item:Ljava/lang/Object;
         5: return

  public T take();
    Code:
         0: aload_0
         1: getfield      #7                  // Field item:Ljava/lang/Object;
         4: areturn
}
ana@vm:~/generics$ javap -c UseBox | grep -A1 "Box.take"
        15: invokevirtual #42                 // Method Box.take:()Ljava/lang/Object;
        18: checkcast     #45                 // class java/lang/String
```

**`titles.getClass()` is `java.util.ArrayList`, with no `<String>`**, and the two lists' classes are
one and the same. Then `javap` shows what `Box<T>` became: the field `item` is stored as
`Ljava/lang/Object;`, and `put` and `take` move `Object`s. `T` survives in the signature `javap`
prints, as information for the compiler, and nowhere in the instructions.

So where did the type check go? Into the callers. The last command searched `UseBox`'s bytecode for
the call to `take`. The instruction right after it is a `checkcast` to `String`: **the compiler
wrote the cast that `Raw.java` had to write by hand**, and wrote it only where it had already proved
the cast would succeed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Type erasure. On the left, what javac checks: class Box of T with a field item of type T; Box of String box; box.put of Dune; String title equals box.take. On the right, what the JVM runs: class Box with a field item of type Object; put takes an Object; take returns an Object; at the call site, invokevirtual Box.take followed by checkcast String. The type argument String is used by the compiler and then erased; the cast it guarantees is written into the caller.\"><defs><marker id=\"jv35-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">what javac checks</text><text x=\"400\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">what the JVM runs</text><rect x=\"20\" y=\"36\" width=\"300\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"400\" y=\"36\" width=\"300\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">class Box&lt;T&gt; {</text><text x=\"58\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">T item;</text><text x=\"34\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><text x=\"34\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Box&lt;String&gt; box = new Box&lt;&gt;();</text><text x=\"34\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">box.put(&quot;Dune&quot;);</text><text x=\"34\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">String title = box.take();</text><text x=\"414\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">class Box {</text><text x=\"438\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Object item;</text><text x=\"414\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><text x=\"414\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">new Box  (no type argument)</text><text x=\"414\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invokevirtual Box.put(Object)</text><text x=\"414\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invokevirtual Box.take()</text><text x=\"414\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">checkcast String</text><path d=\"M322 110 H396\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv35-a)\"></path><text x=\"359\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">erased</text><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the type argument is checked, then thrown away;</text><text x=\"20\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the cast it makes safe is written into the caller</text></svg>", "caption": "One class at run time, whatever the brackets said. The compiler keeps its promise by inserting the cast at each call."}
```

## What erasure forbids

Because `T` does not exist at run time, anything that needs it at run time does not compile:

```java
// Limits.java
import java.util.List;

public class Limits<T> {
    T fresh() {
        return new T();
    }

    static boolean isTitles(Object o) {
        return o instanceof List<String>;
    }
}
```

```
ana@vm:~/generics$ javac Limits.java
Limits.java:6: error: unexpected type
        return new T();
                   ^
  required: class
  found:    type parameter T
  where T is a type-variable:
    T extends Object declared in class Limits
Limits.java:10: error: Object cannot be safely cast to List<String>
        return o instanceof List<String>;
               ^
2 errors
```

- **`new T()`** needs to know which class to create, and at run time there is no `T` to ask. The
  usual way round is to be given the means of creating one, such as a `Class<T>` or a
  `Supplier<T>` from `java-functional`.
- **`o instanceof List<String>`** would have to check the elements' type, and the list does not
  carry it. `o instanceof List<?>` compiles, because it only asks whether `o` is a list.

The same reason forbids `new T[10]` and a `static` field of type `T`, and it is why two methods
`void f(List<String>)` and `void f(List<Integer>)` cannot live in one class: once erased, their
signatures are identical. **None of this limits what a program can do**; it limits what a program can
ask at run time about a type it only knew at compile time.
