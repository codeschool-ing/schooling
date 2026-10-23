---
title: cluster
version: 1
---

**Um pool espalha o cálculo pelos processadores; o `cluster` espalha o servidor inteiro.** Ele inicia
um processo **primário** e vários processos **workers**, cada um uma cópia inteira do programa, e todos
escutam na mesma porta. O primário segura a porta e entrega cada conexão nova a uma worker, em rodízio
no Linux; cada worker roda o próprio event loop no próprio processador.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O módulo cluster. As conexões chegam na porta 3000, que o processo primário segura. O primário entrega cada conexão nova à próxima de quatro workers, em rodízio; cada worker é uma cópia inteira do programa, com a sua memória e o seu event loop. Quando uma worker morre o primário inicia outra.\"><text x=\"70\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conexões</text><line x1=\"20\" y1=\"100\" x2=\"128\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"20\" y1=\"114\" x2=\"128\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"20\" y1=\"128\" x2=\"128\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"128\" y1=\"112\" x2=\"168\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"168.0,112.0 160.6,115.1 160.6,108.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"170\" y=\"72\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">primário</text><text x=\"250\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:3000</text><text x=\"250\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não atende nada</text><line x1=\"330\" y1=\"112\" x2=\"438\" y2=\"34\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,34.0 433.9,40.8 430.2,35.8\" fill=\"var(--phosphor)\"></polygon><rect x=\"440\" y=\"14\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 1</text><text x=\"540\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a sua memória e o seu loop</text><line x1=\"330\" y1=\"112\" x2=\"438\" y2=\"86\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,86.0 431.6,90.8 430.1,84.7\" fill=\"var(--phosphor)\"></polygon><rect x=\"440\" y=\"66\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 2</text><text x=\"540\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a sua memória e o seu loop</text><line x1=\"330\" y1=\"112\" x2=\"438\" y2=\"138\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,138.0 430.1,139.3 431.6,133.2\" fill=\"var(--phosphor)\"></polygon><rect x=\"440\" y=\"118\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 3</text><text x=\"540\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a sua memória e o seu loop</text><line x1=\"330\" y1=\"112\" x2=\"438\" y2=\"190\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,190.0 430.2,188.2 433.9,183.2\" fill=\"var(--phosphor)\"></polygon><rect x=\"440\" y=\"170\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 4</text><text x=\"540\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a sua memória e o seu loop</text><text x=\"250\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">em rodízio, no Linux</text><text x=\"250\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">uma worker morre: fork de outra</text></svg>", "caption": "Uma porta, um primário, uma cópia do servidor inteiro por processador.", "same": ["worker 1", "worker 2", "worker 3", "worker 4"]}
```

```schooling-example
{"language": "javascript", "file": "hello-cluster.js", "parts": [
 {"code": "// hello-cluster.js: one primary, one worker per CPU, all answering on port 3000.\nimport cluster from \"node:cluster\";\nimport http from \"node:http\";\nimport { availableParallelism } from \"node:os\";"},
 {"code": "if (cluster.isPrimary) {\n  console.log(`primary ${process.pid}: starting ${availableParallelism()} workers`);\n  for (let i = 0; i < availableParallelism(); i++) cluster.fork();", "note": "**O mesmo arquivo roda em todo processo**, e o `cluster.isPrimary` diz de que tipo é este. O primário inicia as workers e não atende nada ele mesmo."},
 {"code": "  cluster.on(\"exit\", (worker, code, signal) => {\n    console.log(`worker ${worker.process.pid} died (${signal ?? code}); starting another`);\n    cluster.fork();\n  });", "note": "**Uma worker que morre é substituída.** Uma queda derruba um quarto da capacidade por um instante, em vez do serviço inteiro."},
 {"code": "} else {\n  http.createServer((req, res) => res.end(`answered by ${process.pid}`)).listen(3000, \"127.0.0.1\");\n}", "note": "**Cada worker chama `listen(3000)`**, e nenhuma ganha `EADDRINUSE`: numa worker, o `listen` pede ao primário a porta que ele já segura."}
]}
```

```
ana@dev:~/server/procs$ node hello-cluster.js
primary 15028: starting 4 workers
worker 15041 died (SIGKILL); starting another
^C
```

De um segundo terminal, seis pedidos, e depois uma worker morta de vez, com um pid de quem respondeu:

```
ana@dev:~/server/procs$ for i in 1 2 3 4 5 6; do curl -s http://127.0.0.1:3000/; done
answered by 15039
answered by 15040
answered by 15038
answered by 15041
answered by 15039
answered by 15040
ana@dev:~/server/procs$ kill -KILL 15041
ana@dev:~/server/procs$ sleep 0.5; ps -o pid,args -C node
  PID COMMAND
15028 node hello-cluster.js
15038 /home/ana/.local/node/bin/node /home/ana/server/procs/hello-cluster.js
15039 /home/ana/.local/node/bin/node /home/ana/server/procs/hello-cluster.js
15040 /home/ana/.local/node/bin/node /home/ana/server/procs/hello-cluster.js
15109 /home/ana/.local/node/bin/node /home/ana/server/procs/hello-cluster.js
```

**Cada pedido foi respondido pela próxima worker da vez, e uma worker morta foi substituída** dentro do
meio segundo antes de o `ps` olhar. A segunda propriedade importa tanto quanto a primeira: uma queda
numa worker é uma queda numa worker.

## É mais rápido?

Só para trabalho que mantém um processador ocupado. Um lançador pequeno roda qualquer arquivo de
servidor num cluster, com o número de workers numa variável, para que o mesmo `busy.js` da última seção
seja medido com uma worker e com quatro:

```schooling-example
{"language": "javascript", "file": "cluster.js", "parts": [
 {"code": "// cluster.js: `node cluster.js FILE` runs FILE in several workers behind one port.\nimport cluster from \"node:cluster\";\nimport { availableParallelism } from \"node:os\";\nimport path from \"node:path\";\n\nconst file = path.resolve(process.argv[2]);", "note": "O arquivo a rodar é o primeiro argumento, resolvido a partir da pasta onde o comando foi digitado."},
 {"code": "if (cluster.isPrimary) {\n  const count = Number(process.env.WORKERS ?? availableParallelism());\n  console.log(`primary ${process.pid}: ${count} workers of ${path.basename(file)}`);\n  for (let i = 0; i < count; i++) cluster.fork();\n} else {\n  await import(file);\n}", "note": "**Uma worker só importa o arquivo**, o que inicia o servidor dele como se estivesse sozinho. As workers recebem os mesmos argumentos e o mesmo ambiente que o primário."}
]}
```

Oito pedidos lentos ao mesmo tempo, com `WORKERS=1 node cluster.js busy.js` no outro terminal e depois
`WORKERS=4 node cluster.js busy.js`:

```
ana@dev:~/server/procs$ time (for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/primes & done; wait)
200 200 200 200 200 200 200 200 
real	0m8.439s
user	0m0.030s
sys	0m0.021s
```

```
ana@dev:~/server/procs$ time (for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/primes & done; wait)
200 200 200 200 200 200 200 200 
real	0m2.158s
user	0m0.019s
sys	0m0.027s
```

**Quatro workers fizeram as oito contagens num quarto do tempo**, duas cada, ao mesmo tempo. Um
servidor que passa a maior parte do tempo esperando arquivos, um banco ou outros serviços ganha bem
menos: um processo Node já mantém milhares de pedidos em espera em andamento, e a aula 2 mostrou por
quê. Meça antes de decidir que um serviço precisa disso.
