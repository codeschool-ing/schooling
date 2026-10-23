---
title: try-with-resources
version: 1
---

O Java 7 acrescentou uma forma de `try` que fecha as coisas sozinha. Você declara o recurso entre
parênteses depois do `try`, e **o compilador escreve o `finally` por você**, inclusive as partes que a
seção 02 errou. A única coisa que ele pede ao recurso é que a classe implemente uma interface com um
método, `java.lang.AutoCloseable`, cujo método é `close()`.

O `Resource` já tem um `close()`, então duas mudanças o qualificam: `implements AutoCloseable` na linha
da classe, e `@Override` acima do `close`, que a lição 24 explicou e a lição 39 retoma. Substitua o
`~/twr/Resource.java` por esta versão:

```java
// Resource.java
public class Resource implements AutoCloseable {
    private final String name;
    private final boolean failOnClose;

    public Resource(String name, boolean failOnClose) {
        this.name = name;
        this.failOnClose = failOnClose;
        System.out.println("open " + name);
    }

    public void use(boolean fail) {
        System.out.println("use " + name);
        if (fail) {
            throw new IllegalStateException("use of " + name + " failed");
        }
    }

    @Override
    public void close() {
        System.out.println("close " + name);
        if (failOnClose) {
            throw new IllegalStateException("close of " + name + " failed");
        }
    }
}
```

Depois, o vazamento da seção 02, escrito do jeito novo:

```java
// Twr.java
public class Twr {
    public static void main(String[] args) {
        try (Resource r = new Resource("loans.db", false)) {
            r.use(true);
        }
    }
}
```

```
ana@vm:~/twr$ javac Resource.java Twr.java Order.java CountLines.java
ana@vm:~/twr$ java Twr
open loans.db
use loans.db
close loans.db
Exception in thread "main" java.lang.IllegalStateException: use of loans.db failed
	at Resource.use(Resource.java:15)
	at Twr.main(Twr.java:5)
```

**O `close loans.db` foi impresso antes de a exceção sair do `main`.** Sem `finally`, sem variável fora
do bloco, e a variável `r` só existe dentro do `try`, então nenhum código depois dele consegue usar um
recurso fechado por engano. Essa última parte passa despercebida com facilidade: no `Finally.java` a
variável continuava visível depois do fechamento, e nada impedia uma linha posterior de chamar
`r.use(false)` nela.

## Dois recursos, e a ordem em que fecham

Vários recursos vão nos mesmos parênteses, separados por ponto e vírgula. Um `catch` e um `finally`
podem vir depois, como em qualquer `try`:

```java
// Order.java
public class Order {
    public static void main(String[] args) {
        try (Resource db = new Resource("loans.db", false);
             Resource log = new Resource("audit.log", false)) {
            db.use(false);
            log.use(true);
        } catch (IllegalStateException e) {
            System.out.println("caught: " + e.getMessage());
        } finally {
            System.out.println("finally");
        }
    }
}
```

```
ana@vm:~/twr$ java Order
open loans.db
open audit.log
use loans.db
use audit.log
close audit.log
close loans.db
caught: use of audit.log failed
finally
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"A ordem dos eventos em Order.java. loans.db abre, depois audit.log abre. O corpo usa os dois e lança. audit.log fecha, depois loans.db fecha. Só então o catch roda, e o finally roda por último. Cada recurso só existe dentro da própria caixa.\"><defs><marker id=\"jv37-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"22\" width=\"400\" height=\"176\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"70\" y=\"57\" width=\"340\" height=\"106\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"100\" y=\"92\" width=\"280\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">open loans.db</text><text x=\"240\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">open audit.log</text><text x=\"240\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">use loans.db, use audit.log: throws</text><text x=\"240\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">close audit.log</text><text x=\"240\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">close loans.db</text><rect x=\"40\" y=\"212\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">catch: caught: use of audit.log failed</text><rect x=\"40\" y=\"252\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"267\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">finally</text><text x=\"462\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aberto em segundo</text><text x=\"462\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">então fecha primeiro</text><text x=\"462\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aberto primeiro</text><text x=\"462\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e este fecha por último</text><text x=\"462\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o corpo lança aqui</text><text x=\"462\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o tratador roda depois de todos os fechamentos</text><text x=\"462\" y=\"267\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e o finally depois disso</text></svg>", "caption": "Cada recurso é fechado quando o bloco que o abriu termina, o mais interno primeiro, e antes que qualquer catch veja a exceção."}
```

