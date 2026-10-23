---
title: Quando o sistema de arquivos diz não
version: 1
---

**Todo método de `Files` informa uma recusa com uma exceção que diz o que deu errado e em que caminho.**
Todas são subclasses de `FileSystemException`, que é uma `IOException`, então o código pode capturar
aquela para a qual tem um plano e deixar o resto subir:

```java
// Failures.java: three things the file system refuses, each with its own exception
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class Failures {
    public static void main(String[] args) throws IOException {
        Path shelf = Path.of("shelf");
        Files.createDirectories(shelf);
        Files.writeString(shelf.resolve("dune.txt"), "Dune\n");

        attempt("read a missing file", () -> Files.readString(Path.of("missing.txt")));
        attempt("create it again", () -> Files.createDirectory(shelf));
        attempt("create it again, leniently", () -> Files.createDirectories(shelf));
        attempt("delete it while full", () -> Files.delete(shelf));
    }

    interface Action {
        void run() throws IOException;
    }

    static void attempt(String label, Action action) {
        try {
            action.run();
            System.out.println(label + ": done");
        } catch (IOException e) {
            System.out.println(label + ": " + e.getClass().getSimpleName() + ", " + e.getMessage());
        }
    }
}
```

```
ana@vm:~/fp/files$ java Failures.java
read a missing file: NoSuchFileException, missing.txt
create it again: FileAlreadyExistsException, shelf
create it again, leniently: done
delete it while full: DirectoryNotEmptyException, shelf
```

Cada recusa chegou com a sua própria classe: **`NoSuchFileException`** para o arquivo que falta,
**`FileAlreadyExistsException`** para um diretório criado duas vezes, **`DirectoryNotEmptyException`**
para um apagamento que teria perdido um arquivo. O `createDirectories` é o tolerante: um diretório que já
está lá é o que pediram a ele, então ele retornou sem reclamar. A mensagem é o caminho, e a classe diz o
que aconteceu com ele. `Action` é uma interface funcional do próprio programa porque pode lançar
`IOException`, o mesmo problema que os auxiliares da seção 04 resolveram do outro jeito.

## Um nome de fora fica dentro

Um servidor que entrega arquivos de uma pasta tira o nome da requisição, e a requisição é escrita por
quem a manda. `../` é uma parte legítima de um caminho, então **um nome juntado à pasta sem conferência
pode apontar para qualquer lugar que o programa tenha permissão de ler**. A defesa é resolver o nome,
normalizar o resultado e conferir que ele ainda começa pela pasta:

```java
// Inside.java: a name that arrives from outside must stay inside its directory
import java.nio.file.Path;

public class Inside {
    static final Path BASE = Path.of("library").toAbsolutePath().normalize();

    static Path inside(String name) {
        Path p = BASE.resolve(name).normalize();
        if (!p.startsWith(BASE)) {
            throw new IllegalArgumentException("outside the library: " + name);
        }
        return p;
    }

    public static void main(String[] args) {
        for (String name : new String[] {"dune.txt", "fiction/../emma.txt", "../orders.csv", "/etc/hostname"}) {
            try {
                System.out.println(name + " -> " + BASE.relativize(inside(name)));
            } catch (IllegalArgumentException e) {
                System.out.println(name + " -> refused, " + e.getMessage());
            }
        }

        Path sibling = BASE.resolve("../library-old/notes.txt").normalize();
        System.out.println("as strings: " + sibling.toString().startsWith(BASE.toString()));
        System.out.println("as paths:   " + sibling.startsWith(BASE));
    }
}
```

```
ana@vm:~/fp/files$ java Inside.java
dune.txt -> dune.txt
fiction/../emma.txt -> emma.txt
../orders.csv -> refused, outside the library: ../orders.csv
/etc/hostname -> refused, outside the library: /etc/hostname
as strings: true
as paths:   false
```

`fiction/../emma.txt` voltou para dentro, então foi aceito; `../orders.csv` saiu, então foi recusado. O
quarto é o caso que as pessoas esquecem: **`resolve` com um caminho absoluto ignora a base por inteiro** e
devolve o outro caminho, então `/etc/hostname` passou como ele mesmo e só a conferência o parou.

As duas últimas linhas são o motivo de a conferência ser `Path.startsWith` e não `String.startsWith`. Uma
pasta chamada `library-old` começa com as letras `library`, e uma conferência no texto a aceitou. O
`Path.startsWith` compara nomes inteiros, `library` contra `library-old`, e a recusou.

Uma coisa que o `normalize` não consegue ver é um link simbólico: ele lê nomes, não o disco, então um link
dentro da pasta que aponta para fora passa pela conferência. Onde a pasta puder ter links, confira o
`toRealPath()`, que pergunta ao disco para onde o caminho leva de verdade, e rejeite o nome se o caminho
real estiver fora.
