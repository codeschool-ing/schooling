---
title: Como uma função acha um nome
version: 1
---

A aula 3 disse que um nome pertence a um escopo. **Escopos se aninham**, porque funções e blocos se
escrevem uns dentro dos outros, e quando o código usa um nome o motor o procura numa ordem fixa:

```javascript
const library = "City Library";

function openShelf(shelfName) {
  const opened = "09:00";

  function describeBook(title) {
    return `${title} on ${shelfName}, ${library}, open since ${opened}`;
  }

  return describeBook("Iracema");
}

console.log(openShelf("Romance"));

function lookForIt() {
  return readerCount;
}
console.log(lookForIt());
```

```
ana@dev:~/js$ node scope-chain.js 2>&1 | head -n 7
Iracema on Romance, City Library, open since 09:00
/home/ana/js/scope-chain.js:16
  return readerCount;
  ^

ReferenceError: readerCount is not defined
    at lookForIt (/home/ana/js/scope-chain.js:16:3)
```

`describeBook` declara um nome, `title`, e usa quatro. Ela os achou assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três escopos aninhados. O escopo do arquivo guarda library. Dentro dele, o escopo de openShelf guarda shelfName e opened. Dentro desse, o escopo de describeBook guarda title. Um nome usado em describeBook é procurado primeiro no próprio escopo, depois para fora, um escopo por vez, e nunca para dentro.\"><defs><marker id=\"chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"520\" height=\"222\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o arquivo</text><text x=\"30\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">library = &quot;City Library&quot;</text><rect x=\"46\" y=\"70\" width=\"470\" height=\"152\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">openShelf</text><text x=\"60\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelfName = &quot;Romance&quot;   opened = &quot;09:00&quot;</text><rect x=\"76\" y=\"126\" width=\"420\" height=\"82\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">describeBook</text><text x=\"90\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">title = &quot;Iracema&quot;</text><text x=\"90\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">usa title, shelfName, library, opened</text><path d=\"M600 190 L600 46\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#chain-ah-amber)\"></path><text x=\"610\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1. o próprio escopo</text><text x=\"610\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2. openShelf</text><text x=\"610\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3. o arquivo</text></svg>", "caption": "Um nome é procurado de dentro para fora, e o aninhamento é decidido por onde o código está escrito.", "same": ["2. openShelf"]}
```

**Primeiro o próprio escopo, depois o escopo em que foi escrita, depois o seguinte para fora**, até
chegar ao nível de cima do arquivo. Essa sequência é a **cadeia de escopos**. O primeiro escopo que
tem o nome ganha, e é assim que uma declaração interna sombreia uma externa (aula 3). Se nenhum
escopo o tiver, o resultado é o `ReferenceError` que `lookForIt` produziu: `readerCount is not
defined`.

## Escrita, não chamada

O aninhamento que importa é **onde a função está escrita no código-fonte**, não de onde ela é
chamada. É por isso que esse tipo de escopo se chama **léxico**: dá para descobri-lo lendo o código,
sem rodá-lo. Uma função escrita no topo de um arquivo não enxerga as variáveis da função que por
acaso a chame, e uma função escrita dentro de outra sempre enxerga os nomes dessa outra.

A busca vai **só para fora**. `openShelf` não consegue ler `title`, porque `title` mora num escopo
dentro dela. Os dados entram numa função interna pelos parâmetros e pelos nomes que ela enxerga
para fora; saem de volta pelo que ela devolve.
