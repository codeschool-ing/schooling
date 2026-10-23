---
title: The trouble with null
version: 1
---

**A method that may find nothing has to say so somehow, and for most of Java's history it said so by
returning `null`.** Nothing in the method's signature warned the caller. `Edition findOrNull(String
title)` and a method that never returns `null` look exactly the same, so the caller either checks
every result, which nobody does, or finds out at run time, somewhere further on.

This lesson works on a small catalogue of editions, some of them translations. Save it in
`~/fp/optional`:

```java
// Catalogue.java: four editions, two of them translations, and two ways to look one up
import java.util.List;
import java.util.Optional;

public class Catalogue {
    public record Edition(String title, String author, String translator, long priceCents) {}

    static final List<Edition> EDITIONS = List.of(
            new Edition("Dom Casmurro", "Machado de Assis", null, 3490),
            new Edition("The Posthumous Memoirs of Brás Cubas", "Machado de Assis",
                    "Margaret Jull Costa and Robin Patterson", 5290),
            new Edition("Grande Sertão: Veredas", "João Guimarães Rosa", null, 7990),
            new Edition("The Devil to Pay in the Backlands", "João Guimarães Rosa",
                    "James L. Taylor and Harriet de Onís", 6490));

    static Edition findOrNull(String title) {
        for (Edition e : EDITIONS) {
            if (e.title().equals(title)) {
                return e;
            }
        }
        return null;
    }

    static Optional<Edition> find(String title) {
        return EDITIONS.stream().filter(e -> e.title().equals(title)).findFirst();
    }
}
```

`translator` is `null` for the two editions in their original Portuguese, which is the field's honest
value: there is no translator. Now a caller that forgets:

```java
// NullTrouble.java: a null that travels before it fails
public class NullTrouble {
    public static void main(String[] args) {
        Catalogue.Edition edition = Catalogue.findOrNull("Dom Casmurro");
        String translator = edition.translator();
        System.out.println("translated by " + translator.toUpperCase());
    }
}
```

```
ana@vm:~/fp/optional$ java NullTrouble.java
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "String.toUpperCase()" because "<local2>" is null
	at NullTrouble.main(NullTrouble.java:6)
```

## Where it failed, and where the mistake was

The program failed on line 6, calling `toUpperCase()`. The mistake was the assumption, two lines
earlier, that every edition has a translator. **A `null` fails where it is used, not where it came
from**, and in real code those can be a dozen methods and two modules apart.

The message is better than it used to be: since Java 15 the JVM says by default which expression
was `null`, not only the line. Here it says `"<local2>"`, the variable in slot 2 of the method's
frame, because the source-file mode compiles without the table of local names. Compiled with `javac -g`, which keeps it, the same
failure names the variable:

```
ana@vm:~/fp/optional$ javac -g -d out Catalogue.java NullTrouble.java
ana@vm:~/fp/optional$ java -cp out NullTrouble
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "String.toUpperCase()" because "translator" is null
	at NullTrouble.main(NullTrouble.java:6)
```

Maven compiles with that table by default, so in a project the message reads like the second one.
Either way, it is still a failure at run time, found by whoever ran that path first.

The same trap waits behind `findOrNull`: ask for a title the catalogue does not have, and `edition`
itself is `null`, and the failure moves one line up. Neither return type said that nothing was a
possible answer. The next section is the type that does.
