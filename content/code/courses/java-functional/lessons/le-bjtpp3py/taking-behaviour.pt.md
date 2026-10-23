---
title: Recebendo comportamento como argumento
version: 1
---

**Uma função de ordem superior é uma função que recebe outra função como argumento, ou devolve
uma.** O termo vem da matemática, e em Java quer dizer um método com uma interface funcional entre
os parâmetros ou como tipo de retorno. `List.sort(Comparator)` é uma, e `removeIf(Predicate)`
também. Esta seção escreve uma, partindo do código que pede por ela.

## Três métodos que diferem numa linha

A estante de uma livraria, e uma pergunta feita a ela de vários jeitos. Escrita sem lambdas, cada
pergunta é um método:

```java
// Select.java: a method per question, then one method that takes the question
import java.util.ArrayList;
import java.util.List;
import java.util.function.Predicate;

public class Select {
    record Book(String title, int pages, long priceCents) {}

    static List<Book> longerThan(List<Book> books, int pages) {
        List<Book> out = new ArrayList<>();
        for (Book b : books) {
            if (b.pages() > pages) {
                out.add(b);
            }
        }
        return out;
    }

    static <T> List<T> select(List<T> items, Predicate<T> rule) {
        List<T> out = new ArrayList<>();
        for (T item : items) {
            if (rule.test(item)) {
                out.add(item);
            }
        }
        return out;
    }

    static List<String> titles(List<Book> books) {
        List<String> out = new ArrayList<>();
        for (Book b : books) {
            out.add(b.title());
        }
        return out;
    }

    public static void main(String[] args) {
        List<Book> shelf = List.of(
                new Book("Dune", 412, 6990),
                new Book("Emma", 474, 3990),
                new Book("Beowulf", 96, 2490),
                new Book("Ulysses", 730, 8990));
        System.out.println("longerThan:  " + titles(longerThan(shelf, 450)));
        System.out.println("long:        " + titles(select(shelf, b -> b.pages() > 450)));
        System.out.println("cheap:       " + titles(select(shelf, b -> b.priceCents() < 4000)));
        System.out.println("odd request: " + titles(select(shelf, b -> b.title().startsWith("U") || b.pages() < 100)));
        System.out.println("short words: " + select(List.of("an", "epic", "of", "the", "sea"), w -> w.length() <= 2));
    }
}
```

```
ana@vm:~/fp/higher-order$ java Select.java
longerThan:  [Emma, Ulysses]
long:        [Emma, Ulysses]
cheap:       [Emma, Beowulf]
odd request: [Beowulf, Ulysses]
short words: [an, of]
```

`longerThan` é uma pergunta fixada dentro de um laço. A próxima pergunta, mais barato que certo
preço, seria uma cópia dele com uma linha trocada, e a seguinte também. **`select` fica com o laço e
recebe como argumento a linha que muda.** Os dois primeiros resultados são idênticos, o que prova
que nada se perdeu, e o terceiro e o quarto são perguntas para as quais ninguém escreveu método.

## Genérico, porque o laço não se importa

`select` é declarado `<T>`, então funciona com qualquer lista e uma regra sobre o tipo dela. A
última linha o usou em strings simples sem mudar nada. Essa é a forma geral de uma função de ordem
superior: **o método é dono da parte que é sempre igual, aqui o laço e a lista nova, e quem chama
fornece a parte que varia.** É a mesma divisão que a Stream API faz em escala muito maior. O
`filter` da aula 7 é este `select`, embutido na biblioteca e capaz de rodar em vários processadores.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois painéis. À esquerda, receber comportamento: quem chama passa o lambda b -&gt; b.pages() &gt; 450 para select, que é dono do laço e chama o lambda uma vez por livro. À direita, devolver comportamento: quem chama passa o número 450 para atLeast, que devolve um lambda que o capturou.\"><defs><marker id=\"flow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">recebendo comportamento</text><rect x=\"45\" y=\"70\" width=\"280\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">b -&gt; b.pages() &gt; 450</text><path d=\"M185 106 L185 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#flow-ah-phosphor)\"></path><rect x=\"45\" y=\"138\" width=\"280\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">select(shelf, rule)</text><text x=\"185.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dono do laço, chama a regra</text><text x=\"185.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma vez por livro</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">devolvendo comportamento</text><rect x=\"395\" y=\"70\" width=\"280\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">atLeast(450)</text><path d=\"M535 106 L535 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#flow-ah-phosphor)\"></path><rect x=\"395\" y=\"138\" width=\"280\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">b -&gt; b.pages() &gt;= pages</text><text x=\"535.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pages = 450, capturado</text></svg>", "caption": "Receber comportamento põe a regra de quem chama dentro do laço de outro; devolvê-lo monta uma regra para quem chama guardar."}
```

## No que prestar atenção

O lambda roda dentro de `select`, uma vez por item, num momento que `select` escolhe. Então uma
regra que **faz algo** além de responder, como imprimir ou mudar um campo, faz isso tantas vezes
quantas `select` decidir chamá-la. Uma regra que só lê o argumento e devolve uma resposta pode ser
chamada qualquer número de vezes, em qualquer ordem, sem perigo. As aulas 9 e 11 voltam ao motivo
de essa diferença importar assim que mais de uma thread está chamando.
