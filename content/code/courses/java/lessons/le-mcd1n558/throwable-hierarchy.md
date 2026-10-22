---
title: One family, two branches
version: 1
---

Lesson 36 drew a line between checked and unchecked exceptions and left one question open: **where
does the line come from?** It is not a flag on each class. It comes from the class's ancestors. Every
exception and every error in Java is a subclass of one class, `java.lang.Throwable`, and which branch
of that family tree a class sits on decides what the compiler asks of you.

A program can walk the tree itself. `getSuperclass()` returns the class a class extends, and following
it until it returns `null` gives the whole line of ancestors:

```java
// Ancestry.java
import java.util.List;

public class Ancestry {
    public static void main(String[] args) {
        List<Class<?>> types = List.of(
                java.nio.file.NoSuchFileException.class,
                NumberFormatException.class,
                StackOverflowError.class);
        for (Class<?> type : types) {
            StringBuilder line = new StringBuilder(type.getSimpleName());
            for (Class<?> up = type.getSuperclass(); up != null; up = up.getSuperclass()) {
                line.append(" -> ").append(up.getSimpleName());
            }
            System.out.println(line);
        }
    }
}
```

```
ana@vm:~/hierarchy$ javac Ancestry.java Deep.java && java Ancestry
NoSuchFileException -> FileSystemException -> IOException -> Exception -> Throwable -> Object
NumberFormatException -> IllegalArgumentException -> RuntimeException -> Exception -> Throwable -> Object
StackOverflowError -> VirtualMachineError -> Error -> Throwable -> Object
```

Three lines, three branches:

- **`NoSuchFileException` passes through `IOException`** on its way to `Exception`. That makes it
  checked: a method that may throw it has to say so, as `throws IOException` did in lesson 37.
- **`NumberFormatException` passes through `RuntimeException`**, and everything under
  `RuntimeException` is unchecked. `Integer.parseInt` throws it, and nobody is forced to catch it.
- **`StackOverflowError` never meets `Exception` at all.** It descends from `Error`, the other branch
  under `Throwable`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"The Throwable hierarchy. Throwable has two branches. Error, with VirtualMachineError and below it StackOverflowError and OutOfMemoryError, is unchecked. Exception has IOException, with NoSuchFileException under it, which are checked, and RuntimeException, with IllegalArgumentException and NumberFormatException under it, which are unchecked.\"><rect x=\"300\" y=\"16\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Throwable</text><rect x=\"40\" y=\"86\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Error</text><rect x=\"440\" y=\"86\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Exception</text><path d=\"M360 46 V66 H140 V86 M360 66 H540 V86\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"40\" y=\"146\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VirtualMachineError</text><path d=\"M140 116 V146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"16\" y=\"206\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">StackOverflowError</text><rect x=\"150\" y=\"206\" width=\"112\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">OutOfMemoryError</text><path d=\"M140 176 V191 H80 V206 M140 191 H206 V206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"376\" y=\"146\" width=\"148\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IOException</text><rect x=\"540\" y=\"146\" width=\"164\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RuntimeException</text><path d=\"M540 116 V131 H450 V146 M540 131 H622 V146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"370\" y=\"206\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NoSuchFileException</text><path d=\"M450 176 V206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"536\" y=\"206\" width=\"172\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IllegalArgumentException</text><path d=\"M622 176 V206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"546\" y=\"256\" width=\"152\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NumberFormatException</text><path d=\"M622 236 V256\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"262\" width=\"14\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">unchecked: the compiler asks nothing</text><rect x=\"20\" y=\"286\" width=\"14\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"293\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">checked: catch it or declare it</text></svg>", "caption": "Every exception and error is a Throwable. What the compiler checks is decided by the branch: RuntimeException and Error and everything under them are exempt."}
```

## `Error` is the JVM's, not yours

An `Error` reports a problem with the machine the program runs on rather than with the program's
data: the thread ran out of stack, the heap ran out of memory, a class file that was there at compile
time is missing at run time. **The usual reaction to an `Error` is to let the program end**, because
the JVM may no longer be in a state where your recovery code can run correctly.

A first consequence surprises people. `catch (Exception e)` looks like it catches everything, and it
does not catch an `Error`:

```java
// Deep.java
public class Deep {
    static int depth = 0;

    static void down() {
        depth++;
        down();
    }

    public static void main(String[] args) {
        try {
            down();
        } catch (Exception e) {
            System.out.println("caught an Exception at depth " + depth);
        }
        System.out.println("after the try");
    }
}
```

```
ana@vm:~/hierarchy$ java Deep 2>&1 | head -4
Exception in thread "main" java.lang.StackOverflowError
	at Deep.down(Deep.java:7)
	at Deep.down(Deep.java:7)
	at Deep.down(Deep.java:7)
ana@vm:~/hierarchy$ java Deep > deep.txt 2>&1; echo "exit $?"; wc -l < deep.txt; grep -c "after the try" deep.txt
exit 1
1025
0
```

`down` calls itself until the thread's stack is full, and the JVM throws `StackOverflowError`. The
`catch (Exception e)` did not match it, so neither `caught an Exception` nor `after the try` ever
printed: `grep -c` counted 0 of the latter in 1025 lines of output, and the exit status was 1. The
1025 lines are the first line plus 1024 frames, all `Deep.down(Deep.java:7)`. **The JVM stops
printing a stack trace at 1024 frames**, so a very deep recursion never shows you the frame where it
started.

Writing `catch (Throwable t)` instead would catch it. Code that does that, logs a line and carries on
as if nothing happened is running on a JVM that has just said it is in trouble. The exceptions you
catch and handle are the ones under `Exception`; the ones under `Error` are for the JVM to report and
for you to read.
