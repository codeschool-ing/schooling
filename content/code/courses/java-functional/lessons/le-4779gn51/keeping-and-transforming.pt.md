---
title: Manter e transformar
version: 1
---

**`filter` mantém alguns elementos, `map` transforma cada elemento em outro valor, e `flatMap`
transforma cada elemento em qualquer número de valores.** Esses três, com um punhado de passos que
reordenam e aparam, formam a maioria das operações intermediárias que você vai escrever. Este
programa os roda na estante da aula 6, salvo ao lado dela em `~/fp/streams`:

```schooling-example
{
  "language": "java",
  "file": "Steps.java",
  "parts": [
    {
      "code": "// Steps.java: filter, map, flatMap, distinct, sorted, skip and limit on the shelf\nimport java.util.Arrays;\nimport java.util.Comparator;\nimport java.util.List;\n\npublic class Steps {\n    public static void main(String[] args) {"
    },
    {
      "code": "        List<String> sciFiAuthors = Shelf.BOOKS.stream()\n                .filter(b -> b.genre().equals(\"sci-fi\"))\n                .map(Book::author)\n                .distinct()\n                .toList();\n        System.out.println(\"sci-fi authors: \" + sciFiAuthors);",
      "note": "`filter` mantém os quatro livros de ficção científica, `map` transforma cada um no seu autor, e `distinct` tira as repetições, comparando com `equals`. Dois autores escreveram os quatro."
    },
    {
      "code": "\n        int totalPages = Shelf.BOOKS.stream().mapToInt(Book::pages).sum();\n        System.out.println(\"pages on the shelf: \" + totalPages);",
      "note": "`mapToInt` é um `map` para um `IntStream`, o tipo primitivo da seção 03 da aula 6, que tem `sum`. O `boxed()` faz o caminho inverso, de volta a um `Stream<Integer>`."
    },
    {
      "code": "\n        List<String> words = Shelf.BOOKS.stream()\n                .map(Book::title)\n                .flatMap(t -> Arrays.stream(t.split(\" \")))\n                .filter(w -> w.length() > 6)\n                .sorted()\n                .toList();\n        System.out.println(\"long title words: \" + words);",
      "note": "`flatMap` recebe uma função que devolve um stream, e junta todos esses streams num só. Cada título virou as suas palavras, e as palavras dos doze títulos seguiram como um stream único."
    },
    {
      "code": "\n        List<String> page2 = Shelf.BOOKS.stream()\n                .sorted(Comparator.comparingLong(Book::priceCents))\n                .skip(4)\n                .limit(4)\n                .map(b -> b.title() + \" \" + b.priceCents())\n                .toList();\n        System.out.println(\"second page of four, by price: \" + page2);\n    }\n}\n",
      "note": "`sorted` recebe um comparator montado como na aula 5. `skip(4)` descarta os quatro primeiros e `limit(4)` fica com os quatro seguintes: a segunda página de uma lista mostrada de quatro em quatro."
    }
  ],
  "output": "sci-fi authors: [Frank Herbert, Ursula K. Le Guin]\npages on the shelf: 5166\nlong title words: [Beowulf, Casmurro, Children, Darkness, Dispossessed, Middlemarch, Persuasion, Sertão:, Ulysses, Veredas]\nsecond page of four, by price: [Middlemarch 4490, The Hobbit 4590, The Left Hand of Darkness 4990, The Dispossessed 5490]"
}
```

## `map` é um para um, `flatMap` é um para muitos

`map(Book::title)` deu um título para cada livro. Um título dividido em palavras são vários valores,
e `map(t -> Arrays.stream(t.split(" ")))` teria produzido um `Stream<Stream<String>>`, um stream
cujos elementos são streams, o que quase nunca é o que alguém quer. **O `flatMap` achata isso**: a
função devolve um stream para cada elemento, e o resultado é um stream de tudo o que eles continham.
A mesma forma transforma uma lista de pedidos numa lista dos itens deles, ou uma lista de pastas numa
lista dos seus arquivos. A divisão é por espaços e nada mais, e é por isso que `Sertão:` ficou com os
dois-pontos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"À esquerda, três títulos: Dune, Children of Dune e The Hobbit. Com map, cada título dá um valor, um stream das suas palavras, então o resultado são três streams. Com flatMap, as palavras dos três seguem como um stream só: Dune, Children, of, Dune, The, Hobbit.\"><defs><marker id=\"flatmap-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Dune</text><rect x=\"20\" y=\"80\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Children of Dune</text><rect x=\"20\" y=\"130\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">The Hobbit</text><text x=\"300\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">map: três streams</text><rect x=\"225\" y=\"30\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"300\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[Dune]</text><path d=\"M190 48 L221 48\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flatmap-ah-paperdim)\"></path><rect x=\"225\" y=\"80\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"300\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[Children, of, Dune]</text><path d=\"M190 98 L221 98\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flatmap-ah-paperdim)\"></path><rect x=\"225\" y=\"130\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"300\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[The, Hobbit]</text><path d=\"M190 148 L221 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flatmap-ah-paperdim)\"></path><text x=\"565\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">flatMap: um stream</text><rect x=\"430\" y=\"30\" width=\"270\" height=\"136\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Dune</text><text x=\"565\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Children</text><text x=\"565\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">of</text><text x=\"565\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Dune</text><text x=\"565\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">The</text><text x=\"565\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Hobbit</text></svg>", "caption": "map dá um valor por elemento; flatMap junta os streams que recebe num só."}
```

## A ordem dos passos importa

Um `filter` cedo deixa mais barato tudo o que vem depois, porque menos elementos chegam aos passos
seguintes. Em `words`, filtrar pelo tamanho depois do `flatMap` era a única opção, já que uma palavra
não existe até o título ser dividido; filtrar os livros por gênero antes de mapeá-los para autores,
em `sciFiAuthors`, economizou oito chamadas de `map`. **`distinct` e `sorted` lembram elementos**: o
`distinct` guarda um conjunto de tudo o que já passou, e o `sorted` segura o stream inteiro até ver o
fim. Com doze livros isso não custa nada que valha medir. Num stream de milhões, decide se o programa
cabe na memória, e é um motivo para pô-los depois do `filter` que tira a maioria dos elementos.
