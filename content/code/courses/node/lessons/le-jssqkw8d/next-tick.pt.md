---
title: process.nextTick, e a fila antes da fila
version: 1
---

**`process.nextTick(fn)` roda `fn` assim que o trecho atual de JavaScript termina, antes de qualquer
callback de promise e antes de o loop seguir.** Ele é mais antigo que as promises no Node, e tem a
própria fila, que é esvaziada primeiro:

```javascript
// ticks.js
console.log("1 synchronous");
setTimeout(() => console.log("5 timeout"), 0);
setImmediate(() => console.log("6 immediate"));
Promise.resolve().then(() => console.log("4 promise"));
process.nextTick(() => console.log("3 nextTick"));
console.log("2 synchronous, last line");
```

```
ana@dev:~/server/loop$ node ticks.js
1 synchronous
2 synchronous, last line
3 nextTick
4 promise
6 immediate
5 timeout
```

A ordem é a das filas na ordem em que o Node as esvazia: o próprio arquivo, depois a fila do
`nextTick`, depois as microtasks, depois as fases do loop — timers, depois check. Os números foram
escritos para bater com o que foi impresso; as linhas foram escritas numa ordem diferente de
propósito.

## Para que serve, e quanto custa

As bibliotecas do próprio Node usam o `nextTick` para uma tarefa acima de todas: **tornar um callback
assíncrono sempre, mesmo quando a resposta já é conhecida.** Uma função que às vezes chama de volta
na hora e às vezes depois é uma armadilha, porque o código depois da chamada roda antes do callback
num caso e depois dele no outro. Adiar com `nextTick` faz com que seja sempre "depois", quase sem
custo.

O custo é que a fila do `nextTick` é esvaziada **por completo**, inclusive os ticks acrescentados
enquanto ela é esvaziada, antes de qualquer outra coisa acontecer. Uma função que se agenda com
`nextTick` nunca deixa o loop chegar à fase poll, então nenhuma requisição é lida de novo:

```javascript
// starve.js
let ticks = 0;
function again() {
  ticks++;
  if (ticks < 1_000_000) process.nextTick(again);
}
setTimeout(() => console.log(`the timer ran after ${ticks} ticks`), 0);
again();
```

```
ana@dev:~/server/loop$ node starve.js
the timer ran after 1000000 ticks
```

O timer vencia em um milissegundo e esperou um milhão de ticks. Sem o limite no `if`, esperaria para
sempre. **No seu próprio código, prefira `queueMicrotask` ou uma promise resolvida** quando precisar
de "depois disto, mas logo"; eles têm o mesmo tipo de risco com uma fila a menos para raciocinar, e a
documentação do Node recomenda o mesmo.
