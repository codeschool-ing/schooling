---
title: A field that belongs to the class
version: 1
---

Every field in lessons 12 to 14 had one copy per object, which is what a book's title or a member's
loans need. Some data is not about one object at all. How many members has the library registered?
No single member knows, and storing the number in each of them would mean updating every copy each
time. **A `static` field has one copy, belonging to the class**, shared by every object of it and
reachable with no object at all.

In a new directory, `~/static`, a member that counts how many members have been made:

```java
// Member.java
class Member {
    static int created = 0;
    String name;
    int loans = 0;

    Member(String name) {
        this.name = name;
        created = created + 1;
    }
}
```

The constructor adds one to `created` every time a member is made. Since `created` is static, it is
the same field for all of them, so it counts across the whole program:

```java
// Counter.java
public class Counter {
    public static void main(String[] args) {
        System.out.println(Member.created);
        Member a = new Member("Ana");
        Member b = new Member("Bruno");
        a.loans = a.loans + 1;
        System.out.println(Member.created + " " + a.loans + " " + b.loans);
        System.out.println(a.created + " " + b.created);
    }
}
```

```
ana@vm:~/static$ javac Counter.java && java Counter
0
2 1 0
2 2
```

The first line read `Member.created` **before any member existed**, through the class's name, and
got 0. After two constructors it is 2. `a.loans` is 1 and `b.loans` is 0, because `loans` is an
ordinary field and each member has its own:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"One class and two objects. The class Member holds one static field, created, equal to 2. Each object, Ana and Bruno, holds its own name and its own loans: Ana has 1 loan and Bruno 0. Both objects point back to the one class, so a.created and b.created read the same field.\"><defs><marker id=\"jv15-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"240\" y=\"16\" width=\"240\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the class Member, loaded once</text><rect x=\"270\" y=\"52\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">static created = 2</text><rect x=\"60\" y=\"150\" width=\"240\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">object a</text><text x=\"180\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">name = \"Ana\"</text><text x=\"180\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loans = 1</text><rect x=\"420\" y=\"150\" width=\"240\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">object b</text><text x=\"540\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">name = \"Bruno\"</text><text x=\"540\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loans = 0</text><path d=\"M180 150 V120 H330 V96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv15-a)\"></path><path d=\"M540 150 V120 H390 V96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv15-a)\"></path><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each object knows its class</text></svg>", "caption": "After Counter's two constructors: one created for the class, a name and a count of loans for each object. a.created and b.created are two ways to spell Member.created."}
```

The last line is the one that misleads. `a.created` and `b.created` look like fields of two
objects, and they are the same field, read twice. The compiler allows the spelling, and with
`-Xlint:static` it says what it thinks of it:

```
ana@vm:~/static$ javac -Xlint:static Counter.java
Counter.java:9: warning: [static] static variable should be qualified by type name, Member, instead of by an expression
        System.out.println(a.created + " " + b.created);
                            ^
Counter.java:9: warning: [static] static variable should be qualified by type name, Member, instead of by an expression
        System.out.println(a.created + " " + b.created);
                                              ^
2 warnings
```

**Write a static member through the class's name, `Member.created`, never through an object.** The
reader then knows at a glance that it is shared, which is the one thing about it that matters.

`javap` shows where the difference lives:

```
ana@vm:~/static$ javap -p Member
Compiled from "Member.java"
class Member {
  static int created;
  java.lang.String name;
  int loans;
  Member(java.lang.String);
  static {};
}
```

`created` is marked `static` and the two other fields are not. The last line, `static {}`, is code
the compiler wrote to run `created = 0` once, when the class is loaded, rather than once per object.
Lesson 27 shows such blocks in full and the order they run in.
