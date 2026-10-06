---
title: Promessas
version: 1
---

**Uma promessa é um objeto que representa um resultado ainda não pronto.** Em vez de receber um
callback, uma função devolve uma promessa na hora, e você prende à promessa o que deve acontecer em
seguida:

```javascript
const { readFile } = require("node:fs/promises");

const p = readFile("books/12.json", "utf8");
console.log(p);

p.then((text) => JSON.parse(text))
  .then((book) => readFile(`authors/${book.authorId}.json`, "utf8").then((a) => [book, JSON.parse(a)]))
  .then(([book, author]) => console.log(book.title, "by", author.name))
  .catch((err) => console.log("failed:", err.code))
  .finally(() => console.log("done, either way"));

readFile("books/99.json", "utf8")
  .then(() => console.log("never printed"))
  .catch((err) => console.log("book 99:", err.code));
```

```
ana@dev:~/js$ node promise.js
Promise { <pending> }
book 99: ENOENT
Dom Casmurro by Machado de Assis
done, either way
```

Impressa na hora, a promessa é `Promise { <pending> }`: ela existe, e o resultado dela ainda não.
**`.then(fn)` registra o que fazer com o valor, `.catch(fn)` o que fazer com um erro, e
`.finally(fn)` o que fazer de qualquer jeito.**

## Três estados

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma promessa começa pendente. Ela se resolve uma vez, ou cumprida com um valor, o que roda os callbacks de then, ou rejeitada com um motivo, o que roda os callbacks de catch. O finally roda nos dois casos. Uma promessa resolvida nunca muda de novo.\"><defs><marker id=\"states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"76\" width=\"150\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pendente</text><text x=\"105.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Promise { &lt;pending&gt; }</text><rect x=\"300\" y=\"20\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">cumprida</text><text x=\"390.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com um valor</text><rect x=\"300\" y=\"132\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">rejeitada</text><text x=\"390.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com um motivo, um Error</text><path d=\"M180 92 L296 44\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-phosphor)\"></path><path d=\"M180 108 L296 156\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-amber)\"></path><text x=\"236\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">resolve(v)</text><text x=\"236\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">reject(e)</text><rect x=\"560\" y=\"20\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.then(fn)</text><rect x=\"560\" y=\"132\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.catch(fn)</text><path d=\"M480 44 L556 44\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-phosphor)\"></path><path d=\"M480 156 L556 156\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-amber)\"></path><text x=\"630\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">.finally: os dois</text></svg>", "caption": "Três estados, e uma promessa sai de pendente uma vez e para sempre."}
```

Uma promessa fica **pendente** até se **resolver**, uma vez, como **cumprida** com um valor ou
**rejeitada** com um motivo. Depois disso nunca muda. Você mesmo pode fazer uma, e é assim que uma API
de callback ou um temporizador vira promessa:

```javascript
function wait(ms, value) {
  return new Promise((resolve) => setTimeout(() => resolve(value), ms));
}

function failAfter(ms, message) {
  return new Promise((resolve, reject) => setTimeout(() => reject(new Error(message)), ms));
}

const p = wait(100, "a value");
console.log(p);
p.then((v) => console.log("fulfilled with", v, p));

const q = failAfter(150, "the shelf is empty");
q.catch((e) => console.log("rejected with", e.message, q));
```

```
ana@dev:~/js$ node make-promise.js 2>&1 | head -n 8
Promise { <pending> }
fulfilled with a value Promise { 'a value' }
rejected with the shelf is empty Promise {
  <rejected> Error: the shelf is empty
      at Timeout._onTimeout (/home/ana/js/make-promise.js:6:67)
      at listOnTimeout (node:internal/timers:588:17)
      at process.processTimers (node:internal/timers:523:7)
}
```

A função entregue a `new Promise` recebe duas funções, `resolve` e `reject`, e chama uma delas quando
o trabalho termina. Impressa depois de resolvida, a promessa mostra o seu estado: o valor, ou
`<rejected>` e o erro.

## Encadeando

**O `.then` devolve uma promessa nova, para o que o callback dele devolver.** É isso que deixa os
passos se alinharem em vez de se aninharem, e por que um `.catch` no fim de `promise.js` cobriu as
duas leituras: um erro em qualquer ponto da corrente pula os `.then` que faltam e cai no primeiro
`.catch` abaixo dele.

```javascript
Promise.resolve(2)
  .then((n) => n * 10)
  .then((n) => {
    console.log("got", n);
  })
  .then((n) => console.log("then got", n));
```

```
ana@dev:~/js$ node chain-values.js
got 20
then got undefined
```

O primeiro callback devolveu `20`, e o seguinte o recebeu. **O segundo callback não devolveu nada**,
só imprimiu, então o terceiro recebeu `undefined`. Esquecer o `return` dentro de um `.then` é o bug
mais comum em correntes de promessas: o próximo passo roda cedo demais, com nada.
