---
title: Dobrando um stream num valor só
version: 1
---

**O `reduce` combina todos os elementos de um stream num valor só, dois de cada vez.** Ele recebe um
valor inicial, chamado **identidade**, e uma função que combina o que foi acumulado até ali com o
próximo elemento. Uma soma é o caso simples: comece do 0 e some. A seção 05 da aula 5 dobrou uma
lista de funções numa só com a mesma ideia; o `reduce` é a versão do stream.

```java
// Reduce.java: reduce with and without an identity, and the rule it relies on
import java.util.Optional;
import java.util.stream.IntStream;
import java.util.stream.Stream;

public class Reduce {
    public static void main(String[] args) {
        long total = Shelf.BOOKS.stream().map(Book::priceCents).reduce(0L, (a, b) -> a + b);
        long sameTotal = Shelf.BOOKS.stream().mapToLong(Book::priceCents).sum();
        System.out.println("total: " + total + " / " + sameTotal);

        Optional<Book> oldest = Shelf.BOOKS.stream().reduce((a, b) -> a.year() <= b.year() ? a : b);
        System.out.println("oldest: " + oldest.map(Book::title).orElse("none"));
        Optional<Long> nothing = Stream.<Long>empty().reduce((a, b) -> a + b);
        System.out.println("sum of nothing, no identity: " + nothing);

        System.out.println("minus, in order:  " + IntStream.rangeClosed(1, 8).reduce(0, (a, b) -> a - b));
        System.out.println("minus, split up:  " + IntStream.rangeClosed(1, 8).parallel().reduce(0, (a, b) -> a - b));
        System.out.println("start 100, in order: " + IntStream.rangeClosed(1, 8).reduce(100, Integer::sum));
        System.out.println("start 100, split up: " + IntStream.rangeClosed(1, 8).parallel().reduce(100, Integer::sum));
    }
}
```

```
ana@vm:~/fp/streams$ java Reduce.java
total: 62480 / 62480
oldest: Beowulf
sum of nothing, no identity: Optional.empty
minus, in order:  -36
minus, split up:  0
start 100, in order: 136
start 100, split up: 836
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Dois jeitos de combinar os números de 1 a 8 com subtração a partir de 0. Em ordem, o resultado é uma cadeia só: 0 menos 1, menos 2, e assim até menos 8, que dá menos 36. Dividido em dois pedaços, de 1 a 4 e de 5 a 8, cada pedaço é reduzido a partir de 0 separadamente, dando menos 10 e menos 26, e depois os dois resultados parciais são combinados, o que dá outro número.\"><defs><marker id=\"fold-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"fold-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"fold-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">em ordem</text><rect x=\"20\" y=\"36\" width=\"560\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8</text><rect x=\"610\" y=\"36\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">-36</text><path d=\"M580 54 L606 54\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-phosphor)\"></path><text x=\"20\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dividido em dois</text><rect x=\"20\" y=\"116\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0 - 1 - 2 - 3 - 4</text><rect x=\"20\" y=\"162\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0 - 5 - 6 - 7 - 8</text><rect x=\"300\" y=\"116\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">-10</text><rect x=\"300\" y=\"162\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">-26</text><path d=\"M270 134 L296 134\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-paperdim)\"></path><path d=\"M270 180 L296 180\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-paperdim)\"></path><rect x=\"410\" y=\"136\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">(-10) - (-26)</text><path d=\"M370 134 L390 134 L390 150 L406 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-paperdim)\"></path><path d=\"M370 180 L390 180 L390 166 L406 166\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-paperdim)\"></path><rect x=\"610\" y=\"136\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">16</text><path d=\"M580 158 L606 158\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-amber)\"></path></svg>", "caption": "Um stream dividido reduz cada pedaço a partir da identidade e depois combina os pedaços, então a operação não pode depender do agrupamento."}
```

A primeira linha é o preço total da estante, 62.480 centavos, calculado pelo `reduce` e de novo pelo
`mapToLong(...).sum()`, que é a mesma dobra com a soma embutida. **Use a embutida quando houver
uma**: `sum`, `count`, `max`, `min` e `average` dizem o que fazem, e os streams primitivos os calculam
sem boxing.

## Sem identidade, a resposta pode faltar

`reduce((a, b) -> ...)` sem valor inicial devolve um `Optional`. Sem identidade não há o que devolver
para um stream vazio, então o resultado diz isso em vez de inventar um valor: o stream vazio deu
`Optional.empty`. `oldest` dobrou a estante dois livros de cada vez, ficando sempre com o mais
antigo, e Beowulf venceu. A aula 10 trata do `Optional`; aqui basta que `map` e `orElse` leiam o
valor com segurança.

## A regra que o compilador não confere

As últimas quatro linhas são o motivo de o `reduce` ter uma regra. Um stream pode ser dividido em
pedaços, cada pedaço reduzido sozinho, e os resultados parciais combinados; a aula 9 faz isso de
propósito, e o `parallel()` aqui só pede por isso. Para a resposta ser a mesma qualquer que seja a
divisão, duas coisas precisam valer:

- **a função de combinação é associativa**: `(a op b) op c` é igual a `a op (b op c)`. A soma é; a
  subtração não. Em ordem, 0 − 1 − 2 − … − 8 dá −36. Dividido, os pedaços foram subtraídos
  separadamente e depois subtraídos um do outro, e a resposta saiu 0. A figura divide os números em
  dois, o que dá 16; a execução os cortou em oito pedaços;
- **a identidade é de fato neutra**: combiná-la com qualquer valor devolve esse valor. 0 é a
  identidade da soma; 100 não é. Em ordem, o 100 foi somado uma vez e deu 136. Dividido, cada pedaço
  começou do seu próprio 100, e 836 é 36 mais oito deles: o stream tinha sido cortado em oito
  pedaços.

Nenhuma execução lançou erro. **Um `reduce` que quebra a regra dá um número errado, em silêncio**, e
só quando o stream por acaso é dividido. Somas, produtos, `max`, `min`, juntar strings e `andThen`
são associativos e têm identidade verdadeira; subtração, divisão e médias não, e uma média se
calcula com `average()` ou com um coletor.
