---
title: Quatro espécies de referência
version: 1
---

**Uma referência a método é um lambda que só chama um método existente, escrita como o nome do
método.** `s -> s.toUpperCase()` recebe uma string e chama um método nela sem acrescentar nada; a
referência `String::toUpperCase` diz o mesmo com menos símbolos, e o compilador constrói a partir
dela o mesmo tipo de objeto. O `::` separa onde o método mora do nome dele, e não há parênteses
depois do nome, porque nada está sendo chamado ainda.

Há quatro espécies, que se distinguem pelo que vem antes do `::`:

```schooling-example
{
  "language": "java",
  "file": "References.java",
  "parts": [
    {
      "code": "// References.java: the four kinds of method reference, each beside the lambda it replaces\nimport java.util.ArrayList;\nimport java.util.List;\nimport java.util.function.Function;\nimport java.util.function.Predicate;\nimport java.util.function.Supplier;\n\npublic class References {\n    public static void main(String[] args) {"
    },
    {
      "code": "        Function<String, Integer> parseLambda = s -> Integer.parseInt(s);\n        Function<String, Integer> parse = Integer::parseInt;",
      "note": "**Estática**: um nome de classe e um método estático. O argumento do lambda vira o argumento do método."
    },
    {
      "code": "\n        String shop = \"Lumen\";\n        Predicate<String> isShopLambda = s -> shop.equals(s);\n        Predicate<String> isShop = shop::equals;",
      "note": "**Ligada**: um objeto e um dos seus métodos. O objeto é escolhido agora; o argumento do lambda é passado ao método."
    },
    {
      "code": "\n        Function<String, String> upperLambda = s -> s.toUpperCase();\n        Function<String, String> upper = String::toUpperCase;",
      "note": "**Não ligada**: um nome de classe e um método de instância. O objeto ainda não foi escolhido: o primeiro argumento vira o objeto em que o método roda."
    },
    {
      "code": "\n        Supplier<List<String>> shelfLambda = () -> new ArrayList<>();\n        Supplier<List<String>> shelf = ArrayList::new;",
      "note": "**Construtor**: um nome de classe e `new`. Cada chamada constrói um objeto novo, como o lambda faria."
    },
    {
      "code": "\n        System.out.println(parse.apply(\"42\") + 1);\n        System.out.println(isShop.test(\"Lumen\") + \" \" + isShop.test(\"Atlas\"));\n        System.out.println(upper.apply(\"emma\"));\n        System.out.println(shelf.get());\n    }\n}\n",
      "note": "Cada referência é usada exatamente como o lambda ao lado seria: pelo próprio método da interface."
    }
  ],
  "output": "43\ntrue false\nEMMA\n[]"
}
```

`parse.apply("42") + 1` imprimiu 43, então a referência devolveu um `Integer`, não uma string.
`isShop` comparou com `"Lumen"`, a string a que foi ligada. `upper` rodou `toUpperCase` no argumento
que recebeu. `shelf.get()` montou uma lista nova e vazia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma tabela das quatro espécies de referência a método. Estática, Integer::parseInt, vira s -&gt; Integer.parseInt(s). Ligada, shop::equals, vira s -&gt; shop.equals(s), com o objeto fixado quando a referência é feita. Não ligada, String::toUpperCase, vira s -&gt; s.toUpperCase(), com o primeiro argumento sendo o objeto. Construtor, ArrayList::new, vira () -&gt; new ArrayList&lt;&gt;().\"><defs><marker id=\"kinds-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"90\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">espécie</text><text x=\"255\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">referência</text><text x=\"475\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o lambda que ela representa</text><text x=\"645\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o objeto</text><rect x=\"30\" y=\"38\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">estática</text><rect x=\"165\" y=\"38\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Integer::parseInt</text><rect x=\"380\" y=\"38\" width=\"190\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s -&gt; Integer.parseInt(s)</text><rect x=\"585\" y=\"38\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"645.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem objeto</text><path d=\"M345 62 L376 62\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#kinds-ah-paperdim)\"></path><rect x=\"30\" y=\"102\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ligada</text><rect x=\"165\" y=\"102\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">shop::equals</text><rect x=\"380\" y=\"102\" width=\"190\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s -&gt; shop.equals(s)</text><rect x=\"585\" y=\"102\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"645.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fixado ao ser feita</text><path d=\"M345 126 L376 126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#kinds-ah-paperdim)\"></path><rect x=\"30\" y=\"166\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">não ligada</text><rect x=\"165\" y=\"166\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">String::toUpperCase</text><rect x=\"380\" y=\"166\" width=\"190\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s -&gt; s.toUpperCase()</text><rect x=\"585\" y=\"166\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"645.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o primeiro argumento</text><path d=\"M345 190 L376 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#kinds-ah-paperdim)\"></path><rect x=\"30\" y=\"230\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">construtor</text><rect x=\"165\" y=\"230\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">ArrayList::new</text><rect x=\"380\" y=\"230\" width=\"190\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">() -&gt; new ArrayList&lt;&gt;()</text><rect x=\"585\" y=\"230\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"645.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um novo a cada chamada</text><path d=\"M345 254 L376 254\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#kinds-ah-paperdim)\"></path></svg>", "caption": "Cada referência é um lambda que só chama um método; de onde vem o objeto é o que as diferencia."}
```

## O que o compilador confere

**Uma referência tem tipo-alvo, exatamente como um lambda** (aula 1, seção 05), e o compilador
confere se o método nomeado se encaixa nele. `Integer::parseInt` se encaixa em
`Function<String, Integer>` porque existe um `parseInt` que recebe uma `String` e devolve um `int`,
que é embrulhado no `Integer` que a função promete. Escreva a mesma referência onde se espera um
`Predicate<String>` e o compilador recusa, já que `parseInt` não devolve `boolean`.

A escolha entre um lambda e uma referência é sobre leitura, nunca sobre velocidade. Os dois viram um
objeto construído pelo `invokedynamic`, e a JVM trata os dois do mesmo jeito.
