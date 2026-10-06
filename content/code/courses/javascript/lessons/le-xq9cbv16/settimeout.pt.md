---
title: setTimeout: uma espera que é um mínimo
version: 1
---

**`setTimeout(fn, ms)` põe `fn` na fila de tarefas depois de passarem pelo menos `ms`
milissegundos**, e devolve um id que você usa para cancelá-lo. Argumentos depois da espera são
passados para `fn`:

```javascript
const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();

const id = setTimeout((title, copies) => {
  console.log(`reminder after about ${round(performance.now() - start)} ms: return ${title} (${copies})`);
}, 300, "Iracema", 2);
console.log("timer id:", typeof id);

const cancelled = setTimeout(() => console.log("never printed"), 200);
clearTimeout(cancelled);

const busyUntil = performance.now() + 500;
while (performance.now() < busyUntil) {}
console.log("busy loop finished after about", round(performance.now() - start), "ms");
```

```
ana@dev:~/js$ node timeout.js
timer id: object
busy loop finished after about 500 ms
reminder after about 500 ms: return Iracema (2)
```

O lembrete foi armado para 300 ms e **rodou por volta de 500 ms**. O temporizador disparou aos 300, e o
callback entrou na fila nessa hora. Mas o programa ainda estava no laço ocupado, e a regra da aula 13
vale: nada roda até a pilha esvaziar. **A espera diz quando o callback pode rodar, nunca que vai
rodar.** O programa arredonda todo tempo para os 100 ms mais próximos, porque o número exato muda
alguns milissegundos de uma execução para outra.

## O resto da interface

- **`clearTimeout(id)` cancela um temporizador que ainda não rodou**, então `never printed` nunca saiu.
  Limpar um temporizador que já rodou não faz mal;
- argumentos extras, `"Iracema"` e `2` aqui, são passados ao callback. Uma arrow que captura os
  valores (aula 6) faz o mesmo e é mais comum;
- no Node o id é um **objeto** com métodos próprios, usados na última seção desta aula; no navegador é
  um número. Trate-o como um valor opaco que você devolve ao `clearTimeout`.

## Quando a espera importa

Um temporizador é a ferramenta certa para "faça isto depois": esconder um aviso depois de cinco
segundos, tentar uma requisição de novo depois de uma pausa (aula 16). **É a ferramenta errada para
medir tempo**, como mostra o lembrete. Para saber quanto algo levou, leia o relógio antes e depois,
que é o que todo programa desta aula faz com `performance.now()`.
