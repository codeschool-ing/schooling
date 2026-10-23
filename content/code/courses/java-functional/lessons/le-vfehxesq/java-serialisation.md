---
title: Java's own serialisation
version: 1
---

**Serialisation turns an object into bytes that can be stored or sent, and deserialisation builds the
object again from them.** Java has had its own format since 1.1: a class that implements the marker
interface `Serializable` can be written by an `ObjectOutputStream` and read back by an
`ObjectInputStream`, the decorators of lesson 19 wrapped around any byte stream:

```java
// Shelve.java: two records written to a file with Java serialisation, and read back
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

public class Shelve {
    record Book(String title, String author, int year) implements Serializable {}

    public static void main(String[] args) throws IOException, ClassNotFoundException {
        List<Book> books = List.of(new Book("Dune", "Frank Herbert", 1965), new Book("Emma", "Jane Austen", 1815));
        try (ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream("books.ser"))) {
            out.writeObject(books);
        }
        System.out.println(Files.size(Path.of("books.ser")) + " bytes");

        try (ObjectInputStream in = new ObjectInputStream(new FileInputStream("books.ser"))) {
            @SuppressWarnings("unchecked")
            List<Book> back = (List<Book>) in.readObject();
            System.out.println(back);
            System.out.println("equal: " + back.equals(books));
        }
    }
}
```

```
ana@vm:~/fp/serial$ java Shelve.java
191 bytes
[Book[title=Dune, author=Frank Herbert, year=1965], Book[title=Emma, author=Jane Austen, year=1815]]
equal: true
ana@vm:~/fp/serial$ tr -c '[:print:]' . < books.ser; echo
....sr..java.util.CollSerW...:......I..tagxp....w.....sr..Shelve$Book...........I..yearL..authort..Ljava/lang/String;L..titleq.~..xp....t..Frank Herbertt..Dunesq.~......t..Jane Austent..Emmax
```

The list went out as 191 bytes and came back equal. **The second command shows what those bytes are**:
`tr` replaced every byte that is not a printable character with a dot, and what is left is readable.
The file names the classes to build, `java.util.CollSer` (the form `List.of` takes when it is written)
and `Shelve$Book`, then the field names and their types, then the values.

## A format that names its classes

That last point is the whole design and the whole trouble. **`readObject` builds whatever classes the
bytes name**, as long as they are on the class path and serialisable, and only afterwards does the cast
to `List<Book>` check what came out. Building an object of a class can run code in it, and on a real
class path there are thousands of serialisable classes nobody chose.

The format has other costs as well. It is readable only by Java. It ties the bytes to the class: rename a
field, and a file written last month no longer reads, unless the class declares a `serialVersionUID` and
someone writes code to bridge the change. And `readObject` is a constructor that skips the constructor,
so a record's checks run, but an ordinary class's do not.

Java's architects have called serialisation a mistake in public, and **new code should not use it to
store or send data**. It is still worth knowing, because it is in old code, in caches and in some
frameworks, and because the defence against its danger is part of the JDK. That is the next section.
