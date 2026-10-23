---
title: Bloqueando o loop
version: 1
---

**O único jeito de deixar um servidor Node lento para todo mundo é manter a thread principal
ocupada.** A aula 1 disse isso numa figura. Esta seção faz isso e mede.

```javascript
// busy.js: one route that computes for two seconds, and one that does nothing.
const http = require("node:http");
const { monitorEventLoopDelay } = require("node:perf_hooks");

const delay = monitorEventLoopDelay({ resolution: 1 });
delay.enable();

function spin(ms) {
  const end = Date.now() + ms;
  while (Date.now() < end) {} // busy: nothing else can run meanwhile
}

http
  .createServer((req, res) => {
    if (req.url === "/slow") spin(2000);
    if (req.url === "/delay") {
      res.end(`event loop delay: max ${Math.round(delay.max / 1e6)} ms, mean ${Math.round(delay.mean / 1e6)} ms\n`);
      return delay.reset();
    }
    res.end(`${req.url} done\n`);
  })
  .listen(3000, "127.0.0.1", () => console.log("listening on 3000"));
```

O `spin` faz o papel de um trabalho de verdade: uma ordenação, um relatório, uma expressão regular
que retrocede. É um laço que olha o relógio, então não faz nada de útil e segura a thread exatamente
pelo tempo que mandarem. Inicie o servidor num terminal, e no outro peça o `/fast` sozinho, depois o
`/slow` em segundo plano seguido na hora do `/fast` de novo:

```
ana@dev:~/server/loop$ curl -s -o /dev/null -w 'fast alone: %{time_total} s\n' http://127.0.0.1:3000/fast
fast alone: 0.003214 s
ana@dev:~/server/loop$ curl -s http://127.0.0.1:3000/delay
event loop delay: max 4 ms, mean 1 ms
ana@dev:~/server/loop$ curl -s -o /dev/null -w 'slow: %{time_total} s\n' http://127.0.0.1:3000/slow &
ana@dev:~/server/loop$ sleep 0.2; curl -s -o /dev/null -w 'fast behind slow: %{time_total} s\n' http://127.0.0.1:3000/fast
slow: 2.000612 s
fast behind slow: 1.800269 s
ana@dev:~/server/loop$ sleep 0.5; curl -s http://127.0.0.1:3000/delay
event loop delay: max 2001 ms, mean 5 ms
```

O `-w` faz o `curl` imprimir quanto a requisição inteira levou, e o `-o /dev/null` joga o corpo fora.
**O `/fast` levou poucos milissegundos sozinho, e quase dois segundos atrás do `/slow`.** O código
dele não mudou; ele esperou a thread. Com cem usuários, todos esperam, e nenhum deles pediu nada
lento.

## Medindo de dentro

O `monitorEventLoopDelay` arma um timer para disparar a cada milissegundo e registra o atraso de
cada um. Um loop ocioso nunca se atrasa mais que alguns milissegundos. **Um timer atrasado é a
medida do próprio loop de quanto tempo o seu código o segurou**, e o `/delay` informa o pior desde a
última vez em que foi perguntado: a segunda leitura pegou os dois segundos do `/slow`. Um servidor
que registra esse número, ou o expõe ao monitoramento, encontra uma rota que bloqueia no dia em que
ela vai para produção, e não no dia em que alguém reclama.

## O que fazer em vez disso

Três respostas, na ordem em que vale recorrer a elas:

1. **Fazer menos.** Um relatório calculado uma vez e guardado, uma lista paginada em vez de ordenada
   inteira, uma expressão regular sem repetição aninhada.
2. **Dividir.** Um trabalho feito em fatias com `setImmediate` entre elas deixa outros callbacks
   rodarem nos intervalos, como a aula 13 do javascript fez numa página.
3. **Tirar da thread principal.** Uma worker thread, um processo filho, ou outro serviço. A aula 10
   faz os três.
