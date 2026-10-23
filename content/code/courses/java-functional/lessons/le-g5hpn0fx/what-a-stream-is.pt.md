---
title: O que é um stream
version: 1
---

**Um stream é um pipeline de operações sobre uma sequência de valores: uma fonte, qualquer número de
passos intermediários e uma operação terminal que produz o resultado.** Ele não guarda dados
próprios. Uma lista armazena livros; um stream feito a partir dessa lista descreve o que fazer com
cada livro, e faz isso uma vez, quando o resultado é pedido.

As aulas 6 a 9 trabalham sobre a mesma estante de doze livros, então salve estes dois arquivos juntos
em `~/fp/streams`. `Book` é um record (aula 29 do `java`), e `Shelf` guarda a lista:

```java
// Book.java: one book on the shelf
public record Book(String title, String author, int year, int pages, long priceCents, String genre) {}
```

```java
// Shelf.java: the twelve books the stream lessons work on
import java.util.List;

public class Shelf {
    public static final List<Book> BOOKS = List.of(
            new Book("Dune", "Frank Herbert", 1965, 412, 6990, "sci-fi"),
            new Book("Children of Dune", "Frank Herbert", 1976, 444, 5990, "sci-fi"),
            new Book("The Left Hand of Darkness", "Ursula K. Le Guin", 1969, 304, 4990, "sci-fi"),
            new Book("The Dispossessed", "Ursula K. Le Guin", 1974, 387, 5490, "sci-fi"),
            new Book("Emma", "Jane Austen", 1815, 474, 3990, "classic"),
            new Book("Persuasion", "Jane Austen", 1817, 249, 2990, "classic"),
            new Book("Middlemarch", "George Eliot", 1871, 880, 4490, "classic"),
            new Book("Ulysses", "James Joyce", 1922, 730, 8990, "classic"),
            new Book("Dom Casmurro", "Machado de Assis", 1899, 256, 3490, "classic"),
            new Book("Grande Sertão: Veredas", "João Guimarães Rosa", 1956, 624, 7990, "classic"),
            new Book("Beowulf", "Anonymous", 1000, 96, 2490, "poetry"),
            new Book("The Hobbit", "J. R. R. Tolkien", 1937, 310, 4590, "fantasy"));
}
```

Um programa na mesma pasta pode usar os dois, porque do Java 22 em diante o modo de arquivo-fonte
compila os outros arquivos `.java` a que um programa se refere (aula 1, seção 02).

## Um laço e um stream

A pergunta: os títulos dos livros abaixo de 40,00, na ordem da estante. Como laço, e como stream:

```java
// LoopAndStream.java: one question answered with a loop and with a stream
import java.util.ArrayList;
import java.util.List;

public class LoopAndStream {
    public static void main(String[] args) {
        List<String> cheap = new ArrayList<>();
        for (Book b : Shelf.BOOKS) {
            if (b.priceCents() < 4000) {
                cheap.add(b.title());
            }
        }
        System.out.println("loop:   " + cheap);

        List<String> cheapToo = Shelf.BOOKS.stream()
                .filter(b -> b.priceCents() < 4000)
                .map(Book::title)
                .toList();
        System.out.println("stream: " + cheapToo);
    }
}
```

```
ana@vm:~/fp/streams$ java LoopAndStream.java
loop:   [Emma, Persuasion, Dom Casmurro, Beowulf]
stream: [Emma, Persuasion, Dom Casmurro, Beowulf]
```

As respostas são iguais. **O laço diz como; o stream diz o quê.** O laço monta uma lista, percorre
os livros com um índice que nunca mostra, testa, extrai e acrescenta. O stream nomeia as coisas: de
onde vêm os livros, `stream()`; o que manter, `filter`; em que transformar cada um, `map`; e como
terminar, `toList()`. O `select` que você escreveu na seção 02 da aula 4 era a primeira metade disto,
e o `filter` é a versão da biblioteca.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 145\" role=\"img\" aria-label=\"Um pipeline de stream desenhado da esquerda para a direita: a fonte Shelf.BOOKS.stream(), depois dois passos intermediários, filter mantendo livros abaixo de 4000 centavos e map transformando cada um no seu título, depois a operação terminal toList, que produz o resultado. Uma chave sob os três primeiros diz que eles ainda não executam nada.\"><defs><marker id=\"pipeline-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"pipeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"155\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97.5\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fonte</text><text x=\"97.5\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">stream()</text><path d=\"M175 58 L195 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#pipeline-ah-paperdim)\"></path><rect x=\"195\" y=\"30\" width=\"155\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272.5\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">intermediária</text><text x=\"272.5\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">filter(...)</text><path d=\"M350 58 L370 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#pipeline-ah-paperdim)\"></path><rect x=\"370\" y=\"30\" width=\"155\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447.5\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">intermediária</text><text x=\"447.5\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">map(Book::title)</text><path d=\"M525 58 L545 58\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pipeline-ah-phosphor)\"></path><rect x=\"545\" y=\"30\" width=\"155\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622.5\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">terminal</text><text x=\"622.5\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">toList()</text><path d=\"M25 104 L520 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><text x=\"272\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">descrevem o trabalho, não executam nada</text><text x=\"622\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">roda o pipeline</text></svg>", "caption": "Toda operação menos a última devolve um stream novo; a terminal roda todas.", "same": ["terminal"]}
```

## Três tipos de operação

| tipo | devolve | exemplos | executa |
|---|---|---|---|
| **fonte** | um `Stream` | `list.stream()`, `Stream.of(...)`, `IntStream.range(0, 10)` | nada ainda |
| **intermediária** | outro `Stream` | `filter`, `map`, `sorted`, `distinct`, `limit` | nada ainda |
| **terminal** | um resultado, ou nada | `toList`, `count`, `forEach`, `findFirst`, `reduce`, `collect` | o pipeline inteiro |

O teste é o tipo de retorno. **Tudo o que devolve um `Stream` é um passo; tudo o que devolve outra
coisa termina o pipeline.** É por isso que uma expressão de stream se escreve como cadeia, uma
operação por linha: toda linha menos a última entrega um stream novo à seguinte.
