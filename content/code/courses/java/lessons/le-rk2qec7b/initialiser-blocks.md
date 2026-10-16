---
title: Code outside every method
version: 1
---

Most people picture a class as fields and methods, with every line of code inside a method, and the
constructor as the place where an object's set-up happens. **A class can also hold code in blocks
that belong to no method at all**, and Java runs them for you at fixed moments. There are two kinds:
a **static block**, which runs once for the class, and an **instance block**, which runs once for
every object. Field initialisers, the `= …` after a field's declaration, run at the same moments as
the blocks of their kind.

Here are both, in a directory of their own, `~/init`:

```schooling-example
{
  "language": "java",
  "file": "Shelf.java",
  "parts": [
    {
      "code": "import java.util.ArrayList;\nimport java.util.List;\n\npublic class Shelf {\n    static final List<String> GENRES = new ArrayList<>();",
      "note": "**A static field with an initialiser.** The expression on the right runs once, when the class is first used, and before anything else in the class."
    },
    {
      "code": "\n    static {\n        GENRES.add(\"fiction\");\n        GENRES.add(\"history\");\n        System.out.println(\"static block: \" + GENRES);\n    }",
      "note": "**A static block: code that belongs to the class rather than to any method.** It runs once, straight after the field above it, because static initialisers run in the order they are written. It is the place for set-up that one expression cannot hold."
    },
    {
      "code": "\n    private final List<String> titles = new ArrayList<>();",
      "note": "An instance field with an initialiser. This one runs for every object, as the first thing each constructor does after calling the superclass's."
    },
    {
      "code": "\n    {\n        titles.add(\"(empty)\");\n        System.out.println(\"instance block: \" + titles);\n    }",
      "note": "**An instance block: the same braces with no `static` and no name.** It runs for every object, after the field above it and before the body of whichever constructor was called."
    },
    {
      "code": "\n    Shelf() {\n        System.out.println(\"Shelf(): \" + titles);\n    }\n\n    Shelf(String first) {\n        titles.set(0, first);\n        System.out.println(\"Shelf(String): \" + titles);\n    }",
      "note": "Two constructors, and neither repeats the set-up. Both find `titles` already holding `(empty)`, because the instance block ran before their bodies."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        System.out.println(\"main starts\");\n        new Shelf();\n        new Shelf(\"Dom Casmurro\");\n    }\n}",
      "note": "`main` prints a line first, so the output shows whether the static block ran before or after it."
    }
  ],
  "output": "static block: [fiction, history]\nmain starts\ninstance block: [(empty)]\nShelf(): [(empty)]\ninstance block: [(empty)]\nShelf(String): [Dom Casmurro]"
}
```

Compiled and run:

```
ana@vm:~/init$ javac Shelf.java && java Shelf
static block: [fiction, history]
main starts
instance block: [(empty)]
Shelf(): [(empty)]
instance block: [(empty)]
Shelf(String): [Dom Casmurro]
```

Read the output against the program, line by line:

- **`static block` comes before `main starts`.** The JVM has to initialise a class before running
  any of its static methods, and `main` is one. Initialising `Shelf` means running its static field
  initialisers and static blocks, top to bottom, once.
- **`instance block` appears twice**, once per `new Shelf`, and each time before the constructor's
  own line. Which constructor was called made no difference to that.
- `Shelf(String)` replaced `(empty)` with the title, so the constructor body ran after the block and
  could see what it had done.

## Where the compiler puts them

`javap -p` lists every member, private ones included:

```
ana@vm:~/init$ javap -p Shelf
Compiled from "Shelf.java"
public class Shelf {
  static final java.util.List<java.lang.String> GENRES;
  private final java.util.List<java.lang.String> titles;
  Shelf();
  Shelf(java.lang.String);
  public static void main(java.lang.String[]);
  static {};
}
```

**The instance block has disappeared, and the static block is one method called `static {}`.** That
is how the compiler arranges them. Every static initialiser and static block, in source order, is
joined into one class initialiser, which the JVM calls once. Every instance initialiser and instance
block is copied into the start of **each** constructor, after its call to the superclass
constructor. There is no instance-block method to call, which is why it cannot be called twice or
skipped.

## When to write one

**A static block earns its place when a static field needs more than one expression to set up**: a
lookup table filled from a loop, or a value that can throw and has to be caught. A `static final`
field that one expression can fill does not need a block, and `List.of("fiction", "history")` would
have done it here, as an unmodifiable list.

**An instance block is rare in real code.** Its job is shared set-up for several constructors, and
lesson 13 already gave that job to `this(...)`, where one constructor calls another. Most style
guides prefer the call, because it is visible in the constructor somebody is reading, and an
instance block twenty lines above it is not. You will still meet instance blocks in older code, and
section 03 shows exactly where they fit in the order of events.
