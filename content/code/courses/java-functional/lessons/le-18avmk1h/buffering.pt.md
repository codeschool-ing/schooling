---
title: Buffer
version: 1
---

**`FileInputStream.read()` pede ao sistema operacional um byte toda vez que é chamado.** Cada pedido é
uma chamada de sistema, uma ida do programa ao kernel e a volta, e a viagem custa muito mais que o byte.
Um `BufferedInputStream` em volta dele pede um bloco de 8.192 bytes de uma vez e os entrega um por vez a
partir da memória. O código que lê não muda; o número de viagens, sim:

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

Ler os mesmos 5 MB um byte por vez levou 1.198 ms sem buffer e 95 ms com buffer, **mais de doze vezes
mais rápido** com o mesmo laço e a mesma soma. A versão sem buffer fez mais de cinco milhões de viagens
ao kernel; a com buffer cerca de 640, uma por bloco de 8.192 bytes. Escrever tem a mesma forma, e
`BufferedOutputStream` e `BufferedWriter` são o remédio ali, com uma regra a mais: um buffer que nunca é
esvaziado (flush) nem fechado nunca chega ao arquivo.

## A cadeia de decoradores

`new BufferedInputStream(new FileInputStream("data.bin"))` é um stream embrulhado em outro, cada um
acrescentando uma coisa: o de dentro conversa com o arquivo, o de fora acrescenta um buffer. **O
`java.io` é construído assim do começo ao fim**, que é o padrão decorator da seção 04 da aula 4 escrito
como classes. Um arquivo de texto costuma ser lido por três camadas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Três caixas aninhadas. A de fora é BufferedReader, que acrescenta readLine e um buffer. Dentro dela está InputStreamReader, que transforma bytes em caracteres usando UTF-8. Dentro dessa está FileInputStream, que lê bytes do arquivo shelf.txt. Os bytes saem do arquivo para fora e chegam como linhas de texto.\"><defs><marker id=\"layers-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"520\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">BufferedReader</text><text x=\"30\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linhas e um buffer</text><rect x=\"50\" y=\"72\" width=\"460\" height=\"96\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">InputStreamReader</text><text x=\"60\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">bytes em caracteres, UTF-8</text><rect x=\"260\" y=\"118\" width=\"236\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">FileInputStream</text><text x=\"378.0\" y=\"145.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shelf.txt</text><rect x=\"570\" y=\"75\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">linhas de texto</text><path d=\"M540 100 L566 100\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#layers-ah-phosphor)\"></path></svg>", "caption": "Cada camada embrulha a de dentro e acrescenta uma coisa; fechar a de fora fecha todas."}
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

As duas versões leem as mesmas linhas. O `Files.newBufferedReader` monta as três camadas para você,
com UTF-8 como codificação, e a aula 20 trata do `Files` e do resto da API mais nova a que ele pertence.
A forma em camadas ainda vale ser conhecida, porque os streams de um socket (aula 23) chegam como bytes
crus e precisam do mesmo embrulho à mão.
