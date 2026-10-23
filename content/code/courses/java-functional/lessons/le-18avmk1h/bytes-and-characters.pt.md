---
title: Bytes e caracteres
version: 1
---

**O `java.io` tem duas famílias de streams: `InputStream` e `OutputStream` movem bytes, `Reader` e
`Writer` movem caracteres.** Um arquivo, um socket e um pipe carregam bytes. Texto são caracteres. A
ponte entre os dois é uma **codificação** (encoding), a regra que transforma cada caractere em bytes e de
volta, e toda conversão entre as duas famílias nomeia uma, ou usa em silêncio a padrão da plataforma.
Esses streams não são o `Stream` das aulas 6 a 9; o nome é mais antigo, e os dois não têm relação.

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

## Seis caracteres, sete bytes

`Sertão` tem seis caracteres e o arquivo tem **sete bytes**: em UTF-8 as cinco letras do alfabeto
ocupam um byte cada, e o `ã` ocupa dois, `c3 a3`. Lida de volta com a mesma codificação, a palavra
voltou inteira. Lida como ISO-8859-1, que toma cada byte como um caractere, os dois bytes do `ã` viraram
dois caracteres, `Ã` e `£`. **Nada falhou**: nenhuma exceção, nenhum aviso, só o texto errado, e é por
isso que bugs de codificação são achados por clientes lendo o próprio nome.

A regra que os evita é **nomear a codificação onde quer que bytes virem caracteres ou caracteres virem
bytes**, e que ela seja UTF-8, a não ser que um formato diga outra coisa. Desde o Java 18 a padrão da
plataforma é UTF-8 em todo sistema, o que tirou a pior das velhas surpresas, mas um arquivo escrito por
outro programa, um sistema antigo ou uma exportação de planilha ainda pode estar em qualquer coisa, e só
o código que o lê pode dizer o que espera.

| move | lê | escreve | use para |
|---|---|---|---|
| bytes | `InputStream` | `OutputStream` | imagens, arquivos compactados, tudo o que não é texto |
| caracteres | `Reader` | `Writer` | texto, com uma codificação nomeada na fronteira |
| a ponte | `InputStreamReader` | `OutputStreamWriter` | transformar um no outro |
