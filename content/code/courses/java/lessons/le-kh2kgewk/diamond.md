---
title: Two defaults, one class
version: 1
---

Default methods brought back the problem that kept multiple inheritance of classes out of Java: **two
parents giving the same method two different bodies**. A class that implements two interfaces with
the same default inherits both, and one call cannot run two methods. Java's answer is to refuse to
guess.

## The clash

In `~/iface/diamond`, two interfaces that each label what they describe:

```java
// Printed.java
public interface Printed {
    default String label() {
        return "printed matter";
    }
}
```

```java
// Recorded.java
public interface Recorded {
    default String label() {
        return "a recording";
    }
}
```

An audiobook is both, so it signs both and writes nothing else:

```java
// Audiobook.java
public class Audiobook implements Printed, Recorded {
}
```

```
ana@vm:~/iface/diamond$ javac Printed.java Recorded.java Audiobook.java
Audiobook.java:2: error: types Printed and Recorded are incompatible;
public class Audiobook implements Printed, Recorded {
       ^
  class Audiobook inherits unrelated defaults for label() from types Printed and Recorded
1 error
```

**The error names the method and both interfaces**, and it is a compile error rather than a rule
about which one wins. No order of `implements` decides it, no "first one listed" convention; the
class has to say.

## Choosing, in one line

```java
// Audiobook.java
public class Audiobook implements Printed, Recorded {
    @Override
    public String label() {
        return Recorded.super.label() + " of " + Printed.super.label();
    }
}
```

`Recorded.super.label()` means "the default from `Recorded`", and the same with `Printed`. A class
may call either, both, or neither; here it combines them. The `.super` form only works for an
interface the class names directly in its `implements`.

## A class beats an interface

One more case, and it needs no code from you to resolve. When a method comes from a **superclass**
and a default with the same signature comes from an interface, the class's method wins:

```java
// Catalogue.java
public class Catalogue {
    public String label() {
        return "a catalogue entry";
    }
}
```

```java
// Leaflet.java
public class Leaflet extends Catalogue implements Printed {
}
```

```java
// Labels.java
public class Labels {
    public static void main(String[] args) {
        System.out.println(new Audiobook().label());
        System.out.println(new Leaflet().label());
    }
}
```

```
ana@vm:~/iface/diamond$ javac *.java && java Labels
a recording of printed matter
a catalogue entry
```

`Leaflet` printed `a catalogue entry`, from `Catalogue`, and `Printed`'s default never ran. The rule
exists so that adding a default to an old interface cannot change what an existing class does: a
class that already had the method keeps it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two interfaces, Printed and Recorded, each give a default label method. Audiobook implements both and inherits two unrelated defaults, so the compiler refuses until Audiobook writes its own label, which may call Recorded.super.label() and Printed.super.label(). Leaflet extends the class Catalogue and implements Printed; the class's method wins over the interface's default.\"><defs><marker id=\"jv23-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"190\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Printed</text><text x=\"115\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">label(): \"printed matter\"</text><rect x=\"240\" y=\"20\" width=\"190\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Recorded</text><text x=\"335\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">label(): \"a recording\"</text><text x=\"225\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one default each</text><path d=\"M115 82 L215 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv23-a)\"></path><path d=\"M335 82 L235 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv23-a)\"></path><rect x=\"110\" y=\"162\" width=\"230\" height=\"108\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"225\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Audiobook</text><text x=\"225\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">inherits two unrelated defaults</text><rect x=\"126\" y=\"218\" width=\"198\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"225\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own label() chooses</text><text x=\"225\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Recorded.super.label()</text><rect x=\"470\" y=\"20\" width=\"110\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"525\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Catalogue</text><text x=\"525\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a class</text><rect x=\"600\" y=\"20\" width=\"110\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Printed</text><text x=\"655\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a default</text><path d=\"M525 82 L575 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv23-a)\"></path><path d=\"M655 82 L620 198\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\" fill=\"none\"></path><rect x=\"490\" y=\"200\" width=\"210\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Leaflet</text><text x=\"595\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">\"a catalogue entry\"</text><text x=\"595\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the class wins</text></svg>", "caption": "Left, the diamond: two defaults meet and the class must decide. Right, a superclass's method against an interface's default: the class wins without a word."}
```

**The diamond is rare in practice and cheap when it happens**: the compiler finds every case, and
the fix is one method. What it teaches is the general shape of Java's inheritance. Behaviour may
arrive from several interfaces; state arrives from one class; and wherever two answers compete with
no rule to settle them, the language makes you write the answer down.
