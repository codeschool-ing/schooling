---
title: A bad network you can start and stop
version: 1
---

**To test on a poor connection, you need one that is poor on demand, in the same way every time.**
Real bad networks are neither: the tunnel is not there when the test runs, and when it is, it is
bad differently on each pass. So you build one. A **proxy** is a program that sits between a client
and a server, receives the client's request, sends it on, and passes the answer back. A proxy that
holds answers, sends them slowly or throws some away is a bad network you can start with one
command, in front of boxoffice, of the payment stub, or of anything else that speaks HTTP.

## The proxy

About eighty lines of Node with no dependencies, like boxoffice. It forwards every request
untouched and spoils only the answer, which is a choice worth understanding before using it: **the
request always arrives**, so whatever the server does, it has done. What the client loses is the
news. That is the half of a failure a client cannot tell apart from a request that never left, and
so the half it must plan for. Save it as `slow-proxy.mjs`:

```js
// slow-proxy.mjs: a bad network between a client and a server, on purpose.
// Start it with `node slow-proxy.mjs`. It listens on port 8070 (PORT changes
// that), forwards every request to TARGET (http://localhost:8080 unless set)
// and spoils the answer on its way back:
//   DELAY  milliseconds each answer is held before it is sent (default 0)
//   RATE   bytes per second the body of an answer is sent at; 0 is no limit
//   DROP   the share of answers thrown away, from 0 to 1: the connection is
//          cut and the client receives nothing at all (default 0)
//   SEED   where the drops start, so a run can be repeated exactly (default 1)
// The request always reaches the server. What is lost is the answer, which is
// the half a client cannot tell apart from a request that never arrived.
import http from 'node:http';

const PORT = Number(process.env.PORT || 8070);
const TARGET = process.env.TARGET || 'http://localhost:8080';
const DELAY = Number(process.env.DELAY || 0);
const RATE = Number(process.env.RATE || 0);
const DROP = Number(process.env.DROP || 0);
let seed = Number(process.env.SEED || 1);

// A small random number generator (mulberry32) that the same SEED repeats.
function random() {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

const wait = (ms) => new Promise((done) => setTimeout(done, ms));

// Ask the real server, and collect its whole answer.
function forward(req, body) {
  return new Promise((resolve, reject) => {
    const out = http.request(new URL(req.url, TARGET), { method: req.method, headers: req.headers }, (res) => {
      const parts = [];
      res.on('data', (part) => parts.push(part));
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: Buffer.concat(parts) }));
    });
    out.on('error', reject);
    out.end(body);
  });
}

// Send the body RATE bytes a second, a tenth of a second at a time.
async function trickle(res, body) {
  const step = Math.max(1, Math.round(RATE / 10));
  for (let i = 0; i < body.length && !res.destroyed; i += step) {
    res.write(body.subarray(i, i + step));
    await wait(100);
  }
  res.end();
}

let count = 0;
http.createServer(async (req, res) => {
  const n = ++count;
  const parts = [];
  for await (const part of req) parts.push(part);
  const lose = random() < DROP;
  let answer;
  try {
    answer = await forward(req, Buffer.concat(parts));
  } catch (err) {
    console.log(`${n} ${req.method} ${req.url}: the server did not answer (${err.code})`);
    return req.socket.destroy();
  }
  await wait(DELAY);
  if (res.destroyed) {
    console.log(`${n} ${req.method} ${req.url} ${answer.status}, but the client had hung up`);
    return;
  }
  if (lose) {
    console.log(`${n} ${req.method} ${req.url} ${answer.status}, answer dropped`);
    return req.socket.destroy();
  }
  console.log(`${n} ${req.method} ${req.url} ${answer.status}, answer sent`);
  const headers = { ...answer.headers, 'content-length': answer.body.length };
  delete headers['transfer-encoding'];
  res.writeHead(answer.status, headers);
  if (RATE > 0) await trickle(res, answer.body);
  else res.end(answer.body);
}).listen(PORT, () => {
  console.log(`slow proxy listening on http://localhost:${PORT}, forwarding to ${TARGET}`);
  console.log(`  DELAY ${DELAY} ms, RATE ${RATE || 'unlimited'} B/s, DROP ${DROP}, SEED ${seed}`);
});
```

```schooling-example
{
 "language": "js",
 "file": "slow-proxy.mjs",
 "parts": [
  {
   "code": "let seed = Number(process.env.SEED || 1);\n\n// A small random number generator (mulberry32) that the same SEED repeats.\nfunction random() {",
   "note": "`Math.random()` cannot be given a seed, so a run that dropped the third answer would drop the fifth next time. This generator gives the same sequence for the same `SEED`, which makes a failure you saw once a failure you can show somebody."
  },
  {
   "code": "  const lose = random() < DROP;\n  let answer;\n  try {\n    answer = await forward(req, Buffer.concat(parts));",
   "note": "Whether this answer will be lost is decided first, in the order requests arrive; then the request goes to the server whatever was decided."
  },
  {
   "code": "  await wait(DELAY);\n  if (res.destroyed) {",
   "note": "The answer is held. If the client gave up while it waited, the proxy says so in its log, which is how a timeout on the client's side shows up on this one."
  },
  {
   "code": "  if (lose) {\n    console.log(`${n} ${req.method} ${req.url} ${answer.status}, answer dropped`);\n    return req.socket.destroy();\n  }",
   "note": "A lost answer: the connection is cut with nothing sent. The server's status is in the log, so you can see what the client never learnt."
  },
  {
   "code": "  if (RATE > 0) await trickle(res, answer.body);\n  else res.end(answer.body);",
   "note": "With `RATE`, the body goes out a tenth of a second's worth at a time, as on a thin link; the headers go at once."
  }
 ]
}
```

It needs boxoffice running on 8080, as always. Start the proxy in a terminal of its own, in
`~/boxoffice`; with nothing set it changes nothing:

```
ana@laptop:~/boxoffice$ node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE unlimited B/s, DROP 0, SEED 1
```

## Latency

Every request through it travels one more hop. The same list of shows, from boxoffice itself and
through the proxy, with curl's `-w` printing the status and the total time in seconds:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8080/v1/shows
200 0.006800
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8070/v1/shows
200 0.023955
```

