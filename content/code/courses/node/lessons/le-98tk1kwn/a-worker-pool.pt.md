---
title: Um pool de workers
version: 1
---

**Iniciar uma worker para cada pedido custaria um início a cada vez e iniciaria tantas threads quanto
houvesse pedidos**, mil de uma vez sob carga, todas disputando quatro processadores. Um **pool** inicia
um número fixo uma vez e o mantém; cada job espera numa fila até uma ficar livre. É a mesma forma do
pool de quatro threads da libuv na aula 2, feita em JavaScript:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um pool de quatro workers. Os jobs chegam pela esquerda e esperam numa fila; cada worker livre pega o próximo job, e quando responde fica livre de novo. Uma worker que lança um erro é substituída por uma nova.\"><text x=\"40\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pool.run(job)</text><line x1=\"80\" y1=\"40\" x2=\"80\" y2=\"68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"80.0,68.0 76.9,60.6 83.1,60.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"40\" y=\"70\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fila</text><rect x=\"52\" y=\"84\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"69\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">job</text><rect x=\"94\" y=\"84\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"111\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">job</text><rect x=\"136\" y=\"84\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"153\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">job</text><rect x=\"178\" y=\"84\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">job</text><rect x=\"220\" y=\"84\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"237\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">job</text><line x1=\"270\" y1=\"100\" x2=\"360\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"360.0,100.0 352.6,103.1 352.6,96.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"315\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">próxima livre</text><rect x=\"362\" y=\"20\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker: ocupada</text><rect x=\"362\" y=\"64\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker: ocupada</text><rect x=\"362\" y=\"108\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker: ocupada</text><rect x=\"362\" y=\"152\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker: livre</text><line x1=\"512\" y1=\"37\" x2=\"580\" y2=\"37\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"580.0,37.0 572.6,40.1 572.6,33.9\" fill=\"var(--phosphor)\"></polygon><text x=\"586\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">resposta: resolve</text><line x1=\"512\" y1=\"81\" x2=\"580\" y2=\"81\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"580.0,81.0 572.6,84.1 572.6,77.9\" fill=\"var(--amber)\"></polygon><text x=\"586\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">lança: reject,</text><text x=\"586\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">e uma worker nova</text></svg>", "caption": "Um número fixo de threads, iniciadas uma vez; é a fila que absorve a carga."}
```

```schooling-example
{"language": "javascript", "file": "pool.js", "parts": [
 {"code": "// pool.js: a fixed number of workers, started once, and a queue of jobs for them.\nimport { Worker } from \"node:worker_threads\";\n\nexport class Pool {\n  #file;\n  #all = [];\n  #idle = [];\n  #queue = [];", "note": "**Três listas**: todas as workers, as livres agora, e os jobs esperando. O `#` as deixa privadas da classe."},
 {"code": "  constructor(file, size) {\n    this.#file = file;\n    for (let i = 0; i < size; i++) this.#start();\n  }\n\n  #start() {\n    const worker = new Worker(this.#file);\n    this.#all.push(worker);\n    this.#idle.push(worker);\n  }", "note": "Todas as workers são iniciadas de uma vez, quando o pool é criado, e ficam esperando."},
 {"code": "  run(job) {\n    return new Promise((resolve, reject) => {\n      this.#queue.push({ job, resolve, reject });\n      this.#next();\n    });\n  }", "note": "**O `run` põe o job na fila e devolve uma promise** para a resposta. Quem chama não sabe nem quer saber qual worker o pega."},
 {"code": "  #next() {\n    if (!this.#idle.length || !this.#queue.length) return;\n    const worker = this.#idle.pop();\n    const { job, resolve, reject } = this.#queue.shift();", "note": "**Um job começa quando há uma worker livre e um job esperando**; senão nada acontece até um dos dois chegar."},
 {"code": "    const onMessage = (value) => {\n      worker.off(\"error\", onError);\n      this.#idle.push(worker);\n      resolve(value);\n      this.#next();\n    };", "note": "A resposta: a worker volta para a lista de livres, e o próximo job, se houver, começa nela."},
 {"code": "    const onError = (err) => {\n      worker.off(\"message\", onMessage);\n      this.#all = this.#all.filter((w) => w !== worker);\n      this.#start();\n      reject(err);\n      this.#next();\n    };", "note": "**Um erro lançado numa worker encerra essa worker**, então ela não volta: uma nova é iniciada no lugar e a promise do job é rejeitada. Sem isso, um pool perde uma worker a cada falha até não ter nenhuma."},
 {"code": "    worker.once(\"message\", onMessage);\n    worker.once(\"error\", onError);\n    worker.postMessage(job);\n  }\n\n  close() {\n    return Promise.all(this.#all.map((w) => w.terminate()));\n  }\n}", "note": "O `close` encerra todas as workers, para que um programa que usa o pool possa sair."}
]}
```

A worker de um pool não termina depois de uma resposta. Ela escuta, e responde cada job que recebe;
esta também recusa um job grande demais para terminar, que é como o caminho de falha é testado:

```javascript
// pool-worker.js: stays alive, and answers every job it is sent.
import { parentPort } from "node:worker_threads";
import { countPrimes } from "./primes.js";

