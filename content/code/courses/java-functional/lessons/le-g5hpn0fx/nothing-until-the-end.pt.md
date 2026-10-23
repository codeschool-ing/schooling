---
title: Nada acontece até o fim
version: 1
---

**Operações intermediárias são preguiçosas: registram o que fazer e não fazem nada.** A operação
terminal começa o trabalho, e então cada elemento percorre todos os passos antes de o próximo
elemento começar. Os dois fatos ficam mais fáceis de acreditar quando você os vê. `peek` é uma
operação intermediária que entrega cada elemento a um `Consumer` e o passa adiante sem mudança, o que
faz dele o `println` do stream para depuração:

```java
// Lazy.java: watching a pipeline run, and not run
import java.util.List;

public class Lazy {
    public static void main(String[] args) {
        System.out.println("-- no terminal operation:");
        Shelf.BOOKS.stream()
                .peek(b -> System.out.println("  looked at " + b.title()))
                .filter(b -> b.pages() > 450);

        System.out.println("-- findFirst:");
        String first = Shelf.BOOKS.stream()
                .peek(b -> System.out.println("  looked at " + b.title()))
                .filter(b -> b.pages() > 450)
                .peek(b -> System.out.println("  kept " + b.title()))
                .map(Book::title)
                .findFirst()
                .orElse("none");
        System.out.println("first long book: " + first);

        System.out.println("-- two steps, element by element:");
        List<String> two = Shelf.BOOKS.stream()
                .filter(b -> b.genre().equals("classic"))
                .peek(b -> System.out.println("  classic: " + b.title()))
                .map(b -> b.title().toUpperCase())
                .peek(t -> System.out.println("  upper:   " + t))
                .limit(2)
                .toList();
        System.out.println(two);
    }
}
```

```
ana@vm:~/fp/streams$ java Lazy.java
-- no terminal operation:
-- findFirst:
  looked at Dune
  looked at Children of Dune
  looked at The Left Hand of Darkness
  looked at The Dispossessed
  looked at Emma
  kept Emma
first long book: Emma
-- two steps, element by element:
  classic: Emma
  upper:   EMMA
  classic: Persuasion
  upper:   PERSUASION
[EMMA, PERSUASION]
```

## Leia a saída em três partes

**O primeiro pipeline não imprimiu nada.** Ele tem uma fonte e dois passos intermediários, e nenhuma
operação terminal, então descreveu um trabalho que ninguém pediu. O Java montou o objeto do stream e
o jogou fora. Um pipeline sem a última linha é um bug comum, e fácil de não ver: compila, e não faz
nada em silêncio.

**O segundo olhou cinco livros e parou.** O `findFirst` precisa de um elemento, e o primeiro livro
longo é Emma, o quinto da estante. O pipeline puxou os quatro livros de ficção científica, nenhum com
mais de 450 páginas, depois Emma, ficou com Emma, e os outros sete livros nunca foram olhados.
Operações que podem terminar cedo se chamam **de curto-circuito**: `findFirst`, `findAny`,
`anyMatch`, `allMatch`, `noneMatch` e `limit`.

**O terceiro foi elemento por elemento.** Um laço escrito à mão poderia filtrar todos os livros
primeiro e depois converter todos os títulos. O stream não fez isso: Emma foi filtrado e passado para
maiúsculas antes de Persuasion sequer ser olhado, e depois de dois títulos o `limit(2)` parou o
pipeline inteiro. Essa ordem, um elemento por todos os passos, é o que faz os passos não custarem nada
quando a resposta é achada cedo, e é o motivo de a aula 9 poder dividir os elementos entre
processadores.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" aria-label=\"Uma grade com três clássicos nas colunas, Emma, Persuasion e Middlemarch, e três passos nas linhas, filter, map e limit 2. Emma passa pelos três passos primeiro, depois Persuasion passa pelos três. Middlemarch nunca é alcançado, porque o limit parou o pipeline depois de dois.\"><defs><marker id=\"vertical-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"vertical-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"80\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">filter</text><text x=\"80\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">map</text><text x=\"80\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">limit(2)</text><text x=\"245\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Emma</text><rect x=\"170\" y=\"48\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">primeiro, passo 1</text><rect x=\"170\" y=\"106\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">primeiro, passo 2</text><rect x=\"170\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">primeiro, passo 3</text><path d=\"M245 92 L245 104\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#vertical-ah-phosphor)\"></path><path d=\"M245 150 L245 162\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#vertical-ah-phosphor)\"></path><text x=\"425\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Persuasion</text><rect x=\"350\" y=\"48\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segundo, passo 1</text><rect x=\"350\" y=\"106\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segundo, passo 2</text><rect x=\"350\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segundo, passo 3</text><path d=\"M425 92 L425 104\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#vertical-ah-paperdim)\"></path><path d=\"M425 150 L425 162\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#vertical-ah-paperdim)\"></path><text x=\"605\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Middlemarch</text><rect x=\"530\" y=\"48\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"605.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca alcançado</text><rect x=\"530\" y=\"106\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"605.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca alcançado</text><rect x=\"530\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"605.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca alcançado</text></svg>", "caption": "Cada elemento passa por todos os passos antes de o próximo começar, e o limit interrompe a busca."}
```

## O que decorre da preguiça

- **um passo que nunca roda não pode falhar**, então um erro dentro de um lambda só aparece quando uma
  operação terminal chega ao elemento que o causa, e o stack trace aponta para a chamada terminal
  além do lambda;
- **o `peek` é para olhar**, não para fazer. Ele só roda para os elementos que um pipeline por acaso
  puxa, então um trabalho feito dentro dele pode rodar para alguns elementos e não para outros, como o
  segundo pipeline mostrou;
- **o `sorted` não pode ser preguiçoso do mesmo jeito**: precisa ver todos os elementos antes de
  entregar o primeiro, então um `sorted` antes de um `findFirst` puxa a fonte inteira. A aula 7 volta
  a isso.
