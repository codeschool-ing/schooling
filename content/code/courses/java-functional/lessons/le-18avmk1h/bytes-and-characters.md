---
title: Bytes and characters
version: 1
---

**`java.io` has two families of streams: `InputStream` and `OutputStream` move bytes, `Reader` and
`Writer` move characters.** A file, a socket and a pipe carry bytes. Text is characters. The bridge
between them is an **encoding**, the rule that turns each character into bytes and back, and every
conversion between the two families names one, or silently uses the platform's default. These streams
are not the `Stream` of lessons 6 to 9; the name is older, and the two are unrelated.

```java
// Encoding.java: one word written as UTF-8 and read back two ways
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.Writer;
import java.nio.charset.StandardCharsets;

public class Encoding {
    public static void main(String[] args) throws IOException {
        try (Writer out = new OutputStreamWriter(new FileOutputStream("word.txt"), StandardCharsets.UTF_8)) {
            out.write("Sertão");
        }

        try (FileInputStream in = new FileInputStream("word.txt")) {
            byte[] bytes = in.readAllBytes();
            System.out.print(bytes.length + " bytes:");
            for (byte b : bytes) {
                System.out.printf(" %02x", b);
            }
            System.out.println();
        }

        System.out.println("read as UTF-8:      " + read(StandardCharsets.UTF_8));
        System.out.println("read as ISO-8859-1: " + read(StandardCharsets.ISO_8859_1));
    }

    static String read(java.nio.charset.Charset charset) throws IOException {
        try (Reader in = new InputStreamReader(new FileInputStream("word.txt"), charset)) {
            StringBuilder text = new StringBuilder();
            int c;
            while ((c = in.read()) != -1) {
                text.append((char) c);
            }
            return text.toString();
        }
    }
}
```

```
ana@vm:~/fp/io$ java Encoding.java
7 bytes: 53 65 72 74 c3 a3 6f
read as UTF-8:      Sertão
read as ISO-8859-1: SertÃ£o
```

## Six characters, seven bytes

`Sertão` has six characters and the file has **seven bytes**: in UTF-8 the five letters of the
alphabet take one byte each, and `ã` takes two, `c3 a3`. Read back with the same encoding, the word
came back whole. Read as ISO-8859-1, which takes every byte as one character, the two bytes of `ã`
became two characters, `Ã` and `£`. **Nothing failed**: no exception, no warning, just the wrong text,
which is why encoding bugs are found by customers reading their own names.

The rule that prevents them is to **name the encoding wherever bytes become characters or characters
become bytes**, and to make it UTF-8 unless a format says otherwise. Since Java 18 the platform default
is UTF-8 on every system, which removed the worst of the old surprises. But a file written by another
program, an old system or a spreadsheet export can still be in anything, and only the code that reads it
can say what it expects.

| moves | read | write | use for |
|---|---|---|---|
| bytes | `InputStream` | `OutputStream` | images, archives, anything that is not text |
| characters | `Reader` | `Writer` | text, with an encoding named at the boundary |
| the bridge | `InputStreamReader` | `OutputStreamWriter` | turning one into the other |
