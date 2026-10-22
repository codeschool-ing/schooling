---
title: One server, five more ways
version: 1
---

**This course chose one language and went deep in it, and the first lesson made a promise about the
last one**: that HTTP, status codes, configuration from the environment, a clean shutdown and the rest
exist in every server language, and that having built them once you would read them elsewhere as the
same ideas with new names. This lesson keeps it. It writes one small server in Node and then in five
other languages that run a large share of the world's servers, runs each one, and asks the same three
questions of all of them.

The server is deliberately small, so that what differs is the language and not the program:

| request | answer |
|---|---|
| `GET /hello?name=ana` | `200`, `{"hello":"ana"}`; without a name, `world` |
| `GET /slow` | `200` after one second, as if it waited on a database |
| anything else | `404`, `{"error":"nothing at /…"}` |

It listens on the port in `PORT`, or 3000, as lesson 9 taught.

The Node version, with nothing but `node:http`, in `~/server/other/node`; each language gets a folder
beside it:

```javascript
// hello.mjs: the server every section of this lesson writes again.
import http from "node:http";

const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://localhost");
  const send = (status, body) => {
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify(body));
  };
  if (req.method === "GET" && url.pathname === "/hello") {
    return send(200, { hello: url.searchParams.get("name") ?? "world" });
  }
  if (req.method === "GET" && url.pathname === "/slow") {
    return setTimeout(() => send(200, { slept: 1000 }), 1000);
  }
  send(404, { error: `nothing at ${url.pathname}` });
});
const port = Number(process.env.PORT ?? 3000);
server.listen(port, "127.0.0.1", () => console.log(`node on :${port}`));
```

```
ana@dev:~/server/other/node$ node hello.mjs
node on :3000
^C
```

And the three questions, asked from a second terminal: does it answer, does it say 404 properly, and
**how long do ten slow requests take when they arrive together?**

```
ana@dev:~/server/other/node$ curl -s 'http://127.0.0.1:3000/hello?name=ana'
{"hello":"ana"}
ana@dev:~/server/other/node$ curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope
{"error":"nothing at /nope"} 404
ana@dev:~/server/other/node$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m1.016s
user	0m0.030s
sys	0m0.025s
```

**Ten requests that each wait one second took one second in all**, because Node waits on all of them
at once: lesson 2's event loop. The last question is the one where the languages differ most, and the
section on concurrency models comes back to it.

## You do not have to install them

Every section shows its run, so the lesson can be read without installing anything. If you want to try
one, each section gives the commands for Ubuntu, which is also what WSL runs on Windows, and for a
Mac with Homebrew. **The `apt` commands were run on the course's machine and the Homebrew ones were
not**; they are the standard formula names, and the section on Go says how its Go was installed. Each
language takes a few hundred megabytes, and `sudo apt remove` with the same package name takes it
away again.
