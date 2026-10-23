---
title: Lendo bytes que você não escreveu
version: 1
---

**Um programa que desserializa bytes vindos de fora deixa quem os escreveu escolher que classes ele
monta.** Atacantes passaram anos achando combinações de classes comuns de bibliotecas cuja
desserialização causa estrago, e a defesa não é procurá-las. É a regra da seção anterior lida ao
contrário: quem lê deve montar **só as classes que espera**, e recusar todo o resto antes de um único
objeto ser feito.

O `ObjectInputFilter`, no JDK desde o Java 9, é essa recusa. Um filtro é consultado para cada descritor
de classe do stream antes de o objeto ser criado, e para cada array antes de ele ser alocado, e responde
permitido ou rejeitado:

```java
// Filter.java: an allow-list decides which classes a stream may create
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectInputFilter;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;

public class Filter {
    record Book(String title, int year) implements Serializable {}

    record Note(String text) implements Serializable {}

    public static void main(String[] args) throws IOException {
        read("a book", bytes(new Book("Dune", 1965)));
        read("a note", bytes(new Note("not a book")));
        read("a huge array", bytes(new int[5_000_000]));
    }

    static byte[] bytes(Object o) throws IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        try (ObjectOutputStream out = new ObjectOutputStream(buffer)) {
            out.writeObject(o);
        }
        return buffer.toByteArray();
    }

    static void read(String label, byte[] data) {
        ObjectInputFilter allow = ObjectInputFilter.Config.createFilter("maxarray=10000;Filter$Book;!*");
        try (ObjectInputStream in = new ObjectInputStream(new ByteArrayInputStream(data))) {
            in.setObjectInputFilter(allow);
            System.out.println(label + ": " + in.readObject());
        } catch (IOException | ClassNotFoundException e) {
            System.out.println(label + ": " + e);
        }
    }
}
```

```
ana@vm:~/fp/serial$ java Filter.java
a book: Book[title=Dune, year=1965]
a note: java.io.InvalidClassException: filter status: REJECTED
a huge array: java.io.InvalidClassException: filter status: REJECTED
```

## Lendo o padrão

O filtro é uma string de regras separadas por `;`, lidas da esquerda para a direita:

| regra | quer dizer |
|---|---|
| `maxarray=10000` | recusar qualquer array com mais de 10.000 elementos |
| `Filter$Book` | permitir esta classe |
| `!*` | recusar tudo o que não casou com nada antes |

**O `Book` foi lido, a `Note` foi recusada**, embora seja um record perfeitamente inofensivo do mesmo
programa: ela não estava na lista, e esse é o teste inteiro. O array foi recusado pelo tamanho, antes de
vinte megabytes serem alocados para ele, o que fecha a outra porta, um stream pequeno na rede que pede uma
quantidade enorme de memória. As duas recusas são uma `InvalidClassException` dizendo
`filter status: REJECTED`, e nos dois casos **a verificação rodou antes de qualquer coisa ser montada**.

O `!*` no fim é o que faz dela uma lista de permissão. Sem ele, uma classe que não casasse com nenhuma
regra ficaria sem decisão, e o stream a leria; uma lista de classes a recusar é uma lista que alguém tem
de continuar completando.

Um filtro também pode valer para a JVM inteira, sem mexer no código, com a propriedade de sistema
`jdk.serialFilter`, por exemplo `java -Djdk.serialFilter='com.example.**;java.base/*;!*' ...`, que é o
jeito de proteger um programa cujo código que desserializa está numa biblioteca. As duas são a segunda
linha de defesa. **A primeira é não desserializar bytes de fora**, e trocar dados num formato que não dá
nome a classe nenhuma, que é o que o JSON da próxima seção é.
