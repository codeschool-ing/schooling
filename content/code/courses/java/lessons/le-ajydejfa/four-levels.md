---
title: Four levels, and what the compiler says at each
version: 1
---

Every field and method in lessons 12 and 13 could be read and changed by any class in the same
directory, which is fine for three classes and becomes a problem with three hundred. **An access
modifier says which code may use a member**, and the compiler refuses any use outside that. Java
has four levels, and one of them is written by writing nothing.

The levels only differ once there is more than one **package**, so this section uses one. A package
is a directory of classes with a name, declared on the first line of each file; lesson 18 is about
packages in full, and here only their effect on access matters. In a new directory, `~/access`, save
a shelf in a subdirectory `lib`, with one field at each level:

```java
// lib/Shelf.java
package lib;

public class Shelf {
    public String name = "Fiction";
    String code = "F-01";
    protected int capacity = 40;
    private int count = 0;

    public void add() {
        count = count + 1;
    }

    public int count() {
        return count;
    }
}
```

A program in `~/access` itself, outside `lib`, tries to read all four. `import lib.Shelf;` says
which `Shelf` it means:

```java
// Main.java
import lib.Shelf;

public class Main {
    public static void main(String[] args) {
        Shelf s = new Shelf();
        s.add();
        System.out.println(s.name + " " + s.count());
        System.out.println(s.code);
        System.out.println(s.capacity);
        System.out.println(s.count);
    }
}
```

```
ana@vm:~/access$ javac Main.java
Main.java:9: error: code is not public in Shelf; cannot be accessed from outside package
        System.out.println(s.code);
                            ^
Main.java:10: error: capacity has protected access in Shelf
        System.out.println(s.capacity);
                            ^
Main.java:11: error: count has private access in Shelf
        System.out.println(s.count);
                            ^
3 errors
```

Three errors, and each message names its level. Line 8, with `s.name` and `s.count()`, passed:
both are `public`. **The field `count` is private, and the method `count()` is public**, which is
the arrangement section 03 argues for.

Now a class inside `lib`, in the same package as `Shelf`:

```java
// lib/Inside.java
package lib;

public class Inside {
    public static void main(String[] args) {
        Shelf s = new Shelf();
        System.out.println(s.code + " " + s.capacity);
        System.out.println(s.count);
    }
}
```

```
ana@vm:~/access$ javac lib/Inside.java
lib/Inside.java:8: error: count has private access in Shelf
        System.out.println(s.count);
                            ^
1 error
```

From inside the package, `code` and `capacity` passed and only `count` failed. **`private` means
this class and nothing else**, not even a neighbour in the same package.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Four nested regions of access. The innermost is the class itself, which private reaches. Around it, the package, which no modifier reaches. Around that, subclasses in other packages, which protected adds. The outermost is every other class, which only public reaches.\"><rect x=\"16\" y=\"16\" width=\"688\" height=\"248\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">public</text><text x=\"96\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every class, in any package</text><rect x=\"56\" y=\"56\" width=\"608\" height=\"192\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">protected</text><text x=\"156\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">adds subclasses in other packages (lesson 20)</text><rect x=\"96\" y=\"96\" width=\"528\" height=\"136\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"116\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">no modifier</text><text x=\"200\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every class in the same package</text><rect x=\"136\" y=\"136\" width=\"448\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"156\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">private</text><text x=\"222\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the class itself</text><text x=\"360\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Shelf.count</text></svg>", "caption": "Each modifier reaches its own region and every region inside it. Shelf.count is private, so only code written inside Shelf reaches it."}
```

| modifier | the class itself | its package | subclasses elsewhere | everyone |
|---|---|---|---|---|
| `private` | yes | no | no | no |
| none, called *package-private* | yes | yes | no | no |
| `protected` | yes | yes | yes | no |
| `public` | yes | yes | yes | yes |

`protected` adds subclasses, which lesson 20 introduces, and is the least used of the four. A
`Main` that keeps to the public members compiles and runs:

```java
// Main.java
import lib.Shelf;

public class Main {
    public static void main(String[] args) {
        Shelf s = new Shelf();
        s.add();
        s.add();
        System.out.println(s.name + " " + s.count());
    }
}
```

```
ana@vm:~/access$ javac Main.java && java Main
Fiction 2
ana@vm:~/access$ ls lib
Inside.java
Shelf.class
Shelf.java
```

`javac Main.java` found `lib/Shelf.java` by itself, through the `import`, and compiled it beside
its source. `Inside` has no `.class`, since it never compiled.
