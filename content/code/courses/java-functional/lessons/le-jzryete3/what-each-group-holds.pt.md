---
title: O que cada grupo guarda
version: 1
---

**`groupingBy(classificador, downstream)` entrega os elementos de cada grupo a outro coletor**, e o
mapa guarda o que esse coletor produzir. Uma lista é só o padrão. Peça uma contagem e cada grupo vira
um número; peça uma soma e vira um total:

```schooling-example
{
  "language": "java",
  "file": "Downstream.java",
  "parts": [
    {
      "code": "// Downstream.java: one grouping, five different answers per group\nimport java.util.Comparator;\nimport java.util.Map;\nimport java.util.Optional;\nimport java.util.TreeMap;\nimport java.util.TreeSet;\nimport java.util.stream.Collectors;\n\npublic class Downstream {\n    public static void main(String[] args) {"
    },
    {
      "code": "        Map<String, Long> count = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new, Collectors.counting()));\n        System.out.println(\"count:   \" + count);",
      "note": "`counting()` transforma cada grupo no número de elementos que ele tem, como `Long`."
    },
    {
      "code": "\n        Map<String, Long> value = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new, Collectors.summingLong(Book::priceCents)));\n        System.out.println(\"value:   \" + value);",
      "note": "`summingLong` soma um campo por grupo: o valor do estoque de cada gênero, em centavos."
    },
    {
      "code": "\n        Map<String, Double> pages = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new, Collectors.averagingInt(Book::pages)));\n        System.out.println(\"pages:   \" + pages);",
      "note": "`averagingInt` dá um `Double`, a média do campo dentro de cada grupo."
    },
    {
      "code": "\n        Map<String, String> authors = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new,\n                        Collectors.mapping(Book::author, Collectors.collectingAndThen(Collectors.toCollection(TreeSet::new), set -> String.join(\" & \", set)))));\n        System.out.println(\"authors: \" + authors);",
      "note": "Coletores se aninham: `mapping` transforma cada livro no seu autor, `toCollection(TreeSet::new)` guarda cada autor uma vez e em ordem, e `collectingAndThen` (seção 05) junta o conjunto numa string só."
    },
    {
      "code": "\n        Map<String, Optional<Book>> dearest = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new, Collectors.maxBy(Comparator.comparingLong(Book::priceCents))));\n        dearest.forEach((g, b) -> System.out.println(\"dearest \" + g + \": \" + b.map(Book::title).orElseThrow()));\n    }\n}\n",
      "note": "`maxBy` guarda um elemento por grupo, embrulhado num `Optional` porque o coletor não tem como saber que nenhum grupo vai ser vazio."
    }
  ],
  "output": "count:   {classic=6, fantasy=1, poetry=1, sci-fi=4}\nvalue:   {classic=31940, fantasy=4590, poetry=2490, sci-fi=23460}\npages:   {classic=535.5, fantasy=310.0, poetry=96.0, sci-fi=386.75}\nauthors: {classic=George Eliot & James Joyce & Jane Austen & João Guimarães Rosa & Machado de Assis, fantasy=J. R. R. Tolkien, poetry=Anonymous, sci-fi=Frank Herbert & Ursula K. Le Guin}\ndearest classic: Ulysses\ndearest fantasy: The Hobbit\ndearest poetry: Beowulf\ndearest sci-fi: Dune"
}
```

## Lendo os resultados como tabela

| gênero | contagem | valor, centavos | média de páginas | mais caro |
|---|---|---|---|---|
| classic | 6 | 31.940 | 535,5 | Ulysses |
| fantasy | 1 | 4.590 | 310,0 | The Hobbit |
| poetry | 1 | 2.490 | 96,0 | Beowulf |
| sci-fi | 4 | 23.460 | 386,75 | Dune |

**Cada coletor downstream é um pequeno `collect` rodado separadamente num grupo.** Essa é a ideia a
guardar: `counting`, `summingLong`, `averagingInt`, `mapping`, `maxBy`, e o `toList`, o `toSet` e o
`joining` da aula 7, podem todos aparecer dentro de um `groupingBy`, e alguns deles, como o `mapping`
acima, recebem outro coletor por sua vez. Um pipeline que responde "valor total por gênero" é uma
linha, e o laço que ele substitui seria um mapa, um `getOrDefault` e uma soma, escritos de novo para
cada pergunta nova.

O `Optional` em volta de cada resultado do `maxBy` é o preço da generalidade: o `maxBy` devolveria um
`Optional` vazio para um stream vazio, e dentro de um `groupingBy` nenhum grupo é vazio, então o
`orElseThrow()` nunca lança aqui. A seção 05 mostra como tirar o embrulho quando ele é só ruído.
