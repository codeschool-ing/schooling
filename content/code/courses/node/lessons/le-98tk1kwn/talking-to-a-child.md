---
title: fork, and a child that answers
version: 1
---

**Lesson 2 blocked the event loop with a long sum, and every request waited behind it.** One way out
is to run the sum somewhere else: in another process, with its own event loop, on another processor.
`fork` starts another Node program with a channel between the two, so each can send the other
messages.

A function that keeps a processor busy for a few seconds, used for the rest of this lesson:

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
 {"code": "// child.js: started with fork, it waits for work and sends back the answer.\nimport { countPrimes } from \"./primes.js\";", "note": "An ordinary module. Nothing in it says it is a child except that it uses `process.send`."},
 {"code": "process.on(\"message\", ({ from, to }) => {\n  const started = Date.now();\n  const count = countPrimes(from, to);\n  process.send({ count, ms: Date.now() - started, pid: process.pid });\n});", "note": "**`message` brings what the parent sent, and `process.send` answers.** Both exist only in a process started with `fork`; the channel keeps the child alive until the parent closes it or kills it."}
]}
```

```schooling-example
{"language": "javascript", "file": "parent.js", "parts": [
 {"code": "// parent.js: hands the counting to a child process and stays free meanwhile.\nimport { fork } from \"node:child_process\";\n\nconst child = fork(\"./child.js\");\nconst ticks = setInterval(() => console.log(\"parent: still answering\"), 500);", "note": "**`fork` starts a second `node`** running `child.js`. The interval stands for the requests a server would be answering while it waits."},
 {"code": "child.send({ from: 0, to: 10_000_000 });\nchild.once(\"message\", (answer) => {\n  console.log(`child ${answer.pid}: ${answer.count} primes in ${answer.ms} ms`);\n  clearInterval(ticks);\n  child.kill();\n});", "note": "**The message is copied across as JSON**, not shared: an object sent is a new object on the other side. `kill()` sends the child `SIGTERM`."},
 {"code": "child.on(\"exit\", (code, signal) => console.log(`child exited: code ${code}, signal ${signal}`));", "note": "**`exit` says how the child ended**: an exit code if it ended itself, a signal if it was stopped. One of the two is always `null`."}
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

**The parent kept ticking for the whole count**, because the sum ran in a process of its own, on
another processor. And `exit` reported a signal and no code, because the child was killed rather than
finishing.

A process is the heaviest way to do it. Each child is a whole Node, with its own runtime in memory,
about 40 MB before it does anything, and takes a few tens of milliseconds to start. That is a fair
price for a program that runs a long time, or that might crash and must not take the parent with it.
For a calculation, Node has something lighter, in the next section.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Two ways to run JavaScript on more than one processor. On the left, two processes started with fork: each has its own Node, its own memory and its own event loop, joined by a channel that carries messages. On the right, one process with a main thread and two worker threads: each thread has its own heap and loop, inside one Node, and a SharedArrayBuffer can be seen by all of them.\"><text x=\"175\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fork: two processes</text><rect x=\"25\" y=\"40\" width=\"145\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">parent.js</text><text x=\"97\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own Node</text><rect x=\"40\" y=\"95\" width=\"115\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">heap</text><rect x=\"40\" y=\"140\" width=\"115\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">event loop</text><rect x=\"205\" y=\"40\" width=\"145\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"277\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">child.js</text><text x=\"277\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own Node</text><rect x=\"220\" y=\"95\" width=\"115\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"277\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">heap</text><rect x=\"220\" y=\"140\" width=\"115\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"277\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">event loop</text><line x1=\"172\" y1=\"210\" x2=\"203\" y2=\"210\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"203.0,210.0 195.6,213.1 195.6,206.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"205\" y1=\"220\" x2=\"172\" y2=\"220\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"172.0,220.0 179.4,216.9 179.4,223.1\" fill=\"var(--phosphor)\"></polygon><text x=\"188\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">messages, copied</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">worker_threads: one process</text><rect x=\"390\" y=\"40\" width=\"310\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one Node</text><rect x=\"402\" y=\"70\" width=\"88\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"446\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">main</text><text x=\"446\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its heap</text><text x=\"446\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its loop</text><rect x=\"502\" y=\"70\" width=\"88\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"546\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker 1</text><text x=\"546\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its heap</text><text x=\"546\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its loop</text><rect x=\"602\" y=\"70\" width=\"88\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"646\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker 2</text><text x=\"646\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its heap</text><text x=\"646\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its loop</text><rect x=\"402\" y=\"158\" width=\"288\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"546\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SharedArrayBuffer</text></svg>", "caption": "A child process shares nothing; a worker thread shares the process, and only the memory it is given."}
```
