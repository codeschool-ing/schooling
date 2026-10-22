---
title: What the angle brackets buy
version: 1
---

Every collection in lessons 31 to 34 was written with a type in angle brackets: `List<String>`,
`Map<String, Integer>`. The brackets are **generics**, and they arrived in Java 5, in 2004. Before
that a `List` held `Object`, anything at all, and each element came out as an `Object` to be cast
back to what you hoped it was. **The brackets move the hope to the compiler, where it becomes a
check.**

Java still compiles the old form, called a **raw type**, so that code from before 2004 keeps
building. It makes a good demonstration of what the brackets prevent. Save this in a new directory,
`~/generics`:

```java
// Raw.java
import java.util.ArrayList;
import java.util.List;

public class Raw {
    static List titles() {
        List list = new ArrayList();
        list.add("Dune");
        list.add("Emma");
        list.add(1965);                 // a year, by mistake
        return list;
    }

    public static void main(String[] args) {
        List shelf = titles();
        for (Object o : shelf) {
            String title = (String) o;
            System.out.println(title.toUpperCase());
        }
    }
}
```

```
ana@vm:~/generics$ javac Raw.java
Note: Raw.java uses unchecked or unsafe operations.
Note: Recompile with -Xlint:unchecked for details.
ana@vm:~/generics$ javac -Xlint:unchecked Raw.java
Raw.java:8: warning: [unchecked] unchecked call to add(E) as a member of the raw type List
        list.add("Dune");
                ^
  where E is a type-variable:
    E extends Object declared in interface List
Raw.java:9: warning: [unchecked] unchecked call to add(E) as a member of the raw type List
        list.add("Emma");
                ^
  where E is a type-variable:
    E extends Object declared in interface List
Raw.java:10: warning: [unchecked] unchecked call to add(E) as a member of the raw type List
        list.add(1965);                 // a year, by mistake
                ^
  where E is a type-variable:
    E extends Object declared in interface List
3 warnings
ana@vm:~/generics$ java Raw
DUNE
EMMA
Exception in thread "main" java.lang.ClassCastException: class java.lang.Integer cannot be cast to class java.lang.String (java.lang.Integer and java.lang.String are in module java.base of loader 'bootstrap')
	at Raw.main(Raw.java:17)
```

Read the three commands in order. The plain `javac` compiled the file and added two `Note:` lines,
which are easy to read past. With `-Xlint:unchecked` the notes became three warnings, one per `add`:
**the compiler could not check what went into a raw list**, and said so. Then the program ran, printed
two titles, and failed on the third element with a `ClassCastException`.

The exception points at line 17, the cast in `main`. **The mistake is on line 10**, in another
method, where a year went into a list of titles. In this file the two are seven lines apart; in a
real program they can be in different classes, written by different people, and the stack trace
names only the place the damage was found.

## The same program, with a type

`Typed.java` is the same program with `<String>` written in. Nothing else changed:

```java
// Typed.java
import java.util.ArrayList;
import java.util.List;

public class Typed {
    static List<String> titles() {
        List<String> list = new ArrayList<>();
        list.add("Dune");
        list.add("Emma");
        list.add(1965);                 // a year, by mistake
        return list;
    }

    public static void main(String[] args) {
        for (String title : titles()) {
            System.out.println(title.toUpperCase());
        }
    }
}
```

```
ana@vm:~/generics$ javac Typed.java
Typed.java:10: error: incompatible types: int cannot be converted to String
        list.add(1965);                 // a year, by mistake
                 ^
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
1 error
```

**The program does not compile, and the error is on line 10**, at the `add` that was wrong, before
anything ran. That is the whole bargain: the type in brackets is a promise about every element, and
the compiler holds every line of the program to it. The cast disappeared as well; the `for-each`
receives `String`s because the list's type says that is all it holds.

So the rule is short. **Never write a raw type in new code**, and treat the `unchecked` note as a
warning rather than as noise: it means some line in the file let an unchecked value into a
collection.
