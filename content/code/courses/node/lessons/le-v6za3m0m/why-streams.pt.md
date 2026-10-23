---
title: Por que os streams existem
version: 1
---

**O `readFile` segura o arquivo inteiro na memória; um stream segura um pedaço dele de cada vez.**
Para um arquivo pequeno a diferença é nenhuma. Para um grande ela é a diferença entre um servidor que
responde e um que fica sem memória, e é fácil de medir.

Primeiro, algo grande. Este programa escreve um log de acessos, três milhões de linhas que são as
mesmas em toda execução, uns 130 megabytes:

```javascript
// makelog.js: write an access log of N lines, the same every time.
import { createWriteStream } from "node:fs";
import { once } from "node:events";

const n = Number(process.argv[2] ?? 3_000_000);
const out = createWriteStream("access.log");
const paths = ["/links", "/7ctxqn", "/links/7ctxqn", "/qh95f4", "/nothing"];
const statuses = [200, 302, 200, 302, 404];
let seed = 42;
const next = () => (seed = (seed * 1103515245 + 12345) % 2147483648);

for (let i = 0; i < n; i++) {
  const k = next() % paths.length;
  const line = `2026-10-01T12:00:${String(i % 60).padStart(2, "0")}Z GET ${paths[k]} ${statuses[k]} ${(next() % 900) + 100}ms\n`;
  if (!out.write(line)) await once(out, "drain");
}
out.end();
await once(out, "finish");
console.log(`wrote ${n} lines`);
```

Ele já escreve com um stream, e a linha do `drain` nele é o assunto da seção sobre contrapressão.
Agora dois programas que contam os 404 dele, um com `readFile` e um com stream:

```javascript
// whole.js
import { readFile } from "node:fs/promises";

const text = await readFile("access.log", "utf8");
let missing = 0;
for (const line of text.split("\n")) if (line.includes(" 404 ")) missing++;
console.log(`${missing} not found; peak memory ${Math.round(process.resourceUsage().maxRSS / 1024)} MB`);
```

```javascript
// streamed.js
import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";

let missing = 0;
for await (const line of createInterface({ input: createReadStream("access.log"), crlfDelay: Infinity })) {
  if (line.includes(" 404 ")) missing++;
}
console.log(`${missing} not found; peak memory ${Math.round(process.resourceUsage().maxRSS / 1024)} MB`);
```

O `maxRSS` é o máximo de memória que o processo segurou em algum momento, medido pelo sistema
operacional.

```
ana@dev:~/server/files$ node makelog.js && ls -lh access.log
wrote 3000000 lines
-rw-r--r-- 1 ana ana 127M Oct 22 19:16 access.log
ana@dev:~/server/files$ node whole.js
610582 not found; peak memory 453 MB
ana@dev:~/server/files$ node streamed.js
610582 not found; peak memory 80 MB
```

**Mesma resposta, uma fração da memória.** O `whole.js` segurou o arquivo como uma string e depois um
array de três milhões de strings; o `streamed.js` nunca segurou mais que um pedaço de 64 kilobytes e a
linha sendo olhada. A diferença cresce com o arquivo e a do stream não: um log dez vezes maior custa ao
`whole.js` dez vezes a memória, e num servidor com dez requisições assim ao mesmo tempo isso é o
processo morto por falta dela.
