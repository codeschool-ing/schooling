---
title: Comments, and the ones that become documentation
version: 1
---

Java has three kinds of comment, and two of them are for the people reading the source. **The third
is read by a tool**, `javadoc`, which turns it into the web pages every Java library is documented
with, including the JDK's own. A program with all three, in `~/syntax`:

```java
// Greeter.java
/**
 * Builds the greetings the library's front desk prints.
 */
public class Greeter {
    /*
     * The desk asked for a full stop at the end,
     * so every greeting ends with one.
     */
    private static final String END = ".";

    /**
     * Returns a greeting for one member.
     *
     * @param name the member's name, as it appears on their card
     * @return the greeting, ending with a full stop
     */
    public static String greet(String name) {
        return "Welcome, " + name + END; // END is defined above
    }

    public static void main(String[] args) {
        System.out.println(greet("Ana"));
    }
}
```

| comment | starts and ends | read by |
|---|---|---|
| line | `//` to the end of the line | people |
| block | `/*` to `*/`, across lines | people |
| documentation | `/**` to `*/`, directly above a class, method or field | people and `javadoc` |

The compiler throws all three away. `java Greeter.java` prints exactly what it would print without
them:

```
ana@vm:~/syntax$ java Greeter.java
Welcome, Ana.
```

## What a comment is for

**A comment says why, and the code says what.** The block comment above `END` is the useful kind:
nobody could tell from `"."` that the front desk asked for it, and the next person who wants to
remove the full stop now knows whom to ask. The line comment at the end of `greet`, `// END is
defined above`, is the useless kind, and it is there on purpose so you can see one. It repeats what
any reader can see, and the day `END` moves it becomes false.

## `javadoc`, and the pages it builds

A documentation comment sits directly above what it documents. Its first sentence is the summary
that lists show, and **tags** starting with `@` describe the pieces: `@param` for each parameter,
`@return` for the result. `javadoc` reads them and writes a website:

```
ana@vm:~/syntax$ javadoc -quiet -d docs Greeter.java
Greeter.java:5: warning: use of default constructor, which does not provide a comment
public class Greeter {
       ^
Greeter.java:22: warning: no comment
    public static void main(String[] args) {
                       ^
2 warnings
ana@vm:~/syntax$ ls docs | head -5
Greeter.html
allclasses-index.html
allpackages-index.html
element-list
help-doc.html
ana@vm:~/syntax$ grep -o "Returns a greeting for one member." docs/Greeter.html | head -1
Returns a greeting for one member.
```

Two warnings, and both are about what has **no** documentation comment. `main` has none, and neither
does the constructor the compiler wrote for `Greeter`, which lesson 1 met in `javap`'s output and
which `javadoc` documents like any other public member. Warnings do not stop it: the pages are in
`docs`, with `Greeter.html` among them, and the sentence from `greet`'s comment is in that page.
Open `docs/index.html` in a browser and the layout is the one the JDK's own documentation uses.

`-quiet` kept `javadoc` from printing its progress, a line for each step and each page it writes,
and the warnings came through anyway,
because a warning is always shown. **That is the use of `javadoc` in a project: it is the check
that every public piece carries its documentation**, and the pages are a side effect.
