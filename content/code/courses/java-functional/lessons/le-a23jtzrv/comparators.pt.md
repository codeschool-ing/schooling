---
title: Comparators montados a partir de chaves
version: 1
---

**`Comparator.comparing(chave)` monta um comparator a partir de uma função que extrai o que
comparar**, e o `thenComparing` acrescenta a regra para os empates. Juntos, eles trocam o comparator
escrito à mão, com sua subtração e seus `if` aninhados, por uma descrição da ordem:

```java
// Orders.java: comparators described by their keys
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class Orders {
    record Book(String title, String author, int year, String series) {}

    static void show(String label, List<Book> books, Comparator<Book> order) {
        List<Book> sorted = new ArrayList<>(books);
        sorted.sort(order);
        System.out.println(label);
        for (Book b : sorted) {
            System.out.println("  " + b.author() + ", " + b.year() + ", " + b.title());
        }
    }

    public static void main(String[] args) {
        List<Book> books = List.of(
                new Book("Dune", "Herbert", 1965, "Dune"),
                new Book("Persuasion", "Austen", 1817, null),
                new Book("Middlemarch", "Eliot", 1871, null),
                new Book("Children of Dune", "Herbert", 1976, "Dune"),
                new Book("Emma", "Austen", 1815, null));

        show("by author, then newest first:", books,
                Comparator.comparing(Book::author)
                        .thenComparing(Book::year, Comparator.reverseOrder()));

        show("the same, with reversed() at the end:", books,
                Comparator.comparing(Book::author)
                        .thenComparing(Book::year)
                        .reversed());

        show("books in a series first:", books,
                Comparator.comparing(Book::series, Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparingInt(Book::year));
    }
}
```

```
ana@vm:~/fp/composition$ java Orders.java
by author, then newest first:
  Austen, 1817, Persuasion
  Austen, 1815, Emma
  Eliot, 1871, Middlemarch
  Herbert, 1976, Children of Dune
  Herbert, 1965, Dune
the same, with reversed() at the end:
  Herbert, 1976, Children of Dune
  Herbert, 1965, Dune
  Eliot, 1871, Middlemarch
  Austen, 1817, Persuasion
  Austen, 1815, Emma
books in a series first:
  Herbert, 1965, Dune
  Herbert, 1976, Children of Dune
  Austen, 1815, Emma
  Austen, 1817, Persuasion
  Eliot, 1871, Middlemarch
```

A primeira ordem se lê como está escrita: **por autor e, entre os livros de um autor, por ano, do
mais novo para o mais antigo.** `thenComparing(Book::year, Comparator.reverseOrder())` recebe um
segundo argumento, o comparator a usar nessa chave, e só essa chave é invertida.

## `reversed()` inverte tudo o que veio antes

A segunda ordem parece a primeira com a inversão levada para o fim, e não é. Herbert agora vem antes
de Eliot e Austen. **`reversed()` é chamado no comparator montado até ali**, então inverteu a ordem
dos autores e a dos anos juntas. Os anos continuaram saindo do mais novo para o mais antigo, porque
a ordem de anos que ele inverteu era do mais antigo para o mais novo; só os autores denunciam o
engano. Esse é o erro mais comum em cadeias de comparators, e a saída o mostra claramente, e é por
isso que vale imprimir uma vez o resultado de uma ordem nova antes de confiar nela.

## Chaves ausentes

`series` é `null` em três livros, e um `comparing(Book::series)` simples lançaria uma
`NullPointerException` na primeira vez que comparasse um deles. `Comparator.nullsLast(...)` embrulha
um comparator e decide para onde vão os valores `null`, aqui depois de todo o resto.
`Comparator.naturalOrder()` é a ordem que um tipo define para si, alfabética para strings. Então os
dois livros de Dune vieram primeiro, em ordem de ano graças ao `thenComparingInt`, e os livros sem
série vieram depois.

`thenComparingInt` e `comparingInt` recebem uma `ToIntFunction` e comparam valores `int` sem
embrulhá-los, a mesma troca da seção 04 da aula 2. Use-os para chaves numéricas.
