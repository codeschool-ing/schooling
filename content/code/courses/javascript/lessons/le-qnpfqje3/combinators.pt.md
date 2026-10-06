---
title: all, allSettled, race e any
version: 1
---

O `Promise.all` tem três irmãos, e **eles diferem no que fazem quando algumas das promessas falham**.
Três espelhos de um catálogo de livros, um deles fora do ar:

```javascript
const wait = (ms, v) => new Promise((ok) => setTimeout(() => ok(v), ms));
const fail = (ms, m) => new Promise((_, no) => setTimeout(() => no(new Error(m)), ms));

const jobs = () => [wait(300, "mirror A"), fail(100, "mirror B is down"), wait(200, "mirror C")];

try {
  await Promise.all(jobs());
} catch (e) {
  console.log("all:       ", e.message);
}

const settled = await Promise.allSettled(jobs());
console.log("allSettled:", settled.map((r) => r.status === "fulfilled" ? r.value : `(${r.reason.message})`));

try {
  console.log("race:      ", await Promise.race(jobs()));
} catch (e) {
  console.log("race:       rejected,", e.message);
}

console.log("any:       ", await Promise.any(jobs()));
```

```
ana@dev:~/js$ node combinators.mjs
all:        mirror B is down
allSettled: [ 'mirror A', '(mirror B is down)', 'mirror C' ]
race:       rejected, mirror B is down
any:        mirror C
```

| | espera | dá certo quando | falha quando |
|---|---|---|---|
| **`all`** | toda promessa | **todas** se cumprem, dando todos os valores em ordem | **qualquer uma** rejeita, na hora |
| **`allSettled`** | toda promessa | sempre, dando o resultado de cada uma | nunca |
| **`race`** | a primeira a se resolver | a primeira se resolve cumprindo | a primeira se resolve rejeitando |
| **`any`** | a primeira a se cumprir | **qualquer uma** se cumpre | todas rejeitam |

Leia a saída junto com a tabela. **O `all` falhou assim que o espelho B falhou**, depois de 100 ms,
sem esperar os outros. O `allSettled` relatou os três, com o motivo de B no lugar de um valor. O
`race` pegou a primeira a se resolver, que foi a falha de B. O `any` ignorou a falha e pegou o
primeiro sucesso, **o espelho C, aos 200 ms, antes de A aos 300**.

Cada um tem o seu uso: `all` quando você precisa de todo resultado, `allSettled` para um relatório do
que funcionou, `any` para a cópia funcionando mais rápida da mesma coisa, e `race` para um tempo
limite, correndo o trabalho de verdade contra uma promessa que rejeita depois de um tempo. A aula 16
faz o tempo limite com a ferramenta feita para isso, `AbortSignal.timeout`.
