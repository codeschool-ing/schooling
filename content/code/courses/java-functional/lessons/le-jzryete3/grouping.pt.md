---
title: Agrupando
version: 1
---

**`Collectors.groupingBy(classificador)` separa os elementos em grupos e devolve um mapa da chave de
cada grupo para uma lista dos elementos dele.** O classificador é uma `Function` que responde a uma
pergunta por elemento: em que grupo este está? É o `GROUP BY` do stream, e funciona na estante da
aula 6 em `~/fp/streams`:

```java
// Grouping.java: books grouped by genre, by decade, and in a sorted map
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Collectors;

public class Grouping {
    public static void main(String[] args) {
        Map<String, List<Book>> byGenre = Shelf.BOOKS.stream()
                .collect(Collectors.groupingBy(Book::genre));
        System.out.println(byGenre.keySet());
        System.out.println("fantasy: " + byGenre.get("fantasy"));
        System.out.println("crime:   " + byGenre.get("crime"));

        Map<String, List<Book>> sorted = Shelf.BOOKS.stream()
                .collect(Collectors.groupingBy(Book::genre, TreeMap::new, Collectors.toList()));
        sorted.forEach((genre, books) -> System.out.println(genre + " " + books.size()));

        Map<Integer, List<String>> byCentury = Shelf.BOOKS.stream()
                .collect(Collectors.groupingBy(b -> b.year() / 100 + 1, TreeMap::new,
                        Collectors.mapping(Book::title, Collectors.toList())));
        byCentury.forEach((century, titles) -> System.out.println("century " + century + ": " + titles));
    }
}
```

```
ana@vm:~/fp/streams$ java Grouping.java
[fantasy, classic, sci-fi, poetry]
fantasy: [Book[title=The Hobbit, author=J. R. R. Tolkien, year=1937, pages=310, priceCents=4590, genre=fantasy]]
crime:   null
classic 6
fantasy 1
poetry 1
sci-fi 4
century 11: [Beowulf]
century 19: [Emma, Persuasion, Middlemarch, Dom Casmurro]
century 20: [Dune, Children of Dune, The Left Hand of Darkness, The Dispossessed, Ulysses, Grande Sertão: Veredas, The Hobbit]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"À esquerda, os doze livros como stream. groupingBy com Book::genre como classificador pergunta a cada livro o seu gênero e o põe num balde com essa chave. Resultam quatro baldes: classic com seis livros, sci-fi com quatro, fantasy com um e poetry com um. Não há balde crime, porque nenhum livro produziu essa chave.\"><defs><marker id=\"buckets-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"buckets-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"150\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">12 livros</text><text x=\"95.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Shelf.BOOKS</text><rect x=\"220\" y=\"100\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">groupingBy</text><text x=\"305.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Book::genre</text><path d=\"M170 130 L216 130\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#buckets-ah-paperdim)\"></path><rect x=\"450\" y=\"20\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">classic</text><rect x=\"580\" y=\"20\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">6 livros</text><path d=\"M390 130 L420 130 L420 39 L446 39\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#buckets-ah-phosphor)\"></path><rect x=\"450\" y=\"70\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sci-fi</text><rect x=\"580\" y=\"70\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4 livros</text><path d=\"M390 130 L420 130 L420 89 L446 89\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#buckets-ah-phosphor)\"></path><rect x=\"450\" y=\"120\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fantasy</text><rect x=\"580\" y=\"120\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1 livro</text><path d=\"M390 130 L420 130 L420 139 L446 139\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#buckets-ah-phosphor)\"></path><rect x=\"450\" y=\"170\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">poetry</text><rect x=\"580\" y=\"170\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1 livro</text><path d=\"M390 130 L420 130 L420 189 L446 189\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#buckets-ah-phosphor)\"></path><rect x=\"450\" y=\"220\" width=\"250\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"575.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem chave crime: get devolve null</text></svg>", "caption": "O classificador escolhe uma chave para cada elemento; uma chave só existe se algum elemento a produziu."}
```

## Três coisas a notar

**As chaves vêm dos dados.** `byGenre` tem os quatro gêneros que a estante contém e nenhum outro.
`byGenre.get("crime")` é `null`, não uma lista vazia, porque nenhum livro produziu essa chave; um
relatório que precisa mostrar todos os gêneros, inclusive os vazios, tem de partir da lista de
gêneros e não do mapa. A seção 04 mostra o único coletor que sempre tem as suas duas chaves.

**O mapa simples não tem ordem em que se possa confiar.** `byGenre` é um `HashMap`, e a ordem do
`keySet()` é o que a tabela de hash fez dele. A segunda forma do `groupingBy` recebe uma fábrica de
mapa: `TreeMap::new`, usado como `Supplier` (aula 3, seção 04), dá as chaves ordenadas, que é o que
um relatório impresso quer.

**A chave pode ser calculada.** `b.year() / 100 + 1` transforma um ano num século com divisão
inteira: 1965 está no século 20, 1815 no 19, e Beowulf, datado de 1000, no 11 por essa conta. O
terceiro argumento, `Collectors.mapping(Book::title, toList())`, fez de cada grupo uma lista de
títulos em vez de uma lista de livros. Esse argumento se chama coletor **downstream**, e é o assunto
da próxima seção.
