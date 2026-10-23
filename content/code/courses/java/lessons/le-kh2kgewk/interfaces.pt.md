---
title: Uma interface é um contrato
version: 1
---

A classe abstrata da lição 21 era um pai com parte do trabalho por fazer. **Uma interface é outra
coisa: é uma lista de métodos que uma classe promete ter**, sem atributos e, na forma simples, sem
código. Uma classe só pode estender uma classe, e pode assinar quantas dessas promessas quiser. Essa
é toda a resposta do Java à herança múltipla: uma linha de ancestrais, e qualquer número de
contratos.

## Escrevendo uma e assinando

Num diretório novo, `~/iface`, o contrato da biblioteca para tudo o que pode ser emprestado:

```java
// Lendable.java
public interface Lendable {
    String title();

    int loanDays();
}
```

Dois métodos, sem corpo, e nenhum `public` ou `abstract` escrito: **todo método de uma interface é
público e abstrato, a menos que diga outra coisa**, então as palavras ficam de fora. Uma classe assina
o contrato com `implements` e depois tem de fornecer os dois:

```java
// Book.java
public class Book implements Lendable, Comparable<Book> {
    private final String title;

    public Book(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }

    @Override
    public int loanDays() {
        return 21;
    }

    @Override
    public int compareTo(Book other) {
        return title.compareTo(other.title);
    }
}
```

```java
// Dvd.java
public class Dvd implements Lendable {
    private final String title;

    public Dvd(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }

    @Override
    public int loanDays() {
        return 7;
    }
}
```

`Book` assina dois contratos, separados por vírgula: `Lendable`, e o `Comparable<Book>` da biblioteca
padrão, cujo único método, `compareTo`, diz como dois livros se ordenam. O `@Override` em cada método
pede ao compilador que confirme que ele cumpre de fato algo de um supertipo; a lição 24 mostra o que
isso pega. `Dvd` assina só o `Lendable`.

## Uma variável do tipo da interface

```java
// Desk.java
import java.util.ArrayList;
import java.util.List;

public class Desk {
    public static void main(String[] args) {
        List<Lendable> items = List.of(new Book("Iracema"), new Dvd("Central do Brasil"));
        for (Lendable item : items) {
            System.out.println(item.title() + ": " + item.loanDays() + " days");
        }

        List<Book> books = new ArrayList<>();
        books.add(new Book("O Guarani"));
        books.add(new Book("Dom Casmurro"));
        books.add(new Book("Iracema"));
        books.sort(null);
        System.out.println(books.get(0).title() + ", then " + books.get(1).title());
    }
}
```

```
ana@vm:~/iface$ javac *.java && java Desk
Iracema: 21 days
Central do Brasil: 7 days
Dom Casmurro, then Iracema
```

**A `List<Lendable>` guarda um livro e um DVD**, duas classes sem nenhum pai em comum além de
`Object`, e o laço chama `title()` e `loanDays()` em cada um sem saber qual tem na mão. Cada objeto
respondeu com o seu próprio método: 21 dias para o livro, 7 para o DVD. A lição 25 explica como a JVM
escolhe o método no momento da chamada.

A segunda metade usou o outro contrato. `books.sort(null)` quer dizer "ordene pela ordem dos próprios
elementos", que é o `compareTo`, e `Dom Casmurro` veio primeiro porque `D` vem antes de `I` e de `O`.
O `List.sort` foi escrito muito antes de `Book` existir. Funciona com ele porque `Book` assinou o
`Comparable`, e esse é o uso de um contrato: **código escrito contra a interface funciona com toda
classe que a assina, inclusive as escritas depois.**

## A que o compilador obriga uma classe

Uma classe que assina e não entrega é recusada:

```java
// Magazine.java
public class Magazine implements Lendable {
    @Override
    public String title() {
        return "Revista Piauí";
    }
}
```

```
ana@vm:~/iface$ javac Magazine.java
Magazine.java:2: error: Magazine is not abstract and does not override abstract method loanDays() in Lendable
public class Magazine implements Lendable {
       ^
1 error
```

A mensagem nomeia o método que falta e oferece a única saída além de escrevê-lo: uma classe
`abstract` pode deixar métodos da interface sem escrever para as suas subclasses, como fazia a da
lição 21.

E uma interface não pode ser construída, porque não há nada nela para executar:

```java
// Nope.java
public class Nope {
    public static void main(String[] args) {
        Lendable thing = new Lendable();
    }
}
```

```
ana@vm:~/iface$ javac Nope.java
Nope.java:4: error: Lendable is abstract; cannot be instantiated
        Lendable thing = new Lendable();
                         ^
1 error
```

`Lendable thing` estava certo sozinho. **Uma variável pode ter o tipo de uma interface; um objeto
nunca.** Todo objeto é instância de alguma classe, e a variável pode guardar qualquer uma que tenha
assinado.
