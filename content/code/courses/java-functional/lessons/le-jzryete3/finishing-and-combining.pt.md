---
title: Terminando um coletor, e rodando dois de uma vez
version: 1
---

**Mais três coletores mudam a forma de um resultado em vez de calcular um novo.** O
`collectingAndThen` roda uma função no que outro coletor produziu. O `toCollection` escolhe a coleção
exata a encher. O `teeing`, que chegou no Java 12, manda cada elemento para dois coletores ao mesmo
tempo e combina os dois resultados no fim.

```schooling-example
{
  "language": "java",
  "file": "Finishing.java",
  "parts": [
    {
      "code": "// Finishing.java: collectingAndThen, toCollection and teeing\nimport java.util.Comparator;\nimport java.util.List;\nimport java.util.Map;\nimport java.util.TreeMap;\nimport java.util.TreeSet;\nimport java.util.stream.Collectors;\n\npublic class Finishing {\n    public static void main(String[] args) {"
    },
    {
      "code": "        Map<String, String> dearest = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new,\n                        Collectors.collectingAndThen(\n                                Collectors.maxBy(Comparator.comparingLong(Book::priceCents)),\n                                b -> b.orElseThrow().title())));\n        System.out.println(dearest);",
      "note": "O livro mais caro por gênero de novo, sem o `Optional` em volta de cada um. O `collectingAndThen` pega o `Optional` que o `maxBy` produziu para um grupo e o transforma no título, uma vez por grupo."
    },
    {
      "code": "\n        TreeSet<String> authors = Shelf.BOOKS.stream()\n                .map(Book::author)\n                .collect(Collectors.toCollection(TreeSet::new));\n        System.out.println(authors.first() + \" ... \" + authors.last() + \" (\" + authors.size() + \")\");",
      "note": "O `toCollection` recebe um `Supplier` da coleção a encher. Um `TreeSet` mantém os autores ordenados e únicos, e oferece `first` e `last`, que um `Set` simples não tem."
    },
    {
      "code": "\n        String range = Shelf.BOOKS.stream()\n                .collect(Collectors.teeing(\n                        Collectors.minBy(Comparator.comparingLong(Book::priceCents)),\n                        Collectors.maxBy(Comparator.comparingLong(Book::priceCents)),\n                        (min, max) -> min.orElseThrow().title() + \" to \" + max.orElseThrow().title()));\n        System.out.println(\"from the cheapest to the dearest: \" + range);",
      "note": "O `teeing` passa cada livro tanto para o `minBy` quanto para o `maxBy` numa passada só, depois entrega os dois resultados à função do fim."
    },
    {
      "code": "\n        List<String> fixed = Shelf.BOOKS.stream()\n                .map(Book::title)\n                .collect(Collectors.collectingAndThen(Collectors.toList(), List::copyOf));\n        try {\n            fixed.add(\"Moby-Dick\");\n        } catch (UnsupportedOperationException e) {\n            System.out.println(fixed.size() + \" titles, and add() is refused\");\n        }\n    }\n}\n",
      "note": "O jeito antigo de obter uma lista que ninguém pode mudar: coletar uma lista mutável e depois copiá-la com `List::copyOf`. Desde o Java 16, o `toList()` do stream faz as duas coisas."
    }
  ],
  "output": "{classic=Ulysses, fantasy=The Hobbit, poetry=Beowulf, sci-fi=Dune}\nAnonymous ... Ursula K. Le Guin (9)\nfrom the cheapest to the dearest: Beowulf to Ulysses\n12 titles, and add() is refused"
}
```

## Que coletor, para que pergunta

| pergunta | coletor |
|---|---|
| um mapa de um grupo para os seus elementos | `groupingBy(classificador)` |
| um número, uma soma ou um resumo por grupo | `groupingBy(classificador, counting() / summingLong(...) / averagingInt(...))` |
| só um campo de cada elemento de um grupo | `mapping(campo, downstream)` |
| sim ou não, com as duas respostas sempre presentes | `partitioningBy(predicado)` |
| um resultado, e depois mais um passo sobre ele | `collectingAndThen(coletor, finalizador)` |
| um tipo específico de coleção | `toCollection(TreeSet::new)` |
| dois resultados de uma passada | `teeing(primeiro, segundo, combinador)` |
| uma string | `joining(separador, prefixo, sufixo)` (aula 7) |

Cada um destes é uma receita feita de quatro funções: criar um contêiner vazio, acrescentar um
elemento a ele, juntar dois contêineres, terminar. Essa parte de juntar é o que deixa um coletor rodar
sobre um stream dividido entre processadores, e a aula 9 é o lugar onde isso importa.
