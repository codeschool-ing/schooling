---
title: `extends`, e o que uma subclasse ganha de graça
version: 1
---

Uma biblioteca empresta livros e DVDs. Os dois têm título e ano, os dois são emprestados por um
certo número de dias, e os dois se descrevem do mesmo jeito. Um livro também tem autor, e um DVD tem
duração. Escrever a parte comum duas vezes seria corrigir cada erro dela duas vezes. **A herança
escreve a parte comum uma vez, numa classe que as outras estendem**, e cada uma acrescenta só o que é
seu.

Crie um diretório para esta lição, `~/inherit`, e salve nele quatro arquivos. Primeiro a parte comum:

```java
// Item.java
public class Item {
    protected final String title;
    private final int year;

    public Item(String title, int year) {
        this.title = title;
        this.year = year;
    }

    public int loanDays() {
        return 14;
    }

    public String describe() {
        return title + " (" + year + "), " + loanDays() + " days";
    }
}
```

Depois duas classes que a estendem:

```java
// Book.java
public class Book extends Item {
    private final String author;

    public Book(String title, int year, String author) {
        super(title, year);
        this.author = author;
    }

    public String author() {
        return author;
    }
}
```
```java
// Dvd.java
public class Dvd extends Item {
    private final int minutes;

    public Dvd(String title, int year, int minutes) {
        super(title, year);
        this.minutes = minutes;
    }

    @Override
    public int loanDays() {
        return 7;
    }
}
```

E um programa que as usa:

```java
// Lending.java
public class Lending {
    public static void main(String[] args) {
        Book book = new Book("Effective Java", 2018, "Joshua Bloch");
        Dvd dvd = new Dvd("Metropolis", 1927, 153);
        System.out.println(book.describe());
        System.out.println(book.author());
        System.out.println(dvd.describe());
    }
}
```
```
ana@vm:~/inherit$ javac *.java && java Lending
Effective Java (2018), 14 days
Joshua Bloch
Metropolis (1927), 7 days
ana@vm:~/inherit$ javap -p Book
Compiled from "Book.java"
public class Book extends Item {
  private final java.lang.String author;
  public Book(java.lang.String, int, java.lang.String);
  public java.lang.String author();
}
```

**`Book` não declara `describe()`, e `book.describe()` funcionou.** `Book extends Item` faz de `Book`
uma **subclasse** de `Item`, a sua **superclasse**, e uma subclasse tem todo atributo e todo método
que a superclasse tem. O `javap -p Book` mostra o que o próprio `Book.class` guarda: um atributo, um
construtor e `author()`. O resto é encontrado em `Item` quando é chamado.

**`Dvd` substituiu um método.** Ele declara o seu próprio `loanDays()`, que devolve 7, e o
`describe()`, escrito uma vez em `Item`, chamou a versão do DVD: a linha do DVD diz 7 dias, a do livro
diz 14. Isso se chama **sobrescrever** (override), e o `@Override` acima do método pede ao compilador
que confira se ele substitui mesmo algum; a lição 24 é sobre os dois. A lição 25 explica como o
`describe()` soube qual `loanDays()` chamar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Uma hierarquia de classes. Book e Dvd apontam cada uma para Item, e Item aponta para java.lang.Object, que dá a toda classe toString, equals e hashCode. Item guarda um title protected, um year private, loanDays devolvendo 14 e describe. Book acrescenta um author private e author(). Dvd acrescenta um minutes private e troca loanDays por um que devolve 7.\"><defs><marker id=\"jv20-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"260\" y=\"14\" width=\"200\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">java.lang.Object</text><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">toString, equals, hashCode</text><rect x=\"240\" y=\"104\" width=\"240\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Item</text><text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">protected title</text><text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">private year</text><text x=\"360\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loanDays() 14, describe()</text><rect x=\"60\" y=\"240\" width=\"240\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"180\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">private author</text><text x=\"180\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author()</text><rect x=\"420\" y=\"240\" width=\"240\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Dvd</text><text x=\"540\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">private minutes</text><text x=\"540\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loanDays() 7</text><path d=\"M360 104 V64\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv20-a)\"></path><path d=\"M180 240 L300 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv20-a)\"></path><path d=\"M540 240 L420 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv20-a)\"></path><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">toda classe, no fim</text><text x=\"600\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que as duas dividem</text><text x=\"30\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada uma acrescenta ou troca</text></svg>", "caption": "As setas apontam para a mãe, como o extends se lê. Um Book é um Item e um Object; o que Item declara, Book tem sem escrever de novo."}
```

## `super(...)` vem primeiro

Um `Book` é um `Item` com mais coisas dentro, então construir um livro é construir antes a parte de
item. **`super(title, year)` chama o construtor da superclasse**, e a parte de item é inicializada
antes da parte de livro. Tire essa linha de `Book` e compile:

```
ana@vm:~/inherit$ sed -i 's/        super(title, year);//' Book.java && javac Book.java
Book.java:5: error: constructor Item in class Item cannot be applied to given types;
    public Book(String title, int year, String author) {
                                                       ^
  required: String,int
  found:    no arguments
  reason: actual and formal argument lists differ in length
1 error
```

Sem uma chamada explícita, o compilador insere `super()` sem argumentos, e `Item` não tem construtor
que não receba nenhum: `required: String,int`, `found: no arguments`. Uma classe cuja superclasse tem
um construtor sem argumentos pode deixar a chamada de fora; `Item` pede título e ano, então toda
subclasse tem de repassá-los. A lição 27 acrescenta o que o Java 25 permite *antes* dessa chamada.
Ponha a linha de volta antes de seguir.

## `private` continua privado, `protected` não

`title` é `protected` em `Item` e `year` é `private`. O `describe()` usa os dois, porque é método do
próprio `Item`. Uma subclasse só enxerga um deles. Mude `Book.author()` para devolver também o ano:

```
ana@vm:~/inherit$ sed -i 's/return author;/return author + ", " + year;/' Book.java && javac Book.java
Book.java:11: error: year has private access in Item
        return author + ", " + year;
                               ^
1 error
```

**`year has private access in Item`** (`year` tem acesso privado em `Item`): um `Book` *tem* um ano,
definido pelo construtor que ele chamou, e o código dele não pode tocá-lo. `private` é privado da
classe que o declara, subclasses incluídas, que é a regra da lição 14 vista de baixo. `protected` abre
um membro para as subclasses, e é por isso que `title` pode ser lido de `Book`. O conselho comum é
manter estreito até o acesso das subclasses, e dar a uma subclasse um método, e não um atributo,
quando ela precisa de algo. Desfaça também a mudança em `author()`.
