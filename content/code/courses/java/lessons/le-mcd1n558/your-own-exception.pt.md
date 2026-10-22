---
title: Uma exceção sua
version: 1
---

As exceções do JDK nomeiam o que deu errado nos termos do JDK: um arquivo faltou, uma string não era
número, um índice saiu do intervalo. Um programa tem falhas próprias que nenhum desses nomes descreve.
**Um membro que já tem dois livros não pode pegar um terceiro**, e dizer isso com
`IllegalStateException` conta a quem chamou que algo deu errado sem dizer o quê. Uma classe sua diz o
quê, e pode carregar os detalhes de que quem chama precisa para agir.

## Uma verificada, para uma falha que quem chama consegue tratar

Escrever uma exige uma classe que estenda o ancestral certo e um construtor que passe uma mensagem
para cima:

```java
// LoanNotAllowedException.java
public class LoanNotAllowedException extends Exception {
    private final String memberId;

    public LoanNotAllowedException(String memberId, String reason) {
        super("member " + memberId + " may not borrow: " + reason);
        this.memberId = memberId;
    }

    public String memberId() {
        return memberId;
    }
}
```

Três decisões estão nessas linhas:

1. **O nome termina em `Exception`**, como toda classe de exceção do JDK. Quem lê sabe o que ela é
   antes de ler o corpo.
2. **Ela estende `Exception`, então é verificada.** Um empréstimo recusado é um acontecimento comum no
   balcão de uma biblioteca, e quem chama consegue fazer algo sensato com ele: avisar o membro. Ser
   verificada quer dizer que o compilador não deixa nenhum chamador esquecer disso.
3. **O `super(...)` monta a mensagem**, que é o que o `getMessage()` devolve e o que um stack trace
   imprime. O campo `memberId` é o extra que quem chama pode querer, guardado como dado em vez de
   enterrado no texto.

O balcão que a lança, com limite de dois livros, e um `main` que tenta emprestar três:

```java
// Desk.java
import java.util.HashMap;
import java.util.Map;

public class Desk {
    static final int LIMIT = 2;
    private final Map<String, Integer> loans = new HashMap<>();

    public void lend(String memberId, String isbn) throws LoanNotAllowedException {
        int held = loans.getOrDefault(memberId, 0);
        if (held >= LIMIT) {
            throw new LoanNotAllowedException(memberId, "already holds " + held + " books");
        }
        loans.put(memberId, held + 1);
        System.out.println("lent " + isbn + " to " + memberId);
    }

    public static void main(String[] args) {
        Desk desk = new Desk();
        String[] isbns = {"978-0-13-468599-1", "978-1-61729-136-8", "978-0-596-00920-5"};
        for (String isbn : isbns) {
            try {
                desk.lend("ana", isbn);
            } catch (LoanNotAllowedException e) {
                System.out.println("refused: " + e.getMessage());
                System.out.println("tell member " + e.memberId() + " at the desk");
            }
        }
    }
}
```

```
ana@vm:~/hierarchy$ javac LoanNotAllowedException.java Desk.java && java Desk
lent 978-0-13-468599-1 to ana
lent 978-1-61729-136-8 to ana
refused: member ana may not borrow: already holds 2 books
tell member ana at the desk
```

O terceiro empréstimo foi recusado, e o `catch` usou as duas metades da exceção: a mensagem para a
linha de log e o `memberId()` para o passo seguinte. **O `throws LoanNotAllowedException` no `lend` faz
parte da assinatura dele**, tanto quanto os parâmetros. Um chamador que nem a captura nem a declara é
recusado na compilação:

```java
// Careless.java
public class Careless {
    public static void main(String[] args) {
        new Desk().lend("ana", "978-0-13-468599-1");
    }
}
```

```
ana@vm:~/hierarchy$ javac Careless.java
Careless.java:4: error: unreported exception LoanNotAllowedException; must be caught or declared to be thrown
        new Desk().lend("ana", "978-0-13-468599-1");
                       ^
1 error
```

## Uma não verificada, e a causa que ela carrega

Algumas falhas não deixam a quem chama nada de sensato a fazer. Se o arquivo do catálogo não pode ser
lido, o código que pede um livro não consegue consertar um disco, e obrigar todo chamador a capturar o
problema só produz blocos `catch` vazios, que são o assunto da seção 04. **Uma falha assim é uma
`RuntimeException`**, e ela sobe até a camada que consegue relatá-la, muitas vezes o topo do programa
ou de uma requisição.

O que ela não pode perder é a exceção original. Todo construtor de exceção do JDK tem uma forma que
recebe uma `Throwable cause`, e repassá-la é questão de declarar a mesma forma:

```java
// CatalogueUnavailableException.java
public class CatalogueUnavailableException extends RuntimeException {
    public CatalogueUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

```java
// Catalogue.java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

public class Catalogue {
    static List<String> load(Path file) {
        try {
            return Files.readAllLines(file);
        } catch (IOException e) {
            throw new CatalogueUnavailableException("cannot load the catalogue from " + file, e);
        }
    }

    public static void main(String[] args) {
        List<String> books = load(Path.of(args[0]));
        System.out.println(books.size() + " books");
    }
}
```

O `load` captura a `IOException` que não consegue tratar e lança a exceção nova com **uma mensagem nos
termos deste programa e a original como causa**. Com um arquivo, funciona; sem ele, relata as duas
camadas:

```
ana@vm:~/hierarchy$ javac CatalogueUnavailableException.java Catalogue.java
ana@vm:~/hierarchy$ printf "Effective Java\nJava Concurrency in Practice\n" > catalogue.txt && java Catalogue catalogue.txt
2 books
ana@vm:~/hierarchy$ java Catalogue missing.txt
Exception in thread "main" CatalogueUnavailableException: cannot load the catalogue from missing.txt
	at Catalogue.load(Catalogue.java:12)
	at Catalogue.main(Catalogue.java:17)
Caused by: java.nio.file.NoSuchFileException: missing.txt
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
	at java.base/java.nio.file.Files.readAllLines(Files.java:3085)
	at java.base/java.nio.file.Files.readAllLines(Files.java:3122)
	at Catalogue.load(Catalogue.java:10)
	... 1 more
```

O trace agora tem duas partes. O topo diz o que falhou neste programa, `cannot load the catalogue
from missing.txt`, em `Catalogue.load`. **O `Caused by:` diz por quê**, com a exceção do próprio JDK e
os frames dela. A última linha, `... 1 more`, diz que um frame do trace da causa é o mesmo frame que
está acima, `Catalogue.main`, e não é repetido.

Esse é o terceiro jeito de duas exceções viajarem juntas. A exceção suprimida da lição 37 é uma
segunda falha *ao lado* da primeira; uma causa é a falha *embaixo* dela, o motivo pelo qual a de fora
foi lançada. O `getCause()` a devolve, e uma biblioteca de log imprime a cadeia inteira quando recebe
a de fora.
