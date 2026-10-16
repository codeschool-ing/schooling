---
title: De onde vem um stream
version: 1
---

**Qualquer coleção dá um stream com `stream()`, e vários outros lugares também dão.** A fonte decide
que valores fluem e em que ordem; tudo o que vem depois só vê um valor de cada vez.

```schooling-example
{
  "language": "java",
  "file": "Sources.java",
  "parts": [
    {
      "code": "// Sources.java: six ways to start a stream\nimport java.util.Arrays;\nimport java.util.Map;\nimport java.util.stream.IntStream;\nimport java.util.stream.Stream;\n\npublic class Sources {\n    public static void main(String[] args) {"
    },
    {
      "code": "        System.out.println(Shelf.BOOKS.stream().count());",
      "note": "O `stream()` de uma coleção: a fonte mais comum. `count()` o termina com o número de elementos."
    },
    {
      "code": "        System.out.println(Stream.of(\"Emma\", \"Dune\", \"Ulysses\").map(String::length).toList());",
      "note": "`Stream.of` recebe os próprios valores, para um punhado conhecido de antemão."
    },
    {
      "code": "        int[] years = {1965, 1815, 1922};\n        System.out.println(Arrays.stream(years).max().getAsInt());",
      "note": "`Arrays.stream` sobre um `int[]` dá um `IntStream`, o tipo primitivo da seção 04 da aula 2, com `max` embutido."
    },
    {
      "code": "        System.out.println(IntStream.rangeClosed(1, 5).sum());",
      "note": "`IntStream.range` e `rangeClosed` contam, sem nenhuma coleção por trás. `rangeClosed(1, 5)` inclui o 5."
    },
    {
      "code": "        System.out.println(Map.of(\"sci-fi\", 4).entrySet().stream().map(e -> e.getKey() + \"=\" + e.getValue()).toList());",
      "note": "Um mapa não é uma coleção, mas o `entrySet()`, o `keySet()` e o `values()` dele são, e cada um tem `stream()`."
    },
    {
      "code": "        System.out.println(Stream.iterate(1, n -> n * 2).limit(10).toList());\n    }\n}\n",
      "note": "`Stream.iterate` faz valores a partir de uma semente e uma regra, para sempre. O `limit(10)` é o que o faz terminar."
    }
  ],
  "output": "12\n[4, 4, 7]\n1965\n15\n[sci-fi=4]\n[1, 2, 4, 8, 16, 32, 64, 128, 256, 512]"
}
```

## Fontes infinitas

`Stream.iterate(1, n -> n * 2)` descreve todas as potências de dois, que são uma sequência infinita,
e o programa não rodou para sempre. **Um stream calcula valores só conforme eles são puxados**, e o
`limit(10)` parou de puxar depois de dez. Tire o `limit` e o `toList()` tentaria coletar todos, e o
programa rodaria até os números estourarem e a memória acabar. `Stream.generate(supplier)` é a outra
fonte infinita: chama um `Supplier` (aula 2, seção 03) para cada valor, o que serve para números
aleatórios ou identificadores novos, e precisa de um `limit` do mesmo jeito.

A aula 20 acrescenta mais uma fonte que importa na prática: `Files.lines(path)`, um stream das linhas
de um arquivo, lidas conforme são puxadas e não todas de uma vez.

## Um stream de `int` não é um `Stream<Integer>`

`Arrays.stream(years)` e `IntStream.rangeClosed` deram `IntStream`, não `Stream<Integer>`. Os streams
primitivos, `IntStream`, `LongStream` e `DoubleStream`, existem pelo mesmo motivo das interfaces
primitivas: **nenhum boxing por elemento**. Eles também têm a aritmética que falta a um
`Stream<Integer>`, `sum`, `average`, `max`, `summaryStatistics`, e é por isso que `max().getAsInt()`
e `sum()` estavam disponíveis acima. A aula 7 mostra como passar de um tipo para o outro.
