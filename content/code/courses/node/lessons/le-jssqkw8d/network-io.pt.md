---
title: Cem conexões e nenhuma thread a mais
version: 1
---

**Um socket não é lido no pool.** O sistema operacional consegue vigiar milhares de sockets ao mesmo
tempo e dizer quais têm dados, pelo `epoll` no Linux, pelo `kqueue` no macOS e pelas portas de
conclusão de I/O no Windows. A libuv entrega cada socket a esse mecanismo e faz uma pergunta na fase
poll: *quais destes estão prontos?* Nenhuma thread espera por nenhum deles.

Este programa conta as próprias threads enquanto faz isso. Ele inicia um servidor que responde a
toda requisição depois de um segundo, manda cem requisições a ele de uma vez com `fetch`, e depois
lê um arquivo:

```javascript
// threads.js: how many threads this process has, before and after.
const fs = require("node:fs");
const http = require("node:http");

const threads = () => fs.readFileSync("/proc/self/status", "utf8").match(/^Threads:\s+(\d+)/m)[1];
console.log(`at start: ${threads()} threads`);

// A server that answers every request one second later, and 100 requests to it at once.
const server = http.createServer((req, res) => setTimeout(() => res.end("ok"), 1000));
server.listen(3001, "127.0.0.1", async () => {
  const start = performance.now();
  const replies = await Promise.all(
    Array.from({ length: 100 }, () => fetch("http://127.0.0.1:3001/").then((r) => r.text())),
  );
  console.log(`${replies.length} replies in ${Math.round(performance.now() - start)} ms, ${threads()} threads`);
  fs.readFile(__filename, () => {
    console.log(`after one fs.readFile: ${threads()} threads`);
    server.close();
  });
});
```

`/proc/self/status` é um arquivo que o Linux mantém para cada processo, e a linha `Threads:` é a
contagem.

```
ana@dev:~/server/loop$ node threads.js
at start: 7 threads
100 replies in 1161 ms, 7 threads
after one fs.readFile: 11 threads
```

Leia as três linhas em ordem:

1. **O processo já começa com várias threads.** Além da principal, o V8 mantém algumas próprias,
   para compilar e para coletar lixo em segundo plano.
2. **Cem requisições, cada uma esperando um segundo, levaram pouco mais de um segundo, e não
   acrescentaram threads.** As duas pontas das cem conexões estavam no mesmo processo, vigiadas pelo
   `epoll`. Uma thread por requisição teria significado cem a mais, ou uma fila na frente de poucas.
3. **O primeiro `fs.readFile` iniciou o pool**, e a contagem subiu quatro. A libuv cria o pool na
   primeira vez em que algo precisa dele.

Esse é o argumento inteiro a favor do Node num servidor, numa transcrição só: o recurso caro, uma
thread, não é gasto com espera. O endereço é `127.0.0.1` e não um nome porque um nome passaria pelo
`dns.lookup`, e esse fica no pool.
