---
title: Particionando em sim e não
version: 1
---

**`Collectors.partitioningBy(predicado)` divide um stream em dois grupos, os elementos que passam e os
que não passam, e devolve um mapa com exatamente duas chaves, `true` e `false`.** É um `groupingBy`
com um `Predicate` como classificador, e com uma diferença que é o motivo de ele existir:

```java
// Partition.java: partitioningBy against groupingBy on the same yes-or-no question
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class Partition {
    public static void main(String[] args) {
        Map<Boolean, List<String>> cheap = Shelf.BOOKS.stream()
                .collect(Collectors.partitioningBy(b -> b.priceCents() < 4000,
                        Collectors.mapping(Book::title, Collectors.toList())));
        System.out.println("under 40.00: " + cheap.get(true));
        System.out.println("the rest:    " + cheap.get(false));

        Map<Boolean, Long> free = Shelf.BOOKS.stream()
                .collect(Collectors.partitioningBy(b -> b.priceCents() == 0, Collectors.counting()));
        System.out.println("partitioningBy, free: " + free);

        Map<Boolean, Long> freeGrouped = Shelf.BOOKS.stream()
                .collect(Collectors.groupingBy(b -> b.priceCents() == 0, Collectors.counting()));
        System.out.println("groupingBy, free:     " + freeGrouped);
    }
}
```

```
ana@vm:~/fp/streams$ java Partition.java
under 40.00: [Emma, Persuasion, Dom Casmurro, Beowulf]
the rest:    [Dune, Children of Dune, The Left Hand of Darkness, The Dispossessed, Middlemarch, Ulysses, Grande Sertão: Veredas, The Hobbit]
partitioningBy, free: {false=12, true=0}
groupingBy, free:     {false=12}
```

As duas primeiras linhas são a divisão esperada: quatro livros abaixo de 40,00 e oito a partir disso.
Como o `groupingBy`, o `partitioningBy` recebe um coletor downstream, e o `mapping` fez de cada lado
uma lista de títulos.

## As duas chaves, sempre

Nenhum livro da estante é de graça, e os dois coletores discordam sobre o que isso significa. **O
`partitioningBy` devolveu `{false=12, true=0}`**: as duas chaves, com zero no lado em que não há
ninguém. **O `groupingBy` devolveu `{false=12}`**, porque uma chave só existe quando algum elemento a
produziu. Um código que lê `freeGrouped.get(true)` recebe `null`, e com um `Long` isso vira uma
`NullPointerException` no momento em que é desembrulhado para uma conta. Com o `partitioningBy` a
mesma leitura dá 0.

Então a regra é simples: **quando a pergunta é sim ou não, use `partitioningBy`**, e todo leitor do
resultado pode contar com as duas respostas presentes. O `groupingBy` é para classificadores com mais
de dois resultados, em que as chaves ausentes são um fato real sobre os dados, como `crime` foi na
seção 02.
