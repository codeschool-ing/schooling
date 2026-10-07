---
title: O que fraco quer dizer
version: 1
---

O JavaScript libera memória por você. **Um objeto continua vivo enquanto algo que o seu programa
ainda alcança apontar para ele**, e o coletor de lixo o recupera algum tempo depois de a última
referência desse tipo sumir. A aula 19 trata desse processo; esta seção só precisa da regra.

Um `Map` conta como algo que aponta para as suas chaves. **Um `WeakMap` não conta**: a referência
dele a uma chave é fraca, ou seja, é ignorada quando o coletor decide o que ainda está em uso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O programa ainda alcança duas coleções, strong e weak. O Map segura a sua chave com uma seta cheia, então o objeto da chave continua vivo. O WeakMap segura a sua chave com uma seta tracejada que não conta, então, quando nada mais aponta para esse objeto, o coletor de lixo o leva, e a entrada vai junto.\"><defs><marker id=\"weak-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"weak-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"weak-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"30\" width=\"150\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"91\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o programa</text><rect x=\"36\" y=\"72\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"91.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">strong</text><rect x=\"36\" y=\"146\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"91.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">weak</text><rect x=\"220\" y=\"66\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Map</text><rect x=\"220\" y=\"140\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">WeakMap</text><path d=\"M146 88 L216 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#weak-ah-paper-dim)\"></path><path d=\"M146 162 L216 162\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#weak-ah-paper-dim)\"></path><rect x=\"450\" y=\"66\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">{ title: &quot;kept by a Map&quot; }</text><rect x=\"450\" y=\"140\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"575.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">{ title: &quot;kept by a WeakMap&quot; }</text><path d=\"M370 88 L446 88\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" marker-end=\"url(#weak-ah-phosphor)\"></path><path d=\"M370 162 L446 162\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#weak-ah-amber)\"></path><text x=\"575\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">alcançável: fica</text><text x=\"575\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">inalcançável: coletado</text></svg>", "caption": "A chave de um Map é mantida viva pelo Map. A chave de um WeakMap é mantida viva só por todo o resto."}
```

O laboratório consegue mostrar isso acontecendo, com duas chaves feitas para experimentos e não
para programas. `--expose-gc` dá ao script uma função `gc()` que roda o coletor sob demanda, e um
`WeakRef` é uma referência que deixa o script perguntar se um objeto ainda existe sem mantê-lo
vivo:

```javascript
const strong = new Map();
const weak = new WeakMap();

let a = { title: "kept by a Map" };
let b = { title: "kept by a WeakMap" };
strong.set(a, "data");
weak.set(b, "data");

const refA = new WeakRef(a);
const refB = new WeakRef(b);
a = null;
b = null;

setTimeout(() => {
  globalThis.gc();
  console.log("Map key:     ", refA.deref()?.title);
  console.log("WeakMap key: ", refB.deref()?.title);
  console.log("entries in the Map:", strong.size);
}, 0);
```

```
ana@dev:~/js$ node --expose-gc weak-gc.js
Map key:      kept by a Map
WeakMap key:  undefined
entries in the Map: 1
```

Os dois objetos perderam as suas variáveis quando `a` e `b` viraram `null`. **O do `Map` continuava
lá depois da coleta, porque o `Map` ainda apontava para ele**, e o `Map` ainda estava em uso. O do
`WeakMap` foi coletado, e a entrada dele foi junto.

## Por que você não vê isso num programa comum

Sem `--expose-gc`, **quando a coleta acontece é decisão do motor**, e ela roda quando ele julga que
vale recuperar memória, não quando o seu código gostaria. Esse é o verdadeiro motivo de um
`WeakMap` não ter `size` nem laço: uma contagem que mudasse entre duas linhas do seu programa, por
motivos de fora dele, seria um bug esperando para acontecer.

Então a regra para usar as coleções fracas é simples. **Escreva código que esteja certo com a
entrada ainda lá ou não**, o que na prática significa só chegar a uma entrada pelo objeto-chave que
você está segurando. Se você tem a chave, a entrada está lá, porque você está mantendo a chave
viva.
