---
title: Construtores, para um objeto nunca ficar pela metade
version: 1
---

A seção 02 terminou numa armadilha: um atributo que ninguém definiu é `null`, e nada diz se isso foi
intencional. O `UseBook` criou um livro e depois definiu o título e o ano em mais duas linhas, e um
programa que esquecesse uma delas teria um livro sem título e sem reclamação. **Um construtor é o
código que roda enquanto o `new` cria o objeto**, e se ele recebe os valores como parâmetros, não há
como criar o objeto sem eles.

A seção 04 tem um `Book` próprio, então trabalha num diretório novo, `~/ctors`:

```java
// Book.java
class Book {
    String isbn;
    String title;
    int year;

    Book(String isbn, String title, int year) {
        this.isbn = isbn;
        this.title = title;
        this.year = year;
    }

    Book(String isbn, String title) {
        this(isbn, title, 0);
    }
}
```

Um construtor parece um método, com duas diferenças: **o nome dele é o nome da classe, e ele não
declara tipo de retorno**, nem `void`. Esta classe tem dois. O primeiro recebe os três valores e os
guarda, usando `this` exatamente como o `rename` fez na seção 03. O segundo recebe dois e os repassa
ao primeiro com `this(...)`, acrescentando 0 para o ano, de modo que o armazenamento é escrito uma
vez só. Uma chamada a outro construtor com `this(...)` tem de ser o primeiro comando do construtor.

```java
// Main.java
public class Main {
    public static void main(String[] args) {
        Book a = new Book("978-85-359-0277-1", "Dom Casmurro", 1899);
        Book b = new Book("978-85-01-01234-5", "Untitled draft");
        System.out.println(a.title + ", " + a.year);
        System.out.println(b.title + ", " + b.year);
    }
}
```

```
ana@vm:~/ctors$ javac Main.java && java Main
Dom Casmurro, 1899
Untitled draft, 0
ana@vm:~/ctors$ javap -p Book
Compiled from "Book.java"
class Book {
  java.lang.String isbn;
  java.lang.String title;
  int year;
  Book(java.lang.String, java.lang.String, int);
  Book(java.lang.String, java.lang.String);
}
```

O `new Book(...)` escolheu um construtor pelos argumentos que recebeu, três ou dois. E veja o que o
`javap` lista: os dois construtores escritos no arquivo, e **nenhum `Book()`**.

## O construtor de graça vai embora quando você escreve um

As lições 1 e 12 encontraram um construtor que ninguém escreveu, `Book()`, que o compilador acrescenta
a uma classe que não declara nenhum. Declare qualquer construtor e o compilador não acrescenta nada,
então o código que dependia do antigo deixa de compilar:

```java
// OldMain.java
public class OldMain {
    public static void main(String[] args) {
        Book empty = new Book();
    }
}
```

```
ana@vm:~/ctors$ javac OldMain.java
OldMain.java:4: error: no suitable constructor found for Book(no arguments)
        Book empty = new Book();
                     ^
    constructor Book.Book(String,String,int) is not applicable
      (actual and formal argument lists differ in length)
    constructor Book.Book(String,String) is not applicable
      (actual and formal argument lists differ in length)
1 error
```

**Esse erro é o objetivo do construtor, não um efeito colateral.** Um livro sem ISBN e sem título não
pode mais ser criado por descuido. A mensagem lista todos os construtores da classe e por que cada um
não serve, o que a torna o jeito mais rápido de descobrir o que uma classe espera.

## O parâmetro que esconde o atributo

Esqueça o `this` num construtor e o programa compila, roda, e perde o valor:

```java
// Copy.java
class Copy {
    String barcode;

    Copy(String barcode) {
        barcode = barcode;
    }
}
```

```java
// CopyMain.java
public class CopyMain {
    public static void main(String[] args) {
        Copy c = new Copy("BC-0001");
        System.out.println(c.barcode);
    }
}
```

```
ana@vm:~/ctors$ javac CopyMain.java && java CopyMain
null
```

Dentro do construtor, o parâmetro `barcode` esconde o atributo `barcode`, então `barcode = barcode`
atribui o parâmetro a ele mesmo. O atributo fica com o padrão, `null`, e o `javac` não imprimiu aviso
nenhum. **Quando um parâmetro tem o nome de um atributo, escreva `this.` do lado do atributo, sempre.**
A lição 16 mostra um jeito de fazer o compilador recusar um construtor que deixa um atributo sem
valor, e a lição 27 dá a ordem completa em que os atributos, os inicializadores e os construtores de
um objeto rodam.
