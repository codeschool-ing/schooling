---
title: Worker threads
version: 1
---

**Uma worker thread é uma segunda thread de JavaScript dentro do mesmo processo**, com um event loop e
um heap próprios. Ela inicia mais rápido que um processo e ocupa menos memória, e roda em outro
processador ao mesmo tempo que a thread principal. A aula 2 disse que o JavaScript no Node roda numa
thread só; isso vale para cada thread, e o `node:worker_threads` é como um programa ganha mais de uma.

```schooling-example
{"language": "javascript", "file": "worker.js", "parts": [
 {"code": "// worker.js: runs on a thread of its own, with workerData as its input.\nimport { parentPort, workerData } from \"node:worker_threads\";\nimport { countPrimes } from \"./primes.js\";", "note": "**O `workerData` é a entrada dada quando a worker foi criada**, e o `parentPort` é o canal de volta para a thread que a criou."},
 {"code": "parentPort.postMessage(countPrimes(workerData.from, workerData.to));", "note": "Uma resposta, e depois não sobra nada para o loop desta thread, então ela termina sozinha."}
]}
```

```schooling-example
{"language": "javascript", "file": "threads.js", "parts": [
 {"code": "// threads.js: the same count, on one thread and then split across several.\nimport { Worker } from \"node:worker_threads\";\nimport { availableParallelism } from \"node:os\";\nimport { countPrimes } from \"./primes.js\";\n\nconst N = 10_000_000;", "note": "O `availableParallelism()` é quantos processadores este programa pode usar ao mesmo tempo: o número certo de workers para um trabalho que só calcula."},
 {"code": "function inWorker(from, to) {\n  return new Promise((resolve, reject) => {\n    const worker = new Worker(new URL(\"./worker.js\", import.meta.url), { workerData: { from, to } });\n    worker.once(\"message\", resolve);\n    worker.once(\"error\", reject);\n  });\n}", "note": "**Uma worker embrulhada numa promise**: a primeira mensagem dela a resolve e um erro lançado lá dentro a rejeita. O arquivo é dado como uma URL ao lado deste módulo, para ser achado de onde quer que o programa seja iniciado."},
 {"code": "let started = performance.now();\nconsole.log(`main thread: ${countPrimes(0, N)} primes in ${Math.round(performance.now() - started)} ms`);", "note": "A contagem inteira na thread principal, para comparar."},
 {"code": "const threads = availableParallelism();\nconst step = N / threads;\nstarted = performance.now();\nconst parts = await Promise.all(Array.from({ length: threads }, (_, i) => inWorker(i * step, (i + 1) * step)));\nconst total = parts.reduce((a, b) => a + b, 0);\nconsole.log(`${threads} workers: ${total} primes in ${Math.round(performance.now() - started)} ms`, parts);", "note": "**O mesmo intervalo em fatias iguais, uma por worker, todas ao mesmo tempo.** O `Promise.all` espera cada fatia."}
]}
```

```
ana@dev:~/server/procs$ node threads.js
main thread: 664579 primes in 2763 ms
4 workers: 664579 primes in 959 ms [ 183072, 165441, 159748, 156318 ]
```

**A mesma resposta, umas três vezes mais rápido em quatro processadores.** Não quatro: as fatias são
iguais no tamanho e não no trabalho, já que um número maior leva mais tempo para testar, então a
última fatia é a que todos esperam, e iniciar quatro workers também custa alguma coisa. Essa
diferença entre os processadores que você tem e o ganho que você obtém é normal, e é por isso que uma
medição vale mais que uma multiplicação.

**Uma worker é para calcular, não para esperar.** Ler um arquivo, consultar um banco ou chamar uma API
já acontecem fora da thread principal, no sistema ou no pool da libuv da aula 2. Pôr isso numa worker
acrescenta uma thread que espera onde a principal teria esperado, e não economiza nada.
