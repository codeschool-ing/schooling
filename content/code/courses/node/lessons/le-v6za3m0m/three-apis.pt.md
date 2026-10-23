---
title: Três jeitos de ler um arquivo
version: 1
---

**O `node:fs` oferece cada operação em três formas**, e a aula 2 já explicou o que as separa: onde a
espera acontece.

| forma | como é | onde ela espera |
|---|---|---|
| síncrona | `fs.readFileSync(caminho)` devolve o conteúdo | na thread principal, bloqueando tudo |
| callback | `fs.readFile(caminho, (err, data) => …)` | no pool de threads; o callback roda depois |
| promise | `await readFile(caminho)` do `node:fs/promises` | no pool de threads; a promise se resolve depois |

A mesma leitura nas três, com uma linha impressa depois que cada chamada começa:

```javascript
// three.js
import fs from "node:fs";
import { readFile } from "node:fs/promises";

const name = new URL(import.meta.url).pathname;

const a = fs.readFileSync(name, "utf8");
console.log(`1. sync: ${a.length} characters, already here`);

fs.readFile(name, "utf8", (err, b) => {
  if (err) throw err;
  console.log(`4. callback: ${b.length} characters`);
});
console.log("2. the callback read has started");

const pending = readFile(name, "utf8");
console.log("3. the promise read has started");
console.log(`5. promise: ${(await pending).length} characters`);
```

```
ana@dev:~/server/files$ node three.js
1. sync: 560 characters, already here
2. the callback read has started
3. the promise read has started
4. callback: 560 characters
5. promise: 560 characters
```

A leitura síncrona terminou antes de a próxima linha rodar. As outras duas começaram, o programa
seguiu, e os resultados chegaram depois, na ordem em que o pool os terminou. **Este curso usa a forma
com promise**, o `node:fs/promises`, para tudo depois da inicialização: ela se lê como código síncrono
com `await`, os erros chegam como exceções que um `try` captura, e ela nunca bloqueia o loop. A forma
com callback é a que código e documentação mais antigos usam, e faz o mesmo trabalho.
