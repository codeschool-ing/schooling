---
title: Listeners e temporizadores que ninguém removeu
version: 1
---

Um listener é uma função guardada pelo objeto que ele escuta. **Enquanto esse objeto viver, o listener
vive, e tudo o que a closure dele capturou também.** Acrescentar um por requisição a um objeto que
sobrevive às requisições é o vazamento clássico do Node:

```javascript
const { EventEmitter } = require("node:events");

const catalogue = new EventEmitter();
process.on("warning", (w) => console.log(`${w.name}: ${w.message}`));

function handleRequest(n) {
  const page = { n, rows: new Array(10_000).fill("row") };
  catalogue.on("updated", () => console.log("refresh page", page.n));
}

for (let n = 1; n <= 12; n++) handleRequest(n);
console.log("listeners now:", catalogue.listenerCount("updated"));
```

```
ana@dev:~/js$ node --no-warnings listeners.js
listeners now: 12
MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 updated listeners added to [EventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
```

Cada "requisição" acrescentou um listener a `catalogue`, e a closure de cada listener segurava a sua
`page`, com as suas dez mil linhas. **Doze requisições, doze listeners, doze páginas mantidas vivas
enquanto o catálogo existir.** O Node percebeu: passados dez listeners para um evento, um
`EventEmitter` imprime `MaxListenersExceededWarning`, e a mensagem diz do que suspeita, um vazamento de
memória. O programa imprimiu o aviso ele mesmo por `process.on("warning")`, que é como um servidor o
mandaria para os seus logs.

**Não silencie esse aviso aumentando o limite.** Ele quase sempre está certo. O conserto é remover o
listener quando a requisição termina, com `off` ou `removeListener` e a mesma função (aula 12), ou usar
`once` quando o listener deve rodar uma vez.

## Temporizadores

```javascript
function startWidget() {
  const big = new Array(1_000_000).fill("data");
  const timer = setInterval(() => big.length, 1000);
  return { timer, ref: new WeakRef(big) };
}

const forgotten = startWidget();
const stopped = startWidget();
clearInterval(stopped.timer);

setTimeout(() => {
  globalThis.gc();
  console.log("widget never stopped, data alive:", forgotten.ref.deref() !== undefined);
  console.log("widget stopped, data alive:      ", stopped.ref.deref() !== undefined);
  process.exit(0);
}, 100);
```

```
ana@dev:~/js$ node --expose-gc timer-leak.js
widget never stopped, data alive: true
widget stopped, data alive:       false
```

Dois widgets começaram cada um um intervalo cujo callback se referia a um array de um milhão de itens.
**O que teve o intervalo limpo largou os seus dados; o que ninguém parou manteve o array vivo**, porque
o sistema de temporizadores segura o callback e o callback segura o array. Numa página, o mesmo
acontece com um `setInterval` iniciado por um componente que foi removido, e com listeners em `window`
ou `document` acrescentados por elementos que não existem mais. A regra da aula 15 é o conserto: todo
temporizador tem uma limpeza correspondente, escrita ao mesmo tempo.
