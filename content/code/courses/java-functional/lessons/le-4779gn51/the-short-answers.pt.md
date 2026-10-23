---
title: As respostas curtas
version: 1
---

**Muitas perguntas feitas a um stream têm uma operação terminal própria**, e usá-la é mais curto e
mais rápido que coletar uma lista e olhar para ela. Mais rápido porque as de correspondência param
assim que sabem (aula 6, seção 04).

```java
// Answers.java: terminal operations that answer one question each
import java.util.Arrays;
import java.util.Comparator;
import java.util.IntSummaryStatistics;

public class Answers {
    public static void main(String[] args) {
        System.out.println("any over 800 pages:   " + Shelf.BOOKS.stream().anyMatch(b -> b.pages() > 800));
        System.out.println("all after 1900:       " + Shelf.BOOKS.stream().allMatch(b -> b.year() > 1900));
        System.out.println("none free:            " + Shelf.BOOKS.stream().noneMatch(b -> b.priceCents() == 0));
        System.out.println("classics:             " + Shelf.BOOKS.stream().filter(b -> b.genre().equals("classic")).count());
        System.out.println("dearest:              " + Shelf.BOOKS.stream().max(Comparator.comparingLong(Book::priceCents)).map(Book::title).orElseThrow());
        System.out.println("first before 1900:    " + Shelf.BOOKS.stream().filter(b -> b.year() < 1900).findFirst().map(Book::title).orElseThrow());
        System.out.println("average pages:        " + Shelf.BOOKS.stream().mapToInt(Book::pages).average().orElse(0));

        IntSummaryStatistics years = Shelf.BOOKS.stream().mapToInt(Book::year).summaryStatistics();
        System.out.println("years:                " + years);

        String[] titles = Shelf.BOOKS.stream().map(Book::title).filter(t -> t.startsWith("The")).toArray(String[]::new);
        System.out.println("titles starting The:  " + Arrays.toString(titles));
    }
}
```

```
ana@vm:~/fp/streams$ java Answers.java
any over 800 pages:   true
all after 1900:       false
none free:            true
classics:             6
dearest:              Ulysses
first before 1900:    Emma
average pages:        430.5
years:                IntSummaryStatistics{count=12, sum=22101, min=1000, average=1841.750000, max=1976}
titles starting The:  [The Left Hand of Darkness, The Dispossessed, The Hobbit]
```

| pergunta | operação | devolve |
|---|---|---|
| algum elemento passa? | `anyMatch(p)` | `boolean`, para no primeiro que passa |
| todos os elementos passam? | `allMatch(p)` | `boolean`, para na primeira falha |
| nenhum elemento passa? | `noneMatch(p)` | `boolean`, para no primeiro que passa |
| quantos? | `count()` | `long` |
| o maior, o menor? | `max(cmp)`, `min(cmp)` | `Optional` |
| o primeiro que passa? | `findFirst()` | `Optional` |
| soma, média, tudo de uma vez | `sum`, `average`, `summaryStatistics` num stream primitivo | um número, um `OptionalDouble`, um objeto de estatísticas |
| um array | `toArray(String[]::new)` | um array do tipo certo (aula 3, seção 04) |

Duas delas merecem um segundo olhar:

- **`allMatch` num stream vazio é `true`**, e `anyMatch` é `false`. "Todo livro de uma estante vazia é
  de graça" é verdade porque não há livro para contradizer. Isso é lógica, não bug, e vale lembrar
  antes de escrever `if (orders.stream().allMatch(Order::isPaid)) ship();`;
- **`summaryStatistics` faz uma passada só** e guarda juntos a contagem, a soma, o mínimo, a média e o
  máximo, onde pedir cada um separadamente percorreria a estante cinco vezes. Os anos vão de 1000,
  Beowulf, a 1976.

`max`, `min` e `findFirst` devolvem um `Optional`, pelo mesmo motivo do `reduce` sem identidade: um
stream vazio não tem maior elemento. O `orElseThrow()` tira o valor e lança exceção se não houver
nenhum, o que é certo aqui, onde uma estante vazia seria um bug do programa e não um caso a tratar.
