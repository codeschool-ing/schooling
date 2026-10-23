---
title: What a framework does with an annotation
version: 1
---

The annotations in section 02 are read by the compiler and gone after it. The ones you meet most in
real Java code are the opposite. `@Test` in JUnit, `@GetMapping` in Spring, `@Entity` in JPA: **the
compiler does nothing with them except keep them**, and a library reads them while the program runs.
`java-back` builds a web service on exactly that. This section shows the two pieces that make it work.

## How long an annotation lives

Every annotation type declares its **retention**, how far it survives: in the source only, into the
class file, or all the way into the running program. Three made-up annotations, one of each, on the
same class:

```java
// Kept.java
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

public class Kept {
    @Retention(RetentionPolicy.SOURCE)
    @interface InSource {}

    @Retention(RetentionPolicy.CLASS)
    @interface InClassFile {}

    @Retention(RetentionPolicy.RUNTIME)
    @interface AtRunTime {}

    @InSource @InClassFile @AtRunTime
    static class Target {}

    public static void main(String[] args) {
        for (var a : Target.class.getAnnotations()) {
            System.out.println(a);
        }
    }
}
```

```
ana@vm:~/annot$ javac Kept.java && java Kept
@Kept.AtRunTime()
ana@vm:~/annot$ javap -v "Kept\$Target.class" | grep -A2 "Annotations:"
RuntimeVisibleAnnotations:
  0: #14()
    Kept$AtRunTime
RuntimeInvisibleAnnotations:
  0: #16()
    Kept$InClassFile
```

Three annotations went on `Target` and **the running program saw one**, `@AtRunTime`. The class file
shows where the other two went. `javap -v` lists the `AtRunTime` one under `RuntimeVisibleAnnotations`
and the `InClassFile` one under `RuntimeInvisibleAnnotations`: written into the class file, and not
loaded by the JVM. `InSource` is in neither, because the compiler dropped it after compiling.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"How long each retention lives. In Kept.java all three annotations are present. javac writes Kept$Target.class with InClassFile and AtRunTime and drops InSource. When java Kept runs, the JVM loads only AtRunTime, which is the one reflection can see.\"><defs><marker id=\"jv39-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kept.java</text><text x=\"110\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the source</text><rect x=\"270\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kept$Target.class</text><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the class file</text><rect x=\"520\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">java Kept</text><text x=\"610\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the running program</text><path d=\"M200 120 H268\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv39-a)\"></path><text x=\"234\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">javac</text><path d=\"M450 120 H518\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv39-a)\"></path><text x=\"484\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">JVM</text><rect x=\"40\" y=\"88\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@InSource</text><rect x=\"40\" y=\"130\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@InClassFile</text><rect x=\"290\" y=\"130\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@InClassFile</text><rect x=\"40\" y=\"172\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@AtRunTime</text><rect x=\"290\" y=\"172\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@AtRunTime</text><rect x=\"540\" y=\"172\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@AtRunTime</text><text x=\"360\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">each step keeps fewer: SOURCE stops at javac, CLASS stops at the JVM</text></svg>", "caption": "Three annotations go into the source and one comes out the other end. Only RUNTIME reaches code that runs."}
```

| retention | where it survives | who reads it |
|---|---|---|
| `SOURCE` | the `.java` file only | the compiler and source tools: `@Override`, `@SuppressWarnings` |
| `CLASS` (the default) | the `.class` file, not the running JVM | tools that read bytecode |
| `RUNTIME` | the running program | code using reflection: every framework |

`Target`'s class file is called `Kept$Target.class`, as lesson 17 explained for a nested class, and the
quotes and the backslash keep the shell from reading `$Target` as a variable.

## A framework in twenty lines

**Reflection** is the part of the library that lets a program look at classes while it runs: list a
class's methods, ask a method for its annotations, call it by name. A test framework is mostly that.
This one runs every method marked with a `RUNTIME` annotation called `@Check`:

```java
// Check.java
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Check {}
```

The checks, on a small ISBN validator. A 13-digit ISBN ends in a check digit computed from the other
twelve, so a typo in one digit is caught:

```java
// LoanChecks.java
public class LoanChecks {
    static boolean validIsbn(String isbn) {
        String d = isbn.replace("-", "");
        int sum = 0;
        for (int i = 0; i < 12; i++) {
            sum += (d.charAt(i) - '0') * (i % 2 == 0 ? 1 : 3);
        }
        return d.length() == 13 && (10 - sum % 10) % 10 == d.charAt(12) - '0';
    }

    @Check
    public void acceptsEffectiveJava() {
        if (!validIsbn("978-0-13-468599-1")) throw new AssertionError("rejected 978-0-13-468599-1");
    }

    @Check
    public void rejectsATypo() {
        if (validIsbn("978-0-13-468599-2")) throw new AssertionError("accepted 978-0-13-468599-2");
    }

    @Check
    public void acceptsTheSecondBook() {
        if (!validIsbn("978-1-61729-136-8")) throw new AssertionError("rejected 978-1-61729-136-8");
    }

    public void helper() {
        System.out.println("helper ran");
    }
}
```

```java
// Runner.java
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

public class Runner {
    public static void main(String[] args) throws Exception {
        Class<?> type = Class.forName(args[0]);
        Object instance = type.getDeclaredConstructor().newInstance();
        for (Method m : type.getDeclaredMethods()) {
            if (m.isAnnotationPresent(Check.class)) {
                try {
                    m.invoke(instance);
                    System.out.println("passed: " + m.getName());
                } catch (InvocationTargetException e) {
                    System.out.println("FAILED: " + m.getName() + ": " + e.getCause().getMessage());
                }
            }
        }
    }
}
```

```
ana@vm:~/annot$ javac Check.java LoanChecks.java Runner.java && java Runner LoanChecks
passed: acceptsEffectiveJava
passed: rejectsATypo
FAILED: acceptsTheSecondBook: rejected 978-1-61729-136-8
```

`Runner` was given only the class's name, as a string, and found the three marked methods on its own;
`helper` was never called, because it carries no `@Check`. That is the whole trick behind JUnit, at the
size of a lesson. **The third check failed, and it is right to.** `978-1-61729-136-8` has a check digit
that does not match its first twelve digits: it was invented for the examples of lessons 37 and 38 and
nobody ever computed it. A check found a real mistake in this course's own data.

Two details of the output are worth a second look. A method called through reflection that throws has
its exception wrapped in an `InvocationTargetException`, with the original as the cause from lesson 38,
so `Runner` reports `e.getCause()`. And `getDeclaredMethods()` does not promise any order. These came
out in the order they were written, and a framework that wants an order has to sort them itself.
