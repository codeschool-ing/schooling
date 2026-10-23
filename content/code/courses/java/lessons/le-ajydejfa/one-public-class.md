---
title: One public class per file
version: 1
---

Lesson 3 met the rule that a file is named after its public class. Its other half is that **a file
may hold only one public class**, and any number of classes that are not public. In a new directory,
`~/catalogue`, here is a file with two public classes in it:

```java
// Catalogue.java
public class Catalogue {
    public static void main(String[] args) {
        Entry e = new Entry();
        e.title = "Grande Sertão: Veredas";
        System.out.println(e.title);
    }
}

public class Entry {
    String title;
}
```

```
ana@vm:~/catalogue$ javac Catalogue.java
Catalogue.java:10: error: class Entry is public, should be declared in a file named Entry.java
public class Entry {
       ^
1 error
```

The compiler has no objection to `Entry` sharing the file. It objects to `Entry` being **public**
there, because a public class must be findable by its name: when another class anywhere refers to
`Entry`, the compiler looks for `Entry.java`. Two ways out, then. Move `Entry` into a file of its
own, `Entry.java`, or take `public` away. Taking it away:

```java
// Catalogue.java
public class Catalogue {
    public static void main(String[] args) {
        Entry e = new Entry();
        e.title = "Grande Sertão: Veredas";
        System.out.println(e.title);
    }
}

class Entry {
    String title;
}
```

```
ana@vm:~/catalogue$ javac Catalogue.java && java Catalogue
Grande Sertão: Veredas
ana@vm:~/catalogue$ ls
Catalogue.class
Catalogue.java
Entry.class
```

**One source file, two class files.** The JVM never sees `.java` files; it loads one `.class` per
class, and `javac` wrote one for each. `Entry` is now package-private, the level of section 02, so
only classes in the same package can use it, which is exactly right for a helper that exists only to
serve `Catalogue`.

In practice almost every class gets a file of its own, public or not, because a file named after
what it holds is the one people find. A small non-public helper in its user's file is the common
exception. Lesson 17 shows a third option, a class declared inside another.
