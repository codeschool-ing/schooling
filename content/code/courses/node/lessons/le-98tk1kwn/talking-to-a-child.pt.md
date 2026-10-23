---
title: fork, e um filho que responde
version: 1
---

**A aula 2 bloqueou o event loop com uma soma longa, e todo pedido esperou atrás dela.** Uma saída é
rodar a soma em outro lugar: em outro processo, com o próprio event loop, em outro processador. O
`fork` inicia outro programa Node com um canal entre os dois, para que cada um possa mandar mensagens
ao outro.

Uma função que mantém um processador ocupado por alguns segundos, usada no resto desta aula:

```javascript
// primes.js: a slow count on purpose, to have something that keeps a CPU busy.
export function countPrimes(from, to) {
  let count = 0;
  for (let n = Math.max(from, 2); n < to; n++) {
    let prime = true;
    for (let d = 2; d * d <= n; d++) {
      if (n % d === 0) {
        prime = false;
        break;
      }
    }
    if (prime) count++;
  }
  return count;
}
```

```schooling-example
{"language": "javascript", "file": "child.js", "parts": [
 {"code": "// child.js: started with fork, it waits for work and sends back the answer.\nimport { countPrimes } from \"./primes.js\";", "note": "Um módulo comum. Nada nele diz que é um filho, a não ser o uso do `process.send`."},
 {"code": "process.on(\"message\", ({ from, to }) => {\n  const started = Date.now();\n  const count = countPrimes(from, to);\n  process.send({ count, ms: Date.now() - started, pid: process.pid });\n});", "note": "**O `message` traz o que o pai mandou, e o `process.send` responde.** Os dois só existem num processo iniciado com `fork`; o canal mantém o filho vivo até o pai o fechar ou o matar."}
]}
```

```schooling-example
{"language": "javascript", "file": "parent.js", "parts": [
 {"code": "// parent.js: hands the counting to a child process and stays free meanwhile.\nimport { fork } from \"node:child_process\";\n\nconst child = fork(\"./child.js\");\nconst ticks = setInterval(() => console.log(\"parent: still answering\"), 500);", "note": "**O `fork` inicia um segundo `node`** rodando o `child.js`. O intervalo faz o papel dos pedidos que um servidor estaria respondendo enquanto espera."},
 {"code": "child.send({ from: 0, to: 10_000_000 });\nchild.once(\"message\", (answer) => {\n  console.log(`child ${answer.pid}: ${answer.count} primes in ${answer.ms} ms`);\n  clearInterval(ticks);\n  child.kill();\n});", "note": "**A mensagem é copiada como JSON**, não compartilhada: um objeto mandado é um objeto novo do outro lado. O `kill()` manda `SIGTERM` ao filho."},
 {"code": "child.on(\"exit\", (code, signal) => console.log(`child exited: code ${code}, signal ${signal}`));", "note": "**O `exit` diz como o filho terminou**: um código de saída se terminou sozinho, um sinal se foi parado. Um dos dois é sempre `null`."}
]}
```

```
ana@dev:~/server/procs$ node parent.js
parent: still answering
parent: still answering
parent: still answering
parent: still answering
parent: still answering
child 14779: 664579 primes in 2782 ms
child exited: code null, signal SIGTERM
```

**O pai continuou marcando o tempo durante toda a contagem**, porque a soma rodou num processo próprio,
em outro processador. E o `exit` informou um sinal e nenhum código, porque o filho foi morto em vez de
terminar.

Um processo é o jeito mais pesado de fazer isso. Cada filho é um Node inteiro, com o próprio runtime na
memória, uns 40 MB antes de fazer qualquer coisa, e leva algumas dezenas de milissegundos para
iniciar. É um preço justo para um programa que roda por muito tempo, ou que pode cair e não pode levar
o pai junto. Para um cálculo, o Node tem algo mais leve, na próxima seção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Dois jeitos de rodar JavaScript em mais de um processador. À esquerda, dois processos iniciados com fork: cada um tem o seu Node, a sua memória e o seu event loop, ligados por um canal que leva mensagens. À direita, um processo com uma thread principal e duas worker threads: cada thread tem o seu heap e o seu loop, dentro de um Node só, e um SharedArrayBuffer pode ser visto por todas.\"><text x=\"175\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fork: dois processos</text><rect x=\"25\" y=\"40\" width=\"145\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">parent.js</text><text x=\"97\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o seu próprio Node</text><rect x=\"40\" y=\"95\" width=\"115\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">heap</text><rect x=\"40\" y=\"140\" width=\"115\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">event loop</text><rect x=\"205\" y=\"40\" width=\"145\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"277\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">child.js</text><text x=\"277\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o seu próprio Node</text><rect x=\"220\" y=\"95\" width=\"115\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"277\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">heap</text><rect x=\"220\" y=\"140\" width=\"115\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"277\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">event loop</text><line x1=\"172\" y1=\"210\" x2=\"203\" y2=\"210\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"203.0,210.0 195.6,213.1 195.6,206.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"205\" y1=\"220\" x2=\"172\" y2=\"220\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"172.0,220.0 179.4,216.9 179.4,223.1\" fill=\"var(--phosphor)\"></polygon><text x=\"188\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">mensagens, copiadas</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">worker_threads: um processo</text><rect x=\"390\" y=\"40\" width=\"310\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um Node só</text><rect x=\"402\" y=\"70\" width=\"88\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"446\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">principal</text><text x=\"446\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o seu heap</text><text x=\"446\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o seu loop</text><rect x=\"502\" y=\"70\" width=\"88\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"546\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker 1</text><text x=\"546\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o seu heap</text><text x=\"546\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o seu loop</text><rect x=\"602\" y=\"70\" width=\"88\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"646\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker 2</text><text x=\"646\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o seu heap</text><text x=\"646\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o seu loop</text><rect x=\"402\" y=\"158\" width=\"288\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"546\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SharedArrayBuffer</text></svg>", "caption": "Um processo filho não divide nada; uma worker thread divide o processo, e só a memória que recebe.", "same": ["event loop", "heap", "worker 1", "worker 2"]}
```