Três coisas nessa saída, e cada uma é uma regra:

1. **Os recursos abrem na ordem em que são escritos e fecham na ordem inversa.** O `audit.log` foi
   aberto em segundo, então fechou primeiro. Um recurso posterior pode depender de um anterior, um
   writer construído sobre um arquivo por exemplo, e fechar em ordem inversa nunca tira o chão de
   debaixo dele.
2. **Os dois fechamentos rodaram antes do `catch`.** Quando o seu tratador vê a exceção, todo recurso
   já foi devolvido, então o tratador não consegue usá-los e não precisa fechá-los.
3. O `finally` rodou por último, depois do `catch`, como em qualquer `try`.

## Um recurso de verdade

Os próprios arquivos, streams, readers, writers, sockets e conexões com banco do JDK implementam
`AutoCloseable`, a maioria pela sub-interface mais antiga `java.io.Closeable`. Este programa conta as
linhas de um arquivo com um `BufferedReader` de `java.nio.file.Files`:

```java
// CountLines.java
import java.io.BufferedReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class CountLines {
    public static void main(String[] args) throws IOException {
        int lines = 0;
        try (BufferedReader in = Files.newBufferedReader(Path.of(args[0]))) {
            while (in.readLine() != null) {
                lines++;
            }
        }
        System.out.println(args[0] + ": " + lines + " lines");
    }
}
```

Crie um arquivo de três linhas para contar, e depois peça um que não existe:

```
ana@vm:~/twr$ printf "978-0-13-468599-1 ana\n978-1-61729-136-8 rui\n978-0-596-00920-5 ana\n" > loans.txt
ana@vm:~/twr$ java CountLines loans.txt
loans.txt: 3 lines
ana@vm:~/twr$ java CountLines missing.txt
Exception in thread "main" java.nio.file.NoSuchFileException: missing.txt
	at java.base/sun.nio.fs.UnixException.translateToIOException(UnixException.java:92)
	at java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:106)
	at java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:111)
	at java.base/sun.nio.fs.UnixFileSystemProvider.newFileChannel(UnixFileSystemProvider.java:213)
	at java.base/sun.nio.fs.UnixFileSystemProvider.newByteChannel(UnixFileSystemProvider.java:244)
	at java.base/java.nio.file.Files.newByteChannel(Files.java:357)
	at java.base/java.nio.file.Files.newByteChannel(Files.java:399)
	at java.base/java.nio.file.spi.FileSystemProvider.newInputStream(FileSystemProvider.java:371)
	at java.base/java.nio.file.Files.newInputStream(Files.java:154)
	at java.base/java.nio.file.Files.newBufferedReader(Files.java:2645)
	at java.base/java.nio.file.Files.newBufferedReader(Files.java:2674)
	at CountLines.main(CountLines.java:10)
```

O reader foi fechado nos dois caminhos. No segundo, o `Files.newBufferedReader` lançou antes de o
reader existir, então não havia o que fechar, e **o try-with-resources só fecha o que foi de fato
aberto**: um recurso cujo inicializador lança nunca é fechado, porque não está lá. O stack trace longo
são os métodos do próprio JDK, de cima para baixo; a última linha,
`CountLines.main(CountLines.java:10)`, é a que pertence a você, e aponta para a linha do `try`. O
`throws IOException` no `main` é a exceção verificada da lição 36, repassada em vez de tratada.

## O que não se qualifica

Uma classe sem `AutoCloseable` é recusada na compilação, por mais óbvio que pareça o uso:

```java
// NotCloseable.java
public class NotCloseable {
    public static void main(String[] args) {
        try (StringBuilder sb = new StringBuilder()) {
            sb.append("loan");
        }
    }
}
```

```
ana@vm:~/twr$ javac NotCloseable.java
NotCloseable.java:4: error: incompatible types: try-with-resources not applicable to variable type
        try (StringBuilder sb = new StringBuilder()) {
                           ^
    (StringBuilder cannot be converted to AutoCloseable)
1 error
```

O `StringBuilder` guarda só memória, então não tem nada a devolver nem método `close`, e o compilador
diz exatamente isso. **A regra é a interface, não o nome de um método**: o primeiro `Resource` da
seção 02 tinha um `close()` perfeitamente bom e teria sido recusado do mesmo jeito.
