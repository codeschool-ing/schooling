---
title: Buffering
version: 1
---

**`FileInputStream.read()` asks the operating system for one byte every time it is called.** Each request
is a system call, a trip from the program into the kernel and back, and the trip costs far more than the
byte. A `BufferedInputStream` wrapped around it asks for a block of 8,192 bytes at once and hands them
out one at a time from memory. The code that reads does not change; the number of trips does:

```java
// Buffered.java: the same 5 MB read one byte at a time, with and without a buffer
import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Random;

public class Buffered {
    public static void main(String[] args) throws IOException {
        byte[] data = new byte[5 * 1024 * 1024];
        new Random(42).nextBytes(data);
        try (FileOutputStream out = new FileOutputStream("data.bin")) {
            out.write(data);
        }
        time("unbuffered", () -> new FileInputStream("data.bin"));
        time("buffered  ", () -> new BufferedInputStream(new FileInputStream("data.bin")));
    }

    interface Opener {
        InputStream open() throws IOException;
    }

    static void time(String label, Opener opener) throws IOException {
        long start = System.nanoTime();
        long sum = 0;
        try (InputStream in = opener.open()) {
            int b;
            while ((b = in.read()) != -1) {
                sum += b;
            }
        }
        System.out.printf("%s  sum %d  %6d ms%n", label, sum, (System.nanoTime() - start) / 1_000_000);
    }
}
```

```
ana@vm:~/fp/io$ java Buffered.java
unbuffered  sum 668572768    1198 ms
buffered    sum 668572768      95 ms
```

Reading the same 5 MB one byte at a time took 1,198 ms unbuffered and 95 ms with a buffer, **more than
twelve times faster** with the same loop and the same sum. The unbuffered version made over five million
trips into the kernel; the buffered one about 640, one per block of 8,192 bytes. Writing has the same
shape, and `BufferedOutputStream` and `BufferedWriter` are the cure there, with one extra rule: a buffer
that is never flushed or closed never reaches the file.

## The decorator chain

`new BufferedInputStream(new FileInputStream("data.bin"))` is a stream wrapped around a stream, each
adding one thing: the inner one talks to the file, the outer one adds a buffer. **`java.io` is built
this way throughout**, which is the decorator pattern of lesson 4 section 04 written as classes. A text
file is usually read through three layers:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Three nested boxes. The outer one is BufferedReader, which adds readLine and a buffer. Inside it is InputStreamReader, which turns bytes into characters using UTF-8. Inside that is FileInputStream, which reads bytes from the file shelf.txt. Bytes flow from the file outwards and come out as lines of text.\"><defs><marker id=\"layers-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"520\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">BufferedReader</text><text x=\"30\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lines and a buffer</text><rect x=\"50\" y=\"72\" width=\"460\" height=\"96\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">InputStreamReader</text><text x=\"60\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">bytes to characters, UTF-8</text><rect x=\"260\" y=\"118\" width=\"236\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">FileInputStream</text><text x=\"378.0\" y=\"145.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shelf.txt</text><rect x=\"570\" y=\"75\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">lines of text</text><path d=\"M540 100 L566 100\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#layers-ah-phosphor)\"></path></svg>", "caption": "Each layer wraps the one inside it and adds one thing; closing the outer one closes them all."}
```

```java
// Layers.java: three layers to read text lines from a file, and the shortcut that builds them
import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

public class Layers {
    public static void main(String[] args) throws IOException {
        Files.writeString(Path.of("shelf.txt"), "Dune\nEmma\nDom Casmurro\n", StandardCharsets.UTF_8);

        try (BufferedReader in = new BufferedReader(
                new InputStreamReader(new FileInputStream("shelf.txt"), StandardCharsets.UTF_8))) {
            String line;
            while ((line = in.readLine()) != null) {
                System.out.println("by hand:  " + line);
            }
        }

        try (BufferedReader in = Files.newBufferedReader(Path.of("shelf.txt"))) {
            System.out.println("shortcut: " + in.readLine());
        }
    }
}
```

```
ana@vm:~/fp/io$ java Layers.java
by hand:  Dune
by hand:  Emma
by hand:  Dom Casmurro
shortcut: Dune
```

The two versions read the same lines. `Files.newBufferedReader` builds the three layers for you, with
UTF-8 as its encoding, and lesson 20 is about `Files` and the rest of the newer API it belongs to. The
layered form is still worth knowing, because a socket's streams (lesson 23) arrive as bare bytes and need
the same wrapping by hand.
