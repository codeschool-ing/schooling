---
title: Duas ordens, dois métodos
version: 1
---

**`f.andThen(g)` é uma função nova que roda `f` e passa o resultado para `g`. `f.compose(g)` roda
`g` primeiro e passa o resultado para `f`.** Os dois devolvem uma `Function` nova e não mudam
nenhuma das duas de que foram feitos. São métodos default de `Function` (aula 2, seção 02), e é por
isso que qualquer lambda tipado como `Function` já os tem.

```java
// Compose.java: the same two functions joined in both orders
import java.util.Locale;
import java.util.function.Function;

public class Compose {
    public static void main(String[] args) {
        Function<Integer, Integer> addOne = x -> x + 1;
        Function<Integer, Integer> doubleIt = x -> x * 2;
        System.out.println("addOne.andThen(doubleIt): " + addOne.andThen(doubleIt).apply(5));
        System.out.println("addOne.compose(doubleIt): " + addOne.compose(doubleIt).apply(5));

        Function<String, String> strip = String::strip;
        Function<String, String> lower = s -> s.toLowerCase(Locale.ROOT);
        Function<String, Integer> length = String::length;
        Function<String, Integer> cleanLength = strip.andThen(lower).andThen(length);
        System.out.println(cleanLength.apply("   Middlemarch  "));

        Function<String, String> same = Function.identity();
        System.out.println("[" + same.apply("unchanged") + "]");
    }
}
```

```
ana@vm:~/fp/composition$ java Compose.java
addOne.andThen(doubleIt): 12
addOne.compose(doubleIt): 11
11
[unchanged]
```

Com 5, o `andThen` somou um e depois dobrou, 12; o `compose` dobrou e depois somou um, 11. **Os
nomes dizem a ordem em duas gramáticas diferentes.** `andThen` se lê da esquerda para a direita, na
ordem em que o trabalho acontece, e é por isso que quase todo código real o usa. `compose` se lê como
a matemática, onde `f(g(x))` se escreve com `f` primeiro e roda `g` primeiro; ele existe para os
casos em que a função que você tem é a de fora.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas linhas. Na primeira, addOne.andThen(doubleIt): 5 entra em addOne e vira 6, depois em doubleIt e vira 12. Na segunda, addOne.compose(doubleIt): 5 entra primeiro em doubleIt e vira 10, depois em addOne e vira 11.\"><defs><marker id=\"order-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">addOne.andThen(doubleIt)</text><rect x=\"30\" y=\"50\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"70.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">5</text><rect x=\"150\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">addOne</text><rect x=\"300\" y=\"50\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">6</text><rect x=\"420\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">doubleIt</text><rect x=\"570\" y=\"50\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">12</text><path d=\"M110 70 L146 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M260 70 L296 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M380 70 L416 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M530 70 L566 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><text x=\"30\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">addOne.compose(doubleIt)</text><rect x=\"30\" y=\"150\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"70.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">5</text><rect x=\"150\" y=\"150\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">doubleIt</text><rect x=\"300\" y=\"150\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">10</text><rect x=\"420\" y=\"150\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">addOne</text><rect x=\"570\" y=\"150\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">11</text><path d=\"M110 170 L146 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M260 170 L296 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M380 170 L416 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path><path d=\"M530 170 L566 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#order-ah-phosphor)\"></path></svg>", "caption": "andThen roda primeiro a função em que é chamado; compose roda primeiro o argumento."}
```

## Os tipos precisam se encaixar

`strip.andThen(lower).andThen(length)` mudou de tipo no caminho: dois passos de `String` para
`String` e o último de `String` para `Integer`, então o conjunto é uma `Function<String, Integer>`.
**O tipo de saída de cada passo precisa ser o tipo de entrada do seguinte**, e o compilador confere
cada junta. Uma cadeia que tentasse `length.andThen(lower)` seria recusada, porque `lower` não
recebe o `Integer` que `length` dá.

`Function.identity()` é a função que devolve o argumento sem mudança. Parece inútil e é o ponto de
partida certo para uma cadeia montada num laço, como mostra a seção 05, do mesmo jeito que `0` é o
começo certo de uma soma.

## As outras que se compõem

O `andThen` não está só em `Function`:

| tipo | método | o que o resultado faz |
|---|---|---|
| `Function<T, R>` | `andThen`, `compose` | roda as duas, passando o valor adiante |
| `BiFunction<T, U, R>` | `andThen(Function)` | roda a de dois argumentos, depois uma de um argumento no resultado |
| `Consumer<T>` | `andThen(Consumer)` | entrega o mesmo valor aos dois, em ordem |
| `UnaryOperator<T>` | herda o `andThen` de `Function` | o resultado é tipado como `Function<T, R>`, não como `UnaryOperator` |

A última linha pega muita gente: juntar dois `UnaryOperator<String>` dá uma
`Function<String, String>`, porque o método foi declarado em `Function`. Guarde o resultado numa
variável `Function`, e nada se perde.
