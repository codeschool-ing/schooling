---
title: Uma variável atribuída uma vez
version: 1
---

**`final` numa variável quer dizer que ela é atribuída exatamente uma vez**, e o compilador recusa
uma segunda atribuição. A lição 15 o usou numa constante; ele funciona em qualquer variável, e os usos
mais comuns nem são constantes. Num diretório novo, `~/final`, o caso mais simples:

```java
// Locals.java
public class Locals {
    public static void main(String[] args) {
        final int maxLoans = 3;
        maxLoans = 4;
    }
}
```

```
ana@vm:~/final$ javac Locals.java
Locals.java:5: error: cannot assign a value to final variable maxLoans
        maxLoans = 4;
        ^
1 error
```

## Um atributo que todo construtor tem de definir

Num atributo, o `final` diz algo mais útil: **cada objeto recebe o valor uma vez, enquanto está sendo
construído, e fica com ele.** O ISBN de um livro identifica aquele livro, e um livro cujo ISBN
mudasse no meio da vida seria outro livro usando a identidade do antigo. Um atributo `final` sem valor
na declaração é um *blank final*, e o compilador confere que todo construtor o atribui. Aqui o
segundo construtor esquece:

```java
// Book.java
class Book {
    final String isbn;
    String title;

    Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }

    Book(String title) {
        this.title = title;
    }
}
```

```
ana@vm:~/final$ javac Book.java
Book.java:13: error: variable isbn might not have been initialized
    }
    ^
1 error
```

O acento circunflexo aponta para a chave que fecha `Book(String title)`, linha 13: o lugar onde o
construtor termina sem ter definido `isbn`. Esta é a verificação que a lição 13 prometeu: **com
`final`, o compilador recusa um construtor que deixa o atributo no padrão**, onde o `Copy` da lição 13
deixou `null` para trás em silêncio.

A outra metade da regra é que nada atribui o atributo depois do construtor:

```java
// Book.java
class Book {
    final String isbn;
    String title;

    Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }

    void fixIsbn(String corrected) {
        isbn = corrected;
    }
}
```

```
ana@vm:~/final$ javac Book.java
Book.java:12: error: cannot assign a value to final variable isbn
        isbn = corrected;
        ^
1 error
```

Um livro com ISBN errado se corrige criando um `Book` novo, não editando o antigo. Sem o `fixIsbn` e
com um construtor só, a classe compila, e o `javap` mostra o modificador onde a JVM também o enxerga:

```java
// Book.java
class Book {
    final String isbn;
    String title;

    Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }
}
```

```
ana@vm:~/final$ javac Book.java && javap -p Book
Compiled from "Book.java"
class Book {
  final java.lang.String isbn;
  java.lang.String title;
  Book(java.lang.String, java.lang.String);
}
```

## Uma referência final para algo que muda

A surpresa vem com as referências. **O `final` fixa a variável, e a variável guarda uma referência,
então o que fica fixo é a qual objeto ela leva.** O objeto em si pode mudar tanto quanto a classe
dele permitir:

```java
// Notes.java
public class Notes {
    public static void main(String[] args) {
        final StringBuilder note = new StringBuilder("Due");
        note.append(" on Friday");
        System.out.println(note);

        final int[] counts = {1, 2, 3};
        counts[0] = 9;
        System.out.println(counts[0] + " " + counts.length);
    }
}
```

```
ana@vm:~/final$ javac Notes.java && java Notes
Due on Friday
9 3
```

As duas variáveis são `final`, e o `StringBuilder` da lição 7 cresceu, e o primeiro elemento do array
virou 9. O que o `final` recusa é apontar a variável para outro lugar:

```java
// Reassign.java
public class Reassign {
    public static void main(String[] args) {
        final StringBuilder note = new StringBuilder("Due");
        note = new StringBuilder("Overdue");
    }
}
```

```
ana@vm:~/final$ javac Reassign.java
Reassign.java:5: error: cannot assign a value to final variable note
        note = new StringBuilder("Overdue");
        ^
1 error
```

Então um atributo `final` que guarda uma lista, da lição 31 em diante, continua sendo uma lista a que
qualquer um com a referência pode acrescentar itens. **Um objeto que não muda nunca precisa de todo
atributo final e de que o objeto de cada atributo também não mude**, que é o que a `String` é, e de
que os records da lição 29 chegam perto.
