---
title: Erros que acontecem depois
version: 1
---

**Um bloco `try` só pega o que é lançado enquanto ele está rodando.** Trabalho que termina depois, num
callback, roda quando o `try` já acabou:

```javascript
try {
  setTimeout(() => {
    throw new Error("thrown inside a timer");
  }, 0);
  console.log("the try block finished");
} catch (err) {
  console.log("caught?", err.message);
}
```

```javascript
async function later() {
  await new Promise((ok) => setTimeout(ok, 10));
  throw new Error("thrown after an await");
}

try {
  await later();
} catch (err) {
  console.log("caught:", err.message);
}
```

```
ana@dev:~/js$ node async-callback.js 2>&1 | head -n 6
the try block finished
/home/ana/js/async-callback.js:3
    throw new Error("thrown inside a timer");
    ^

Error: thrown inside a timer
ana@dev:~/js$ node async-await.mjs
caught: thrown after an await
```

`the try block finished` saiu primeiro: **o `try` agendou o temporizador e terminou antes de o
temporizador disparar.** Quando o callback lançou erro, não havia `try` nenhum na pilha, porque a pilha
só tinha o callback do temporizador (aula 13). O erro não foi pego e parou o programa, e o `catch` ao
lado nunca rodou. O mesmo acontece com um listener de evento, ou com uma leitura de arquivo no estilo
callback da aula 14.

Com `await`, o segundo programa, **o `try` ainda estava rodando**, pausado no `await`, quando a promessa
rejeitou. O `await` transformou a rejeição num throw naquela linha, dentro do `try`, e o `catch` o
recebeu. Esse é um dos motivos mais fortes para escrever código assíncrono com `await`: **os erros
voltam para o lugar que pediu**, onde um `try` pode ficar.

## Onde cada tipo de erro é pego

| o trabalho | pegue com |
|---|---|
| código síncrono | `try`/`catch` em volta da chamada |
| uma promessa, com `await` | `try`/`catch` em volta do `await` |
| uma promessa, sem `await` | `.catch()` na promessa |
| um callback | dentro do próprio callback, ou pelo argumento de erro da API de callback (aula 14) |
