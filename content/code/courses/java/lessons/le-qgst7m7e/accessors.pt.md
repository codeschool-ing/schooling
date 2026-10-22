---
title: Getters, setters e a verificação que mora neles
version: 1
---

A reclamação de sempre sobre getters e setters é que são cerimônia: dois métodos para escrever por
atributo, sem fazer nada que um atributo público não faria. **Quando um setter só atribui, a
reclamação é justa.** O sentido de um método de acesso é a linha para a qual um atributo público não
tem lugar, e o jeito mais rápido de enxergá-la é uma classe sem método de acesso nenhum.

## Um atributo público aceita qualquer coisa

Salve os dois arquivos num diretório novo, `~/encap`:

```java
// OpenBook.java
public class OpenBook {
    public String title;
    public int year;
}
```

```java
// OpenDemo.java
public class OpenDemo {
    public static void main(String[] args) {
        OpenBook book = new OpenBook();
        book.title = "Dom Casmurro";
        book.year = -1899;
        System.out.println(book.title + " (" + book.year + ")");
    }
}
```

```
ana@vm:~/encap$ javac OpenBook.java OpenDemo.java && java OpenDemo
Dom Casmurro (-1899)
```

Um livro publicado no ano menos 1899, e **ninguém reclamou**: nem o compilador, nem a JVM, nem o
programa. O erro vai aparecer em outro lugar, mais tarde, no primeiro código que confiar no ano, e
esse código não vai ter ideia de quem o escreveu. Com um atributo público, `OpenBook` nem consegue
saber o momento em que o ano muda, porque nenhum código dela roda quando isso acontece.

## O mesmo livro, com o atributo privado

```java
// Book.java
public class Book {
    private final String title;
    private int year;

    public Book(String title, int year) {
        this.title = title;
        this.year = checkYear(year);
    }

    public String getTitle() {
        return title;
    }

    public int getYear() {
        return year;
    }

    public void setYear(int year) {
        this.year = checkYear(year);
    }

    private static int checkYear(int year) {
        if (year < 1450 || year > 2100) {
            throw new IllegalArgumentException("year out of range: " + year);
        }
        return year;
    }
}
```

Quatro coisas mudaram, e cada uma está trabalhando:

- **Os dois atributos são `private`**, então o único código que consegue escrever `year` está dentro
  de `Book`.
- `title` também é `final` e tem getter e nenhum setter: depois de construído o livro, o título fica
  fixo. Deixar o setter de fora é uma decisão, e a mais comum que uma classe toma.
- `getYear()` e `setYear(int)` seguem a convenção de nomes JavaBeans que toda ferramenta Java
  espera: `get` mais o nome do atributo com maiúscula, `set` para quem escreve, e `is` no lugar de
  `get` para um `boolean`, como em `isAvailable()`.
- **Toda escrita passa por `checkYear`**, inclusive a do construtor. Uma verificação só no setter
  deixaria `new Book("x", -1899)` como atalho.

`BookDemo` constrói um livro válido e depois tenta o ano ruim:

```java
// BookDemo.java
public class BookDemo {
    public static void main(String[] args) {
        Book book = new Book("Dom Casmurro", 1899);
        System.out.println(book.getTitle() + " (" + book.getYear() + ")");
        book.setYear(-1899);
        System.out.println("never printed");
    }
}
```

```
ana@vm:~/encap$ javac Book.java BookDemo.java && java BookDemo; echo $?
Dom Casmurro (1899)
Exception in thread "main" java.lang.IllegalArgumentException: year out of range: -1899
	at Book.checkYear(Book.java:25)
	at Book.setYear(Book.java:20)
	at BookDemo.main(BookDemo.java:6)
1
```

**O valor ruim agora para o programa na linha que o escreveu**: a última linha do stack trace é
`BookDemo.java:6`, a chamada `setYear(-1899)`, e `never printed` nunca foi impresso. A lição 36 lê
um stack trace direito. O que importa aqui é para onde ele aponta: para o culpado, e não para a
vítima.

E dar a volta no setter deixou de ser opção:

```java
// Sneaky.java
public class Sneaky {
    public static void main(String[] args) {
        Book book = new Book("Dom Casmurro", 1899);
        book.year = -1899;
    }
}
```

```
ana@vm:~/encap$ javac Sneaky.java
Sneaky.java:5: error: year has private access in Book
        book.year = -1899;
            ^
1 error
```

## Quando um setter simples ainda vale a pena

Um setter sem verificação, `this.year = year;` e mais nada, compra menos hoje. Ainda assim compra um
lugar: no dia em que a regra chegar, a verificação entra num método só e todos os chamadores a
recebem, onde um atributo público obrigaria a encontrar e mudar cada linha que o escreve. Dentro de
um programa pequeno esse custo é pequeno. Numa biblioteca que outras equipes compilam, é um build
quebrado para cada uma delas.

**Escreva o getter quando alguém precisa ler o valor. Escreva o setter só quando alguém de fato
precisa mudá-lo**, e ponha a regra nele. Uma classe com getter e setter para cada atributo, sem
nenhum deles verificar nada, tem o custo do encapsulamento e nenhuma da proteção.
