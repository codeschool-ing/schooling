---
title: A serialização do próprio Java
version: 1
---

**A serialização transforma um objeto em bytes que podem ser guardados ou enviados, e a desserialização
monta o objeto de novo a partir deles.** O Java tem o seu próprio formato desde o 1.1: uma classe que
implementa a interface marcadora `Serializable` pode ser gravada por um `ObjectOutputStream` e lida de
volta por um `ObjectInputStream`, os decoradores da aula 19 embrulhados em qualquer stream de bytes:

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

A lista saiu como 191 bytes e voltou igual. **O segundo comando mostra o que são esses bytes**: o `tr`
trocou cada byte que não é um caractere imprimível por um ponto, e o que sobra dá para ler. O arquivo dá
o nome das classes a montar, `java.util.CollSer` (a forma que o `List.of` toma ao ser gravado) e
`Shelve$Book`, depois os nomes dos campos e os seus tipos, depois os valores.

## Um formato que dá nome às suas classes

Esse último ponto é o projeto inteiro e o problema inteiro. **O `readObject` monta as classes que os
bytes nomearem**, desde que estejam no class path e sejam serializáveis, e só depois o cast para
`List<Book>` confere o que saiu. Montar um objeto de uma classe pode rodar código dela, e num class path
de verdade há milhares de classes serializáveis que ninguém escolheu.

O formato tem outros custos também. Só o Java o lê. Ele amarra os bytes à classe: renomeie um campo, e um
arquivo gravado no mês passado deixa de ser lido, a menos que a classe declare um `serialVersionUID` e
alguém escreva código para fazer a ponte. E o `readObject` é um construtor que pula o construtor, então as
verificações de um record rodam, mas as de uma classe comum não.

Os arquitetos do Java já chamaram a serialização de erro em público, e **código novo não deve usá-la para
guardar ou enviar dados**. Ainda vale conhecê-la, porque ela está em código antigo, em caches e em alguns
frameworks, e porque a defesa contra o seu perigo faz parte do JDK. Essa é a próxima seção.
