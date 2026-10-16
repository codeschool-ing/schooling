---
title: Coletando num contêiner
version: 1
---

**O `collect` é a operação terminal que monta um contêiner, uma lista, um conjunto, um mapa ou uma
string, a partir dos elementos.** O `reduce` faz um valor novo a cada passo, o que é certo para um
número e um desperdício para um contêiner: reduzir strings com `+` montaria uma string nova para cada
elemento e copiaria tudo o que foi acumulado a cada vez. O `collect` cria um contêiner só e acrescenta
cada elemento a ele. As receitas para isso estão em `Collectors`:

```java
// Collect.java: four collectors, and what toMap does with a repeated key
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.stream.Collectors;

public class Collect {
    public static void main(String[] args) {
        Set<String> genres = Shelf.BOOKS.stream().map(Book::genre).collect(Collectors.toSet());
        System.out.println("genres: " + genres.size());

        String line = Shelf.BOOKS.stream()
                .filter(b -> b.genre().equals("sci-fi"))
                .map(Book::title)
                .collect(Collectors.joining(", ", "sci-fi: ", "."));
        System.out.println(line);

        Map<String, Integer> pages = Shelf.BOOKS.stream()
                .filter(b -> b.pages() > 600)
                .collect(Collectors.toMap(Book::title, Book::pages));
        System.out.println(new TreeMap<>(pages));

        try {
            Shelf.BOOKS.stream().collect(Collectors.toMap(Book::author, Book::title));
        } catch (IllegalStateException e) {
            System.out.println(e.getMessage());
        }

        Map<String, String> byAuthor = Shelf.BOOKS.stream()
                .collect(Collectors.toMap(Book::author, Book::title, (first, second) -> first + " / " + second, TreeMap::new));
        System.out.println(byAuthor.get("Frank Herbert") + " | " + byAuthor.get("Jane Austen"));
    }
}
```

```
ana@vm:~/fp/streams$ java Collect.java
genres: 4
sci-fi: Dune, Children of Dune, The Left Hand of Darkness, The Dispossessed.
{Grande Sertão: Veredas=624, Middlemarch=880, Ulysses=730}
Duplicate key Frank Herbert (attempted merging values Dune and Children of Dune)
Dune / Children of Dune | Emma / Persuasion
```

- **`toSet()`** juntou os gêneros num conjunto, que guardou cada um uma vez. Quatro gêneros. Um
  `HashSet` não tem ordem que você deva imprimir e da qual possa depender, e é por isso que a linha
  imprime o tamanho.
- **`joining(", ", "sci-fi: ", ".")`** juntou os títulos com um separador, um prefixo e um sufixo. Ele
  monta um `StringBuilder` só e acrescenta a ele, que é a versão eficiente do laço com `+`.
- **`toMap(chave, valor)`** montou um mapa de cada título para as suas páginas. Ele é impresso através
  de um `TreeMap` para as chaves saírem ordenadas.

## Uma chave repetida é erro, por padrão

`toMap(Book::author, Book::title)` falhou, e a mensagem cita a chave e os dois valores: Frank Herbert
escreveu dois livros, e um mapa guarda um valor por chave. **O `toMap` se recusa a escolher qual
manter**, o que é o padrão certo, porque qualquer escolha silenciosa perderia um livro. Quando
repetições são esperadas, o terceiro argumento diz como fundir dois valores da mesma chave; aqui os
títulos foram juntados. O quarto, `TreeMap::new`, escolhe o tipo de mapa, uma referência a construtor
usada como `Supplier`, exatamente como a seção 04 da aula 3 mostrou.

A maioria das perguntas reais sobre uma estante é sobre grupos e não sobre um mapa de um valor por
chave: livros por gênero, preço total por autor, o livro mais barato de cada década. Isso é o
`Collectors.groupingBy`, e é a aula 8.