Both under three hundredths of a second: the extra hop costs next to nothing. Stop the proxy with
Ctrl-C and start it holding every answer for 800 ms:

```
ana@laptop:~/boxoffice$ DELAY=800 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 800 ms, RATE unlimited B/s, DROP 0, SEED 1
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8070/v1/shows
200 0.818174
```

0.818 seconds: the delay, plus the few milliseconds the trip itself takes. Every request pays it,
and a screen that needs three requests in a row pays it three times.

## Bandwidth

`RATE=200` sends answers at 200 bytes a second. curl can say when the first byte of the answer
arrived and when the last one did:

```
ana@laptop:~/boxoffice$ RATE=200 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE 200 B/s, DROP 0, SEED 1
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes, first byte %{time_starttransfer}, last %{time_total}\n' localhost:8070/v1/shows
200 379 bytes, first byte 0.020703, last 1.835973
```

The first byte arrives at once and the last after nearly two seconds, for 379 bytes. Two hundred
bytes a second is far slower than even the slowest profile of the emulator in section 05, chosen
so the effect is easy to see; at that rate a picture of 200 kilobytes would take about seventeen
minutes. **Bandwidth punishes size**, and a test of it belongs on the screens that load the most.

## Loss

`DROP=0.3` throws away about three answers in ten. curl prints `000` for a request that got no
status at all:

```
ana@laptop:~/boxoffice$ DROP=0.3 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE unlimited B/s, DROP 0.3, SEED 1
ana@laptop:~/boxoffice$ for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' localhost:8070/v1/shows; done; echo
200 000 200 200 200 000 200 200 200 200 
```

And the proxy's terminal says which ones, and what the server had answered:

```
ana@laptop:~/boxoffice$ DROP=0.3 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE unlimited B/s, DROP 0.3, SEED 1
1 GET /v1/shows 200, answer sent
2 GET /v1/shows 200, answer dropped
3 GET /v1/shows 200, answer sent
4 GET /v1/shows 200, answer sent
5 GET /v1/shows 200, answer sent
6 GET /v1/shows 200, answer dropped
7 GET /v1/shows 200, answer sent
8 GET /v1/shows 200, answer sent
9 GET /v1/shows 200, answer sent
10 GET /v1/shows 200, answer sent
```

**Two lost, not three.** A share is a chance per request, and ten requests are few, which is why
the seed matters: with `SEED` unchanged, the same two are lost on every run, and a test that failed
because of the second request fails again for the same reason. Change the seed to see a different
bad day.

## Slower than the client will wait

The last case is the one section 02 ended on: an answer slower than the client's timeout. Tickets
waits five seconds; curl's `--max-time 5` waits the same. With the proxy holding answers for six:

```
ana@laptop:~/boxoffice$ DELAY=6000 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 6000 ms, RATE unlimited B/s, DROP 0, SEED 1
ana@laptop:~/boxoffice$ curl -sS --max-time 5 localhost:8070/v1/shows; echo "exit $?"
curl: (28) Operation timed out after 5002 milliseconds with 0 bytes received
exit 28
```

`curl: (28)` is curl's code for a timeout, after 5002 ms and no bytes at all. **Six seconds is a
working network** that boxoffice answered through in a few milliseconds, and to the client it is
indistinguishable from no network. Section 05 shows what Tickets tells its user when it happens.
