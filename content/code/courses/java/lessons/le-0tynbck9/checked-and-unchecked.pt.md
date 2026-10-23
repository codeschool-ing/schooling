---
title: Checadas e não checadas, e o que o compilador exige
version: 1
---

As exceções da seção 02 surpreenderam o compilador tanto quanto o programa: nada no `Fine.java`
dizia que o `parseInt` poderia lançar, e o `javac` o compilou sem uma palavra. Algumas exceções são
diferentes. **Para uma exceção checada, o compilador insiste em que cada método a capture ou declare
que a lança**, e recusa o arquivo do contrário.

Ler um arquivo é o exemplo clássico. Este programa conta os empréstimos de `loans.txt`, um por linha:

```java
// Count.java
import java.nio.file.Files;
import java.nio.file.Path;

public class Count {
    public static void main(String[] args) {
        String text = Files.readString(Path.of("loans.txt"));
        System.out.println(text.lines().count() + " loans");
    }
}
```

```
ana@vm:~/exc$ javac Count.java
Count.java:7: error: unreported exception IOException; must be caught or declared to be thrown
        String text = Files.readString(Path.of("loans.txt"));
                                      ^
1 error
```

O `Files.readString` declara `throws IOException`, porque um arquivo pode faltar, estar ilegível ou
num disco que acabou de sumir. **`IOException` é checada**, então o compilador parou na chamada e
nomeou as duas escolhas: capturá-la ali, ou declará-la, o que passa a obrigação a quem chama o
`main`.

Declarar é uma mudança, na linha que declara o `main`:

```java
// Count.java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class Count {
    public static void main(String[] args) throws IOException {
        String text = Files.readString(Path.of("loans.txt"));
        System.out.println(text.lines().count() + " loans");
    }
}
```

```
ana@vm:~/exc$ javac Count.java && java Count
Exception in thread "main" java.nio.file.NoSuchFileException: loans.txt
	at java.base/sun.nio.fs.UnixException.translateToIOException(UnixException.java:92)
	at java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:106)
	at java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:111)
	at java.base/sun.nio.fs.UnixFileSystemProvider.newFileChannel(UnixFileSystemProvider.java:213)
	at java.base/sun.nio.fs.UnixFileSystemProvider.newByteChannel(UnixFileSystemProvider.java:244)
	at java.base/java.nio.file.Files.newByteChannel(Files.java:357)
	at java.base/java.nio.file.Files.newByteChannel(Files.java:399)
	at java.base/java.nio.file.Files.readAllBytes(Files.java:2973)
	at java.base/java.nio.file.Files.readString(Files.java:3043)
	at java.base/java.nio.file.Files.readString(Files.java:3006)
	at Count.main(Count.java:8)
```

**Compilou, e falhou exatamente como a declaração avisava que poderia**: `NoSuchFileException`, uma
`IOException`, porque ainda não havia `loans.txt`. Dez quadros dentro do JDK, e um seu, na linha 8.
Escreva o arquivo e execute de novo:

```
ana@vm:~/exc$ printf "Dune\nEmma\nUlysses\n" > loans.txt
ana@vm:~/exc$ java Count
3 loans
```

`throws IOException` no `main` está certo para um programa deste tamanho. A JVM é quem chama o
`main`, e um stack trace é uma resposta justa a um arquivo que falta. Num programa maior, o método
que sabe o que um arquivo faltando significa, como um que mostra uma mensagem numa tela, é o que o
captura.

## Quais exceções são checadas

A regra é sobre a classe, e é curta:

| classe | checada? | para que serve | exemplos desta lição |
|---|---|---|---|
| `RuntimeException` e as suas subclasses | não | erros no programa, que um programa correto não comete | `NumberFormatException`, `ArithmeticException`, `NullPointerException` |
| outras subclasses de `Exception` | **sim** | condições de fora do programa, que um programa correto ainda encontra | `IOException`, `NoSuchFileException` |
| `Error` e as suas subclasses | não | a própria JVM em apuros | `OutOfMemoryError`, `StackOverflowError` |

A lógica está na coluna do meio. **Uma exceção checada é uma para a qual um programa correto precisa
estar pronto**: um programa perfeito ainda encontra um arquivo faltando, então o compilador garante
que alguém decidiu o que fazer a respeito. Uma não checada é um defeito: `parseInt("ten")` se corrige
não passando `"ten"`, e obrigar cada chamador de `parseInt` a escrever um `catch` enterraria o
tratamento de verdade debaixo de cerimônia.

A linha foi traçada pelos projetistas do JDK e nem sempre fica onde você a traçaria; o `parseInt`
lendo entrada do usuário é, com alguma razão, uma condição de fora do programa. A lição 38 desenha a
hierarquia inteira e decide, para uma exceção do próprio curso, de que lado ela fica.
