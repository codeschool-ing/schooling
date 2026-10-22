---
title: A armadilha: um equals que recebe um Book
version: 1
---

Toda classe herda de `Object` o `equals(Object)`, e ele diz que duas referências são iguais só
quando apontam para o mesmo objeto. Dois objetos `Book` com o mesmo ISBN são objetos diferentes,
então a biblioteca quer uma regra própria. A primeira tentativa de sempre parece certa, compila, passa
num teste rápido, e está errada.

## A tentativa

Em `~/overload/trap`:

```java
// Book.java
public class Book {
    private final String isbn;
    private final String title;

    public Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }

    public boolean equals(Book other) {
        return isbn.equals(other.isbn);
    }

    @Override
    public int hashCode() {
        return isbn.hashCode();
    }
}
```

O parâmetro é `Book`, porque um livro só deveria ser comparado com um livro. Essa palavra é o erro.
**`equals(Book)` não sobrescreve `equals(Object)`; ele o sobrecarrega**, e `Book` passa a ter dois
métodos `equals` lado a lado. Um programa que o chama diretamente não vê nada de errado:

```java
// Trap.java
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class Trap {
    public static void main(String[] args) {
        Book a = new Book("978-85-359-0277-2", "Dom Casmurro");
        Book b = new Book("978-85-359-0277-2", "Dom Casmurro");
        System.out.println("a.equals(b): " + a.equals(b));

        Set<Book> shelf = new HashSet<>();
        shelf.add(a);
        shelf.add(b);
        System.out.println("books in the set: " + shelf.size());
        System.out.println("list contains b: " + List.of(a).contains(b));

        Object asObject = b;
        System.out.println("a.equals(asObject): " + a.equals(asObject));
    }
}
```

```
ana@vm:~/overload/trap$ javac Book.java Trap.java && java Trap
a.equals(b): true
books in the set: 2
list contains b: false
a.equals(asObject): false
```

A primeira linha é o teste rápido, e passou. Depois um `HashSet` guardou **os dois livros**, embora
tenham o mesmo ISBN e o mesmo hash code, e uma lista que contém `a` disse que não continha `b`. A
última linha entrega o motivo: o mesmo `b`, guardado numa variável do tipo `Object`, não é igual a
`a`.

## Por que as coleções nunca o veem

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Book, depois do erro, tem dois métodos equals. O seu equals(Book other) compara ISBNs e é o que a.equals(b) alcança, porque as duas variáveis são declaradas Book. O equals(Object o) herdado de Object compara identidade, e é esse que HashSet.add e List.contains chamam, porque só conhecem os elementos como Object.\"><defs><marker id=\"jv24-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"250\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a.equals(b)</text><text x=\"145\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">as duas declaradas Book</text><rect x=\"20\" y=\"180\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">HashSet.add, List.contains</text><text x=\"145\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">só conhecem os elementos como Object</text><text x=\"145\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">equals(Object)</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><rect x=\"420\" y=\"60\" width=\"260\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">equals(Book other)</text><text x=\"550\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escrito por você: compara ISBNs</text><text x=\"550\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma sobrecarga, não uma sobrescrita</text><rect x=\"420\" y=\"160\" width=\"260\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">equals(Object o)</text><text x=\"550\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">herdado de Object: mesmo objeto?</text><text x=\"550\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o que as coleções chamam</text><path d=\"M270 60 L418 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv24-a)\"></path><path d=\"M270 215 L418 200\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv24-a)\"></path></svg>", "caption": "Os dois métodos ficam lado a lado em Book. O compilador escolhe entre eles pelo tipo declarado do argumento, então as coleções nunca encontram o que foi escrito."}
```

A seção 02 disse que as sobrecargas são escolhidas pelo compilador, pelos tipos declarados dos
argumentos. Em `a.equals(b)` os dois são declarados `Book`, então o compilador escolheu
`equals(Book)`, o que a Ana escreveu. O `HashSet` foi compilado anos antes de `Book` existir, e só
conhece os seus elementos como `Object`. **Toda coleção chama `equals(Object)`**, e neste `Book` essa
ainda é a versão de `Object`, que compara identidade. Então `a` e `b` eram dois objetos diferentes
para o conjunto, e os dois entraram. O mesmo vale para `asObject`: declarado `Object`, logo
`equals(Object)`, logo `false`.

## O `@Override` encontra o erro

Ponha a anotação na tentativa, como a seção 03 manda fazer em toda sobrescrita:

```java
// Book.java
public class Book {
    private final String isbn;
    private final String title;

    public Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }

    @Override
    public boolean equals(Book other) {
        return isbn.equals(other.isbn);
    }

    @Override
    public int hashCode() {
        return isbn.hashCode();
    }
}
```

```
ana@vm:~/overload/trap$ javac Book.java
Book.java:11: error: method does not override or implement a method from a supertype
    @Override
    ^
1 error
```

O compilador diz qual é o bug numa linha: **este método não sobrescreve nada.** Com a anotação, o
erro nunca chega a um conjunto.

## A sobrescrita que funciona

```java
// Book.java
public class Book {
    private final String isbn;
    private final String title;

    public Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof Book book && isbn.equals(book.isbn);
    }

    @Override
    public int hashCode() {
        return isbn.hashCode();
    }
}
```

```
ana@vm:~/overload/trap$ javac Book.java Trap.java && java Trap
a.equals(b): true
books in the set: 1
list contains b: true
a.equals(asObject): true
```

O parâmetro é `Object`, então este substitui o método herdado e todo chamador o alcança, seja qual
for o tipo que declarou. `other instanceof Book book` confere o tipo e dá nome ao resultado do cast
num passo só, então uma `String` ou um `null` simplesmente comparam como diferentes. Agora o conjunto
guarda um livro e a lista encontra `b`.

O `hashCode` estava sobrescrito o tempo todo, e isso importa tanto quanto: **dois objetos iguais
precisam ter o mesmo hash code**, senão um `HashSet` procura o segundo no lugar errado e nem chega a
perguntar ao `equals`. A lição 32 desmonta esse contrato, e os records da lição 29 escrevem os dois
métodos por você.
