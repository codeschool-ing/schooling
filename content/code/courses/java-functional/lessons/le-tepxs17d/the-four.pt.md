---
title: As quatro formas
version: 1
---

**Raramente você precisa escrever uma interface funcional, porque o `java.util.function` já tem uma
para quase toda forma que um lambda assume.** Forma, aqui, quer dizer só duas coisas: o que entra e
o que sai. Quatro respostas cobrem quase todos os casos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro linhas, uma por interface. Function recebe um valor do tipo T e devolve um valor do tipo R. Predicate recebe um T e devolve true ou false. Supplier não recebe nada e devolve um T. Consumer recebe um T e não devolve nada.\"><defs><marker id=\"four-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"four-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que entra</text><text x=\"610\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que sai</text><rect x=\"50\" y=\"44\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">T</text><rect x=\"260\" y=\"44\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"58.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Function&lt;T, R&gt;</text><text x=\"360.0\" y=\"73.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">apply()</text><rect x=\"550\" y=\"44\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">R</text><path d=\"M170 66 L256 66\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-paperdim)\"></path><path d=\"M460 66 L546 66\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-phosphor)\"></path><rect x=\"50\" y=\"108\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">T</text><rect x=\"260\" y=\"108\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"122.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Predicate&lt;T&gt;</text><text x=\"360.0\" y=\"137.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">test()</text><rect x=\"550\" y=\"108\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">boolean</text><path d=\"M170 130 L256 130\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-paperdim)\"></path><path d=\"M460 130 L546 130\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-phosphor)\"></path><rect x=\"50\" y=\"172\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"110.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nada</text><rect x=\"260\" y=\"172\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"186.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Supplier&lt;T&gt;</text><text x=\"360.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">get()</text><rect x=\"550\" y=\"172\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">T</text><path d=\"M170 194 L256 194\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-paperdim)\"></path><path d=\"M460 194 L546 194\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-phosphor)\"></path><rect x=\"50\" y=\"236\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">T</text><rect x=\"260\" y=\"236\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"250.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Consumer&lt;T&gt;</text><text x=\"360.0\" y=\"265.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">accept()</text><rect x=\"550\" y=\"236\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nada</text><path d=\"M170 258 L256 258\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-paperdim)\"></path><path d=\"M460 258 L546 258\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-phosphor)\"></path></svg>", "caption": "As quatro formas se distinguem pelo que entra e pelo que sai."}
```

| interface | método | entra | sai | a pergunta que responde |
|---|---|---|---|---|
| `Function<T, R>` | `R apply(T t)` | um valor | um valor | isto vira o quê? |
| `Predicate<T>` | `boolean test(T t)` | um valor | `true` ou `false` | este passa? |
| `Supplier<T>` | `T get()` | nada | um valor | me dê um |
| `Consumer<T>` | `void accept(T t)` | um valor | nada | faça algo com isto |

Vale aprender os nomes porque **a assinatura de uma API diz o que ela vai fazer com o seu lambda**.
`removeIf(Predicate)` vai testar cada elemento; `forEach(Consumer)` vai entregar cada um e ignorar o
que voltar; o `orElseGet(Supplier)` da aula 10 vai chamar o seu lambda só quando precisar de um
valor.

## Cada uma, executada

```schooling-example
{
  "language": "java",
  "file": "TheFour.java",
  "parts": [
    {
      "code": "// TheFour.java: the four shapes, and their two-argument cousins\nimport java.util.ArrayList;\nimport java.util.List;\nimport java.util.function.BiFunction;\nimport java.util.function.BinaryOperator;\nimport java.util.function.Consumer;\nimport java.util.function.Function;\nimport java.util.function.Predicate;\nimport java.util.function.Supplier;\nimport java.util.function.UnaryOperator;\n\npublic class TheFour {\n    public static void main(String[] args) {"
    },
    {
      "code": "        Function<String, Integer> words = s -> s.split(\" \").length;",
      "note": "Uma `Function` transforma uma `String` num `Integer`. Os dois argumentos de tipo são a entrada e a saída, nessa ordem."
    },
    {
      "code": "        Predicate<String> longTitle = s -> words.apply(s) > 3;",
      "note": "Um `Predicate` é um teste. Este chama a `Function` acima, que ele capturou como qualquer outra variável local."
    },
    {
      "code": "        Supplier<List<String>> newShelf = () -> new ArrayList<>();",
      "note": "Um `Supplier` não recebe nada. Cada chamada a `get` roda o corpo de novo, então cada estante é uma lista nova."
    },
    {
      "code": "        Consumer<String> announce = s -> System.out.println(\"new: \" + s);",
      "note": "Um `Consumer` recebe um valor e não devolve nada. Ele existe pelo efeito: imprimir, salvar, enviar."
    },
    {
      "code": "        BiFunction<String, Integer, String> cut = (s, n) -> s.substring(0, n);\n        UnaryOperator<String> shout = s -> s.toUpperCase();\n        BinaryOperator<Integer> larger = (a, b) -> a >= b ? a : b;",
      "note": "Os primos: `Bi` recebe duas entradas. `UnaryOperator<T>` é uma `Function<T, T>` e `BinaryOperator<T>` uma `BiFunction<T, T, T>`, com nomes para o caso comum em que tudo tem um tipo só."
    },
    {
      "code": "\n        List<String> shelf = newShelf.get();\n        for (String title : List.of(\"Dune\", \"One Hundred Years of Solitude\", \"Emma\")) {\n            if (longTitle.test(title)) {\n                shelf.add(title);\n                announce.accept(title);\n            }\n        }\n        System.out.println(shelf + \" \" + newShelf.get());\n        System.out.println(cut.apply(\"Solitude\", 4) + \" \" + shout.apply(\"emma\") + \" \" + larger.apply(3, 7));\n    }\n}\n",
      "note": "Nenhum dos lambdas rodou até aqui. `newShelf.get()` foi chamado duas vezes e deu duas listas diferentes, uma cheia e uma vazia."
    }
  ],
  "output": "new: One Hundred Years of Solitude\n[One Hundred Years of Solitude] []\nSoli EMMA 7"
}
```

`longTitle` deixou passar um título, e `announce` o imprimiu. As duas estantes do fim são a prova de
que **um `Supplier` é uma receita, não um valor**: `get` rodou o corpo duas vezes e montou duas
listas. A mesma ideia torna o `Supplier` o tipo certo para qualquer coisa cara que talvez não seja
necessária, porque nada é construído até alguém pedir.

## Quando os nomes não bastam

Há interfaces para duas entradas (`BiFunction`, `BiPredicate`, `BiConsumer`) e nenhuma para três.
Isso é de propósito: **um lambda que precisa de três entradas costuma estar pedindo um record**
(aula 29 do `java`) que as agrupe, ou uma interface sua com um nome que diga o que as três
significam. A seção 05 escreve uma, por outro motivo.
