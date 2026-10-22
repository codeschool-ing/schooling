---
title: Reading bytes you did not write
version: 1
---

**A program that deserialises bytes from outside lets whoever wrote them choose which classes it
builds.** Attackers have spent years finding combinations of ordinary library classes whose
deserialisation does harm, and the defence is not to look for them. It is the rule of the last section
read the other way round: a reader should build **only the classes it expects**, and refuse everything
else before a single object is made.

`ObjectInputFilter`, in the JDK since Java 9, is that refusal. A filter is consulted for every class
descriptor in the stream before the object is created, and for every array before it is allocated, and
answers allowed or rejected:

```java
// Filter.java: an allow-list decides which classes a stream may create
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectInputFilter;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;

public class Filter {
    record Book(String title, int year) implements Serializable {}

    record Note(String text) implements Serializable {}

    public static void main(String[] args) throws IOException {
        read("a book", bytes(new Book("Dune", 1965)));
        read("a note", bytes(new Note("not a book")));
        read("a huge array", bytes(new int[5_000_000]));
    }

    static byte[] bytes(Object o) throws IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        try (ObjectOutputStream out = new ObjectOutputStream(buffer)) {
            out.writeObject(o);
        }
        return buffer.toByteArray();
    }

    static void read(String label, byte[] data) {
        ObjectInputFilter allow = ObjectInputFilter.Config.createFilter("maxarray=10000;Filter$Book;!*");
        try (ObjectInputStream in = new ObjectInputStream(new ByteArrayInputStream(data))) {
            in.setObjectInputFilter(allow);
            System.out.println(label + ": " + in.readObject());
        } catch (IOException | ClassNotFoundException e) {
            System.out.println(label + ": " + e);
        }
    }
}
```

```
ana@vm:~/fp/serial$ java Filter.java
a book: Book[title=Dune, year=1965]
a note: java.io.InvalidClassException: filter status: REJECTED
a huge array: java.io.InvalidClassException: filter status: REJECTED
```

## Reading the pattern

The filter is one string of rules separated by `;`, read left to right:

| rule | means |
|---|---|
| `maxarray=10000` | refuse any array longer than 10,000 elements |
| `Filter$Book` | allow this class |
| `!*` | refuse everything that matched nothing before |

**The `Book` was read, the `Note` was refused**, though it is a perfectly harmless record of the same
program: it was not on the list, and that is the whole test. The array was refused by its length, before
twenty megabytes were allocated for it, which closes the other door, a stream that is small on the wire
and asks for an enormous amount of memory. Both refusals are an `InvalidClassException` saying
`filter status: REJECTED`, and in both cases **the check ran before anything was built**.

The `!*` at the end is what makes it an allow-list. Without it a class that matched no rule would be
left undecided, and the stream would read it; a list of classes to refuse is a list somebody has to keep
finishing.

A filter can also be set for the whole JVM, without touching the code, with the system property
`jdk.serialFilter`, for example `java -Djdk.serialFilter='com.example.**;java.base/*;!*' ...`, which
is the way to protect a program whose deserialising code is in a library. Both are the second line of
defence. **The first is not to deserialise bytes from outside at all**, and to exchange data in a format
that names no classes, which is what JSON in the next section is.