parentPort.on("message", ({ from, to }) => {
  if (to > 100_000_000) throw new RangeError(`${to} is more than this worker will count to`);
  parentPort.postMessage(countPrimes(from, to));
});
```

Seis jobs para um pool de duas, o terceiro deles recusado:

```javascript
// jobs.js: six jobs for a pool of two, one of them refused.
import { Pool } from "./pool.js";

const pool = new Pool(new URL("./pool-worker.js", import.meta.url), 2);
const tos = [1e6, 2e6, 1e9, 3e6, 4e6, 5e6];
const results = await Promise.allSettled(tos.map((to) => pool.run({ from: 0, to })));
results.forEach((r, i) => console.log(`up to ${tos[i]}:`, r.status === "fulfilled" ? r.value : r.reason.message));
await pool.close();
```

```
ana@dev:~/server/procs$ node jobs.js
up to 1000000: 78498
up to 2000000: 148933
up to 1000000000: 1000000000 is more than this worker will count to
up to 3000000: 216816
up to 4000000: 283146
up to 5000000: 348513
```

**O job recusado falhou com a própria mensagem e os jobs depois dele rodaram mesmo assim**, na worker
iniciada para substituir a que lançou o erro.

## Um pool atrás de um servidor

O motivo de tudo isso é um servidor que continua respondendo enquanto calcula. O `busy.js` tem uma rota
lenta e uma rápida, e conta na thread principal ou num pool de quatro:

```javascript
// busy.js: a server with a slow route, counted on the main thread or in a pool.
import http from "node:http";
import { availableParallelism } from "node:os";
import { Pool } from "./pool.js";
import { countPrimes } from "./primes.js";

const usePool = process.argv[2] === "pool";
const pool = usePool ? new Pool(new URL("./pool-worker.js", import.meta.url), availableParallelism()) : null;

http
  .createServer(async (req, res) => {
    if (req.url === "/primes") {
      const job = { from: 0, to: 5_000_000 };
      const count = usePool ? await pool.run(job) : countPrimes(job.from, job.to);
      return res.end(`${count} primes`);
    }
    res.end("ok");
  })
  .listen(3000, "127.0.0.1", () => console.log(`busy.js on :3000, ${usePool ? "with a pool" : "no pool"}`));
```

Quatro pedidos lentos ao mesmo tempo e, um instante depois, um rápido. Primeiro com `node busy.js`
rodando no outro terminal, depois com `node busy.js pool`:

```
ana@dev:~/server/procs$ for i in 1 2 3 4; do curl -s -o /dev/null -w 'primes %{time_total} s\n' http://127.0.0.1:3000/primes & done; sleep 0.2; curl -s -o /dev/null -w 'health %{time_total} s\n' http://127.0.0.1:3000/health; wait
primes 1.041229 s
primes 2.082061 s
primes 3.120471 s
primes 4.203286 s
health 4.002002 s
```

```
ana@dev:~/server/procs$ for i in 1 2 3 4; do curl -s -o /dev/null -w 'primes %{time_total} s\n' http://127.0.0.1:3000/primes & done; sleep 0.2; curl -s -o /dev/null -w 'health %{time_total} s\n' http://127.0.0.1:3000/health; wait
health 0.005477 s
primes 1.083871 s
primes 1.089210 s
primes 1.109622 s
primes 1.120725 s
```

**Na thread principal, as quatro contagens rodaram uma depois da outra e o pedido rápido esperou quatro
segundos atrás delas**: o loop bloqueado da aula 2, medido. **Com o pool, as quatro rodaram ao mesmo
tempo, cerca de um segundo cada, e o pedido rápido foi respondido em milissegundos**, porque a thread
principal só passava mensagens. Um pool de quatro com um quinto pedido lento o poria na fila, e essa é
a ideia: a fila fica na memória e custa pouco, e os processadores não ficam sobrecarregados.

Para um serviço de verdade, o pacote `piscina` é este pool com as partes que ficaram de fora aqui:
cancelar um job com um `AbortSignal`, um limite para o tamanho da fila, e um número de workers que
cresce e diminui com a carga.
