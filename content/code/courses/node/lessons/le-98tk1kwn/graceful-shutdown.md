---
title: Stopping without dropping a request
version: 1
---

**A server is stopped many times in its life**, at every deploy, every restart and every machine that
is replaced, and each stop arrives as `SIGTERM`. Node's default is to exit on it at once, which drops
every request still being answered: a visitor gets a broken connection, and a write that was halfway
is never finished. **A graceful shutdown** does it in order instead:

1. stop accepting new connections;
2. let the requests already open finish;
3. exit when nothing is left, or after a deadline if something hangs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A timeline of a graceful shutdown. SIGTERM arrives; the server stops accepting connections at once; a request that was already open keeps running until it answers; when nothing is left the process exits with 0. A deadline ten seconds after the signal would force the exit if a request never ended.\"><line x1=\"40\" y1=\"150\" x2=\"690\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,150.0 682.6,153.1 682.6,146.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"690\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><line x1=\"200\" y1=\"40\" x2=\"200\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"200\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">SIGTERM</text><rect x=\"40\" y=\"60\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">accepting connections</text><rect x=\"200\" y=\"60\" width=\"210\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"305\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">closed to new ones: curl gets 7</text><rect x=\"120\" y=\"105\" width=\"290\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"265\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">/slow, open before the signal, finishes</text><line x1=\"410\" y1=\"40\" x2=\"410\" y2=\"160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"410\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">loop empty: exit 0</text><line x1=\"620\" y1=\"40\" x2=\"620\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"2 4\"></line><text x=\"620\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10 s: exit 1 anyway</text><text x=\"620\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only if something hangs</text></svg>", "caption": "Stop taking work, finish the work already taken, and let the loop end on its own."}
```

A small server with one slow route shows the three steps:

```schooling-example
{"language": "javascript", "file": "graceful.js", "parts": [
 {"code": "// graceful.js: a server that finishes what it started before it exits.\nimport http from \"node:http\";\n\nconst server = http.createServer((req, res) => {\n  const ms = req.url === \"/slow\" ? 3000 : 0;\n  setTimeout(() => res.end(`done ${req.url} after ${ms} ms`), ms);\n});\nserver.listen(3000, \"127.0.0.1\", () => console.log(`pid ${process.pid} on :3000`));", "note": "`/slow` takes three seconds to answer, which is long enough to send a signal in the middle of it."},
 {"code": "function shutdown(signal) {\n  console.log(`${signal}: no new connections; finishing the ones open`);\n  server.close(() => console.log(\"every connection closed; the loop is empty, so node exits\"));", "note": "**`server.close()` stops listening at once** and calls back when the last open connection has ended. Idle keep-alive connections are closed for it; busy ones are left to finish."},
 {"code": "  setTimeout(() => {\n    console.error(\"still busy after 10 s; exiting anyway\");\n    process.exit(1);\n  }, 10_000).unref();\n}", "note": "**The deadline.** A request that never ends must not keep the process alive for ever. `unref()` means this timer does not itself keep the loop running, so when everything else is done Node exits without waiting for it."},
 {"code": "process.once(\"SIGTERM\", shutdown);\nprocess.once(\"SIGINT\", shutdown);", "note": "The same for Ctrl-C. `once`, so a second Ctrl-C gets Node's default and stops at once, which is what a person pressing it twice means."}
]}
```

**Nothing calls `process.exit()` on the good path.** Once the server is closed and the slow request
has answered, nothing is left for the event loop, and Node ends the way any finished program does,
with every pending write flushed. In one terminal:

```
ana@dev:~/server/procs$ node graceful.js; echo "exit code $?"
pid 14583 on :3000
SIGTERM: no new connections; finishing the ones open
every connection closed; the loop is empty, so node exits
exit code 0
```

And in a second, a slow request with `SIGTERM` sent half a second into it, then a new request:

```
ana@dev:~/server/procs$ curl -s http://127.0.0.1:3000/slow & sleep 0.5; kill -TERM 14583
ana@dev:~/server/procs$ curl -s http://127.0.0.1:3000/fast; echo "curl exit code $?"

curl exit code 7
ana@dev:~/server/procs$ wait
done /slow after 3000 ms
```

**The slow request was answered in full, after the signal**, and the new one found nobody listening:
curl's exit code 7 means it could not connect. Then the server exited with 0, on its own.

## The links service

`server.js` gets the same shape. The store from lesson 8 needs nothing extra: a save that is underway
is a pending write, and the loop does not end while one is pending, so letting Node exit by itself is
also what keeps the file whole.

```javascript
// server.js
import { config, summary } from "./src/config.js";
import { createApp } from "./src/app.js";

const server = createApp().listen(config.port, config.host, () => {
  console.log(`links on http://${config.host}:${config.port}`, summary());
});

function shutdown(signal) {
  console.log(`${signal}: closing; requests already open are finished first`);
  server.close(() => console.log("closed"));
  setTimeout(() => process.exit(1), 10_000).unref();
}
process.once("SIGTERM", shutdown);
process.once("SIGINT", shutdown);
```

```
ana@dev:~/server/links$ npm start

> links@0.1.0 start
> node --env-file-if-exists=.env server.js

links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/data/links.json',
  adminKey: '(set, 32 characters)'
}
SIGINT: closing; requests already open are finished first
closed
^C
```

Ctrl-C now says what it is doing instead of vanishing. The ten seconds are a choice rather than a
rule. A service manager waits a while after `SIGTERM` before it sends `SIGKILL`, systemd 90 seconds by
default and Docker ten, and the program's own deadline has to end first, or it is the `SIGKILL` that
ends the shutdown. Under Docker that means a shorter deadline here or a longer wait there.
