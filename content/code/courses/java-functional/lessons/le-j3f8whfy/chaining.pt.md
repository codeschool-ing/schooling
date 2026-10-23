---
title: Trabalhando com a caixa fechada
version: 1
---

**Você usa um `Optional` sem abri-lo.** `map`, `flatMap` e `filter` trabalham no valor se houver um e
deixam passar uma caixa vazia intacta; `orElse`, `orElseGet` e `orElseThrow` decidem, uma vez, no
fim, o que uma caixa vazia significa. Os métodos têm os nomes que têm nos streams porque um
`Optional` se comporta como um stream de zero ou um elemento.

```schooling-example
{
  "language": "java",
  "file": "Chaining.java",
  "parts": [
    {
      "code": "// Chaining.java: an Optional used without ever being opened\nimport java.util.Optional;\n\npublic class Chaining {"
    },
    {
      "code": "    static String translatorOf(String title) {\n        return Catalogue.find(title)\n                .map(Catalogue.Edition::translator)\n                .orElse(\"no translator\");\n    }",
      "note": "O `map` transforma a edição no seu tradutor. Se a edição falta, ou o tradutor é `null`, o resultado é uma caixa vazia, e o `orElse` fornece as palavras a imprimir no lugar."
    },
    {
      "code": "\n    static Optional<String> affordableTitle(String title, long maxCents) {\n        return Catalogue.find(title)\n                .filter(e -> e.priceCents() <= maxCents)\n                .map(Catalogue.Edition::title);\n    }",
      "note": "O `filter` esvazia a caixa quando o valor não passa no teste. Quem chama recebe um `Optional<String>` e ainda decide o que um vazio significa."
    },
    {
      "code": "\n    static String expensiveDefault() {\n        System.out.println(\"  (computing a default)\");\n        return \"unknown\";\n    }",
      "note": "Um valor padrão que custa algo, e que avisa quando roda."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        System.out.println(translatorOf(\"The Devil to Pay in the Backlands\"));\n        System.out.println(translatorOf(\"Dom Casmurro\"));\n        System.out.println(translatorOf(\"Moby-Dick\"));",
      "note": "Três chamadas: uma tradução, um original com tradutor `null`, e um título que o catálogo não tem. Nenhuma precisou de `if`."
    },
    {
      "code": "\n        System.out.println(affordableTitle(\"Dom Casmurro\", 4000));\n        System.out.println(affordableTitle(\"Grande Sertão: Veredas\", 4000));",
      "note": "Presente e abaixo do limite; presente e acima dele, então o `filter` esvaziou a caixa."
    },
    {
      "code": "\n        System.out.println(\"orElse:\");\n        System.out.println(Catalogue.find(\"Dom Casmurro\").map(Catalogue.Edition::author).orElse(expensiveDefault()));\n        System.out.println(\"orElseGet:\");\n        System.out.println(Catalogue.find(\"Dom Casmurro\").map(Catalogue.Edition::author).orElseGet(Chaining::expensiveDefault));",
      "note": "O `orElse` recebe um valor, então o argumento dele é calculado antes da chamada, seja necessário ou não. O `orElseGet` recebe um `Supplier` (aula 2) e só o chama para uma caixa vazia."
    },
    {
      "code": "\n        Catalogue.find(\"Moby-Dick\").ifPresentOrElse(\n                e -> System.out.println(\"found \" + e.title()),\n                () -> System.out.println(\"not in the catalogue\"));\n        System.out.println(Catalogue.find(\"Moby-Dick\").or(() -> Catalogue.find(\"Dom Casmurro\")).map(Catalogue.Edition::title).orElseThrow());\n    }\n}\n",
      "note": "O `ifPresentOrElse` roda uma de duas ações. O `or` tenta outro `Optional` quando o primeiro está vazio: aqui, um título de reserva."
    }
  ],
  "output": "James L. Taylor and Harriet de Onís\nno translator\nno translator\nOptional[Dom Casmurro]\nOptional.empty\norElse:\n  (computing a default)\nMachado de Assis\norElseGet:\nMachado de Assis\nnot in the catalogue\nDom Casmurro"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três linhas passam pela mesma cadeia: find, depois map para o tradutor, depois orElse. Para uma tradução, a caixa guarda a edição, depois o nome do tradutor, e o orElse devolve o nome. Para Dom Casmurro, a caixa guarda a edição, depois o map recebe null e a caixa fica vazia, e o orElse devolve no translator. Para Moby-Dick, o find devolve uma caixa vazia, o map é pulado, e o orElse devolve no translator.\"><defs><marker id=\"chain-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"215\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">find(title)</text><text x=\"405\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">map(translator)</text><text x=\"605\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">orElse(...)</text><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma tradução</text><rect x=\"140\" y=\"36\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Edition</text><path d=\"M290 58 L326 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"330\" y=\"36\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"James L. ...\"</text><path d=\"M480 58 L526 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"530\" y=\"36\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">\"James L. ...\"</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Dom Casmurro</text><rect x=\"140\" y=\"100\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Edition</text><path d=\"M290 122 L326 122\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"330\" y=\"100\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vazia: null</text><path d=\"M480 122 L526 122\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"530\" y=\"100\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">\"no translator\"</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Moby-Dick</text><rect x=\"140\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"215.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vazia</text><path d=\"M290 186 L326 186\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"330\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vazia</text><path d=\"M480 186 L526 186\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"530\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">\"no translator\"</text></svg>", "caption": "Uma caixa vazia passa por todos os passos intacta, e o orElse decide uma vez, no fim, o que ela significa.", "same": ["Dom Casmurro", "Moby-Dick"]}
```

## `map` e `null`

`translatorOf("Dom Casmurro")` achou a edição, e o `map(Edition::translator)` recebeu `null` de
volta. **O `map` transforma um resultado `null` numa caixa vazia**, então a cadeia seguiu como se não
houvesse edição nenhuma, e o `orElse` respondeu. É assim que o `Optional` absorve os velhos campos
`null` sem uma verificação a cada passo.

Quando a função com que você mapeia já devolve um `Optional`, o `map` o embrulharia de novo num
`Optional<Optional<String>>`; o `flatMap` desembrulha um nível, exatamente como achatou streams na
seção 02 da aula 7.

## O `orElse` calcula o argumento de qualquer jeito

A saída mostra `(computing a default)` abaixo de `orElse:` embora Dom Casmurro tenha autor e o padrão
tenha sido jogado fora. **O argumento do `orElse` é um valor comum, avaliado antes de o `orElse` ser
chamado.** Para uma constante isso não custa nada; para uma consulta a banco, uma linha de log ou um
objeto montado do zero, custa toda vez. O `orElseGet` recebe uma receita e só a roda quando a caixa
está vazia, e é por isso que nada foi impresso abaixo de `orElseGet:`.
