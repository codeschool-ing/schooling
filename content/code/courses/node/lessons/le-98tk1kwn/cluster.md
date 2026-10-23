---
title: cluster
version: 1
---

**A pool spreads computation over the processors; `cluster` spreads the whole server.** It starts one
**primary** process and several **worker** processes, each a full copy of the program, and all of them
listen on the same port. The primary holds the port and hands each new connection to a worker, in
turn on Linux; each worker runs its own event loop on its own processor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The cluster module. Connections arrive at port 3000, which the primary process holds. The primary hands each new connection to the next of four worker processes in turn; each worker is a full copy of the program with its own memory and event loop. When a worker dies the primary starts another.\"><text x=\"70\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">connections</text><line x1=\"20\" y1=\"100\" x2=\"128\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"20\" y1=\"114\" x2=\"128\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"20\" y1=\"128\" x2=\"128\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"128\" y1=\"112\" x2=\"168\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"168.0,112.0 160.6,115.1 160.6,108.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"170\" y=\"72\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">primary</text><text x=\"250\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:3000</text><text x=\"250\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">serves nothing itself</text><line x1=\"330\" y1=\"112\" x2=\"438\" y2=\"34\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,34.0 433.9,40.8 430.2,35.8\" fill=\"var(--phosphor)\"></polygon><rect x=\"440\" y=\"14\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 1</text><text x=\"540\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its own memory and loop</text><line x1=\"330\" y1=\"112\" x2=\"438\" y2=\"86\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,86.0 431.6,90.8 430.1,84.7\" fill=\"var(--phosphor)\"></polygon><rect x=\"440\" y=\"66\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 2</text><text x=\"540\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its own memory and loop</text><line x1=\"330\" y1=\"112\" x2=\"438\" y2=\"138\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,138.0 430.1,139.3 431.6,133.2\" fill=\"var(--phosphor)\"></polygon><rect x=\"440\" y=\"118\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 3</text><text x=\"540\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its own memory and loop</text><line x1=\"330\" y1=\"112\" x2=\"438\" y2=\"190\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,190.0 430.2,188.2 433.9,183.2\" fill=\"var(--phosphor)\"></polygon><rect x=\"440\" y=\"170\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 4</text><text x=\"540\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its own memory and loop</text><text x=\"250\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">in turn, on Linux</text><text x=\"250\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a worker dies: fork another</text></svg>", "caption": "One port, one primary, a copy of the whole server per processor."}
```

```schooling-example
{"language": "javascript", "file": "hello-cluster.js", "parts": [
 {"code": "// hello-cluster.js: one primary, one worker per CPU, all answering on port 3000.\nimport cluster from \"node:cluster\";\nimport http from \"node:http\";\nimport { availableParallelism } from \"node:os\";"},
 {"code": "if (cluster.isPrimary) {\n  console.log(`primary ${process.pid}: starting ${availableParallelism()} workers`);\n  for (let i = 0; i < availableParallelism(); i++) cluster.fork();", "note": "**The same file runs in every process**, and `cluster.isPrimary` says which kind this one is. The primary starts the workers and serves nothing itself."},
 {"code": "  cluster.on(\"exit\", (worker, code, signal) => {\n    console.log(`worker ${worker.process.pid} died (${signal ?? code}); starting another`);\n    cluster.fork();\n  });", "note": "**A worker that dies is replaced.** One crash takes down a quarter of the capacity for a moment instead of the whole service."},
 {"code": "} else {\n  http.createServer((req, res) => res.end(`answered by ${process.pid}`)).listen(3000, \"127.0.0.1\");\n}", "note": "**Each worker calls `listen(3000)`**, and none of them gets `EADDRINUSE`: in a worker, `listen` asks the primary for the port it already holds."}
]}
```

```
ana@dev:~/server/procs$ node hello-cluster.js
primary 15028: starting 4 workers
worker 15041 died (SIGKILL); starting another
^C
```

From a second terminal, six requests, then one worker killed outright, with a pid it answered from:

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

**Each request was answered by the next worker in turn, and a killed worker was replaced** within the
half second before `ps` looked. That second property matters as much as the first: a crash in one
worker is a crash in one worker.

## Is it faster?

Only for work that keeps a processor busy. A small launcher runs any server file in a cluster, with
the number of workers in a variable, so the same `busy.js` from the last section can be measured with
one worker and with four:

```schooling-example
{"language": "javascript", "file": "cluster.js", "parts": [
 {"code": "// cluster.js: `node cluster.js FILE` runs FILE in several workers behind one port.\nimport cluster from \"node:cluster\";\nimport { availableParallelism } from \"node:os\";\nimport path from \"node:path\";\n\nconst file = path.resolve(process.argv[2]);", "note": "The file to run is the first argument, resolved from the folder the command was typed in."},
 {"code": "if (cluster.isPrimary) {\n  const count = Number(process.env.WORKERS ?? availableParallelism());\n  console.log(`primary ${process.pid}: ${count} workers of ${path.basename(file)}`);\n  for (let i = 0; i < count; i++) cluster.fork();\n} else {\n  await import(file);\n}", "note": "**A worker simply imports the file**, which starts its server as it would alone. Workers get the same arguments and environment as the primary."}
]}
```

Eight slow requests at once, with `WORKERS=1 node cluster.js busy.js` in the other terminal and then
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

**Four workers did the eight counts in a quarter of the time**, two each, at once. A server that mostly
waits on files, a database or other services gains much less: one Node process already keeps
thousands of waiting requests in flight, and lesson 2 showed why. Measure before deciding a service
needs this.
