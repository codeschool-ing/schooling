---
title: Copiado, transferido ou compartilhado
version: 1
---

**Duas threads de um processo ainda não veem os objetos uma da outra.** Uma mensagem entre elas é
copiada, com o algoritmo de *structured clone*, que copia mais tipos que o JSON (um `Map`, um `Date`,
um typed array) e copia todos do mesmo jeito. Há dois jeitos de evitar a cópia, só para bytes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três jeitos de os dados chegarem a uma worker. Copiados: a thread principal fica com os dados e a worker recebe uma cópia separada. Transferidos: os bytes vão para a worker e a thread principal fica com um buffer vazio. Compartilhados: um bloco de memória que as duas threads leem e escrevem ao mesmo tempo.\"><text x=\"20\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">copiado</text><text x=\"20\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">postMessage(x)</text><rect x=\"200\" y=\"30\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">principal</text><rect x=\"420\" y=\"30\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><rect x=\"284\" y=\"38\" width=\"28\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"494\" y=\"38\" width=\"28\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"320\" y1=\"50\" x2=\"418\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,50.0 410.6,53.1 410.6,46.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"545\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os dois têm, duas vezes</text><text x=\"20\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">transferido</text><text x=\"20\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">postMessage(x, [x.buffer])</text><rect x=\"200\" y=\"100\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">principal</text><rect x=\"420\" y=\"100\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><rect x=\"284\" y=\"108\" width=\"28\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"494\" y=\"108\" width=\"28\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"320\" y1=\"120\" x2=\"418\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,120.0 410.6,123.1 410.6,116.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"545\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a worker tem; o nosso fica vazio</text><text x=\"20\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">compartilhado</text><text x=\"20\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SharedArrayBuffer</text><rect x=\"200\" y=\"170\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">principal</text><rect x=\"420\" y=\"170\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><rect x=\"332\" y=\"176\" width=\"76\" height=\"28\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">um bloco</text><line x1=\"320\" y1=\"190\" x2=\"332\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><line x1=\"408\" y1=\"190\" x2=\"420\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"545\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os dois juntos: use Atomics</text></svg>", "caption": "Uma cópia custa tempo, uma transferência custa ao remetente a sua cópia, e compartilhar custa cuidado.", "same": ["worker"]}
```

Os dois primeiros, num programa só:

```schooling-example
{"language": "javascript", "file": "copy.js", "parts": [
 {"code": "// copy.js: what postMessage does to the data it is given.\nimport { Worker } from \"node:worker_threads\";\n\nconst worker = new Worker(\n  `const { parentPort } = require(\"node:worker_threads\");\n   parentPort.on(\"message\", (m) => { m.list.push(\"added by the worker\"); parentPort.postMessage(m.list.length); });`,\n  { eval: true },\n);", "note": "**O código de uma worker pode ser uma string**, com `eval: true`, o que mantém uma demonstração num arquivo só. Código dado assim é CommonJS, e por isso usa `require`."},
 {"code": "const list = [\"one\", \"two\"];\nworker.postMessage({ list });\nconsole.log(\"the worker's copy has\", await new Promise((r) => worker.once(\"message\", r)), \"items\");\nconsole.log(\"ours still has\", list.length);", "note": "**Copiado**: a worker pôs um item na cópia dela da lista, e a nossa não mudou."},
 {"code": "const bytes = new Uint8Array(64 * 2 ** 20);\nlet t = performance.now();\nworker.postMessage({ list: [], bytes });\nawait new Promise((r) => worker.once(\"message\", r));\nconsole.log(`64 MB copied in ${Math.round(performance.now() - t)} ms; ours is ${bytes.byteLength} bytes`);", "note": "Sessenta e quatro megabytes, copiados do mesmo jeito."},
 {"code": "t = performance.now();\nworker.postMessage({ list: [], bytes }, [bytes.buffer]);\nawait new Promise((r) => worker.once(\"message\", r));\nconsole.log(`64 MB transferred in ${Math.round(performance.now() - t)} ms; ours is ${bytes.byteLength} bytes`);\nawait worker.terminate();", "note": "**Transferido**: o segundo argumento lista os buffers a entregar em vez de copiar. Os bytes vão para a worker, e a nossa visão deles fica vazia."}
]}
```

```
ana@dev:~/server/procs$ node copy.js
the worker's copy has 3 items
ours still has 2
64 MB copied in 74 ms; ours is 67108864 bytes
64 MB transferred in 2 ms; ours is 0 bytes
```

**Uma cópia de 64 MB custou dezenas de milissegundos; uma transferência quase nada**, porque nenhum
byte se mexeu, só o direito de usá-los. O preço é que o remetente os perde, e um `byteLength` de 0 é o
que ele tem depois.

## Compartilhado, e Atomics

**Um `SharedArrayBuffer` é memória que as duas threads usam ao mesmo tempo**: mandá-lo manda acesso aos
mesmos bytes, não uma cópia. É o jeito mais rápido de threads cooperarem, e o único jeito de ter os
bugs pelos quais as threads são conhecidas, que este programa tem de propósito:

```schooling-example
{"language": "javascript", "file": "counter.js", "parts": [
 {"code": "// counter.js: four threads adding to one shared number, with and without Atomics.\nimport { Worker } from \"node:worker_threads\";"},
 {"code": "const code = `\n  const { workerData } = require(\"node:worker_threads\");\n  const n = new Int32Array(workerData.shared);\n  for (let i = 0; i < 1_000_000; i++) {\n    if (workerData.atomic) Atomics.add(n, 0, 1);\n    else n[0]++;\n  }`;", "note": "**Cada worker soma um, um milhão de vezes, no mesmo número.** O `n[0]++` lê o número, soma um e grava de volta, em três passos entre os quais outra thread pode entrar."},
 {"code": "for (const atomic of [false, true]) {\n  const shared = new SharedArrayBuffer(4);\n  const workers = Array.from({ length: 4 }, () => new Worker(code, { eval: true, workerData: { shared, atomic } }));\n  await Promise.all(workers.map((w) => new Promise((r) => w.once(\"exit\", r))));\n  console.log(`${atomic ? \"Atomics.add\" : \"n[0]++     \"}: ${new Int32Array(shared)[0]} of 4000000`);\n}", "note": "**Quatro bytes, compartilhados por quatro workers**, uma vez com incrementos simples e outra com `Atomics.add`, que faz os três passos como um só."}
]}
```

```
ana@dev:~/server/procs$ node counter.js
n[0]++     : 3242706 of 4000000
Atomics.add: 4000000 of 4000000
```

**O `n[0]++` perdeu incrementos, e um número diferente deles a cada execução**: duas threads leem o
mesmo valor, as duas somam um, as duas gravam de volta, e uma das duas somas some. O `Atomics.add` não
pode ser interrompido no meio, então contou cada uma. Uma atualização perdida assim não derruba nada e
não se repete do mesmo jeito duas vezes, e é isso que a torna cara de achar.

**A resposta de costume é não compartilhar.** Mande à worker a entrada dela, deixe-a responder com uma
mensagem, e guarde o `SharedArrayBuffer` para o caso raro em que copiar se mostrou lento demais numa
medição.
