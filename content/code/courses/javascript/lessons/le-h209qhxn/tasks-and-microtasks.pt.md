---
title: Tarefas e microtasks
version: 1
---

Os callbacks que esperam a pilha esvaziar esperam numa de duas filas, e **a fila decide quando eles
rodam**:

- a **fila de tarefas** guarda pedaços inteiros de trabalho: o callback de um temporizador, o handler
  de um clique, o fim de uma requisição de rede. **Uma tarefa roda por vez**, e o laço pega a mais
  antiga primeiro;
- a **fila de microtasks** guarda pequenas continuações que precisam acontecer o quanto antes: os
  callbacks de promessas (`.then`, e o que vem depois de um `await`), e o que for entregue a
  `queueMicrotask`. **Quando a pilha esvazia, todo microtask roda antes da próxima tarefa**, inclusive
  os microtasks enfileirados enquanto a fila era esvaziada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O event loop. A pilha de chamadas roda uma tarefa até o fim. Quando ela esvazia, todo microtask da fila de microtasks roda, inclusive os enfileirados durante o esvaziamento. Depois o navegador pode desenhar a página. Depois o laço pega a tarefa mais antiga da fila de tarefas e a roda, e o ciclo se repete.\"><defs><marker id=\"loop-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><defs><marker id=\"loop-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"loop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">pilha de chamadas</text><rect x=\"50\" y=\"70\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">format</text><rect x=\"50\" y=\"110\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">render</text><rect x=\"50\" y=\"150\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><text x=\"120\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma tarefa, até o fim</text><rect x=\"290\" y=\"20\" width=\"410\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"495\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">fila de microtasks: todos, toda vez</text><rect x=\"310\" y=\"62\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">promise .then</text><rect x=\"440\" y=\"62\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">queueMicrotask</text><rect x=\"570\" y=\"62\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await …</text><rect x=\"290\" y=\"160\" width=\"410\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"495\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fila de tarefas: uma por vez</text><rect x=\"310\" y=\"202\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">setTimeout</text><rect x=\"440\" y=\"202\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">click</text><rect x=\"570\" y=\"202\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fetch done</text><path d=\"M220 60 L286 60\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#loop-ah-amber)\"></path><text x=\"253\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><path d=\"M495 120 L495 156\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#loop-ah-paper-dim)\"></path><text x=\"505\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2. talvez desenhar um quadro</text><path d=\"M286 216 L224 216\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.6\" marker-end=\"url(#loop-ah-paper)\"></path><text x=\"253\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text></svg>", "caption": "Uma tarefa, depois todos os microtasks, depois talvez um quadro, depois a próxima tarefa."}
```

A ordem de um programa inteiro decorre dessa regra:

```javascript
console.log("A: synchronous");

setTimeout(() => console.log("B: task (setTimeout)"), 0);

Promise.resolve().then(() => console.log("C: microtask (promise)"));

queueMicrotask(() => console.log("D: microtask (queueMicrotask)"));

setTimeout(() => {
  console.log("E: second task");
  Promise.resolve().then(() => console.log("F: microtask queued by a task"));
}, 0);

setTimeout(() => console.log("G: third task"), 0);

console.log("H: synchronous, last line");
```

```
ana@dev:~/js$ node order.js
A: synchronous
H: synchronous, last line
C: microtask (promise)
D: microtask (queueMicrotask)
B: task (setTimeout)
E: second task
F: microtask queued by a task
G: third task
```

1. **A** e **H** são código comum, e rodam primeiro, em ordem. O próprio programa é a primeira tarefa.
2. A pilha esvazia, então **todo microtask roda**: **C** e **D**, na ordem em que foram enfileirados.
3. Depois a tarefa mais antiga, **B**.
4. Depois a próxima tarefa, **E**, que enfileira o microtask **F**. **F roda antes de G**: depois de toda
   tarefa, a fila de microtasks é esvaziada de novo antes de o laço pegar outra tarefa.

## A mesma ordem no navegador

```html
<!doctype html>
<script src="order.js"></script>
```

```
ana@dev:~/js$ page order.html
A: synchronous
H: synchronous, last line
C: microtask (promise)
D: microtask (queueMicrotask)
B: task (setTimeout)
E: second task
F: microtask queued by a task
G: third task
```

O mesmo arquivo, carregado por uma página, imprimiu as mesmas oito linhas na mesma ordem. **As duas
filas e a regra entre elas são as mesmas em todo motor**; o que o hospedeiro acrescenta é o que põe
tarefas na fila, cliques no navegador e leituras de arquivo no Node.

## Um microtask pode segurar tudo

```javascript
setTimeout(() => console.log("task"), 0);

let n = 0;
function again() {
  n += 1;
  if (n < 5) queueMicrotask(again);
  else console.log("5 microtasks ran first");
}
queueMicrotask(again);
```

```
ana@dev:~/js$ node chained.js
5 microtasks ran first
task
```

Cada microtask enfileirou outro, e **os cinco rodaram antes da tarefa do temporizador**, porque a fila
tinha de estar vazia antes. Cinco não fazem mal. Uma corrente que nunca para de enfileirar é uma
página em que nenhum clique, temporizador ou quadro roda de novo, e nada acusa erro, porque nada está
errado a não ser que nunca termina.
