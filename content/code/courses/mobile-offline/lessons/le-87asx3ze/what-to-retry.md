---
title: What is worth retrying, and what is an answer
version: 1
---

**A failed request is worth retrying when the failure says nothing about the request itself: the
network dropped it, the server was busy, or the answer never came.** When the server read the
request and said no, the failure is an answer, and sending the same bytes again gets the same no.
Lesson 8 drew that line between a network error and a 4xx; this lesson decides how long to wait
before each new try, and how many tries to make.

| what came back | retry? | why |
|---|---|---|
| no answer: the connection failed, or the timeout ran out | yes | nothing reached the client; whether anything reached the server is the last section's problem |
| 500, 502, 503, 504 | yes | the server, or something in front of it, is in trouble, and it may not be in a moment |
| 429 Too Many Requests | yes, and slower | the server is asking the client to back off, often saying for how long |
| 408 Request Timeout | yes | the server gave up waiting for the request |
| 400, 401, 403, 404, 409, 422 | no | the server read it; the same request gets the same answer |

401 is the one exception worth naming: an expired access token is fixed by refreshing it and then
sending again, which is lesson 20's subject. It is still not a plain retry, because something has
to change first.

## A server that misbehaves on request

This lesson's folder is `~/planner/retry`, and its server is lesson 8's, grown in two ways. **It
gives each new session an id of its own**, `n1`, `n2`, as many real servers do, and it can be told
to fail: every word after `node server.ts` is how to answer the next request that changes
something. Save this as `server.ts`:

```typescript
// server.ts: lesson 8's server, grown for this lesson. It gives each new session an id of its
// own, and it can be told to misbehave: `node server.ts 503 429 drop` answers the first three
// requests that change something that way, and every later one normally.
import { createServer, type ServerResponse } from "node:http";

type Session = { id: string; course: string; date: string; minutes: number };
const sessions: Session[] = [];
const faults = process.argv.slice(2);

function reply(res: ServerResponse, status: number, body: unknown, headers = {}) {
  res.writeHead(status, { "content-type": "application/json", ...headers }).end(JSON.stringify(body) + "\n");
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  if (req.method === "GET") return reply(res, 200, sessions);
  const fault = faults.shift();
  console.log(req.method, req.url, fault ?? "ok");
  if (fault === "503") return reply(res, 503, { error: "busy, try again" });
  if (fault === "429") return reply(res, 429, { error: "too many requests" }, { "retry-after": "2" });
  if (fault === "400") return reply(res, 400, { error: "minutes must be a number" });
  if (req.method !== "POST") return reply(res, 405, { error: "method not allowed" });
  const session = { ...JSON.parse(text), id: `n${sessions.length + 1}` };
  sessions.push(session);
  if (fault === "drop") return req.socket.destroy(); // saved, and the answer never leaves
  reply(res, 201, session);
}).listen(8009, "127.0.0.1", () => console.log("listening on 8009"));
```

`drop` is the nastiest of them: the server saves the session and then closes the connection before
the answer leaves. The last section of the lesson is about it.

The waits come from a small module the next section explains. Save it now as `backoff.ts`:

```typescript
// backoff.ts: how long to wait before the next try, with a seeded generator so it repeats.

// mulberry32: a tiny generator of numbers in [0, 1). The same seed gives the same sequence.
export function seeded(seed: number): () => number {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Exponential: double the ceiling on every attempt, up to a cap.
export function ceiling(attempt: number, base: number, cap: number): number {
  return Math.min(cap, base * 2 ** (attempt - 1));
}

// Full jitter: wait a random time between zero and the ceiling.
export function fullJitter(attempt: number, base: number, cap: number, random: () => number): number {
  return Math.floor(random() * ceiling(attempt, base, cap));
}
```

## The retry loop

The program sends one new session, the way a drain sends one operation, and decides after each
answer whether to try again:

```schooling-example
{"language": "typescript", "file": "retry.ts", "parts": [{"code": "// retry.ts: send one new session to the server, retrying what is worth retrying.\nimport { seeded, fullJitter } from \"./backoff.ts\";\n\nconst SERVER = \"http://127.0.0.1:8009/sessions\";\nconst BASE = 200, CAP = 5000, TRIES = 5, TIMEOUT = 2000; // milliseconds, and attempts in all\nconst random = seeded(7);\nconst body = JSON.stringify({ course: \"guitar\", date: \"2026-10-23\", minutes: 25 });\n", "note": "Four numbers decide the policy: the first wait's ceiling, the longest wait, how many tries in all, and how long one try may take. The seed makes the waits repeat."}, {"code": "function worthRetrying(status: number): boolean {\n  return status >= 500 || status === 429 || status === 408;\n}\n", "note": "The classification. A 5xx is the server's trouble, 429 asks the client to slow down and 408 says the request took too long; every other status is an answer to keep."}, {"code": "for (let attempt = 1; attempt <= TRIES; attempt++) {\n  let wait = fullJitter(attempt, BASE, CAP, random);\n  try {\n    const res = await fetch(SERVER, {\n      method: \"POST\", body, headers: { \"content-type\": \"application/json\" }, signal: AbortSignal.timeout(TIMEOUT),\n    });", "note": "Each attempt has its own deadline. Without `AbortSignal.timeout`, a request to a server that accepted the connection and never answers would wait for ever."}, {"code": "    if (res.ok) {\n      console.log(`attempt ${attempt}: ${res.status}, saved as ${(await res.json()).id}`);\n      break;\n    }\n    if (!worthRetrying(res.status)) {\n      console.log(`attempt ${attempt}: ${res.status}, not retrying: ${(await res.json()).error}`);\n      break;\n    }", "note": "A success ends the loop, and so does a status not worth retrying: the server's reason is printed and the operation is left for the person, as lesson 8's dead table does."}, {"code": "    const after = Number(res.headers.get(\"retry-after\"));\n    if (after > 0) wait = Math.min(after * 1000, CAP);\n    console.log(`attempt ${attempt}: ${res.status}` + (attempt < TRIES ? `, waiting ${wait} ms${after > 0 ? \" as Retry-After asks\" : \"\"}` : \"\"));", "note": "If the server named a wait in `Retry-After`, that replaces the computed one, still held under the cap."}, {"code": "  } catch (e) {\n    const why = (e as Error).name === \"TimeoutError\" ? \"timed out\" : \"no answer\";\n    console.log(`attempt ${attempt}: ${why}` + (attempt < TRIES ? `, waiting ${wait} ms` : \"\"));\n  }", "note": "No answer at all, or no answer in time. Both are worth retrying, and both leave the client not knowing whether the server did the work."}, {"code": "  if (attempt === TRIES) console.log(\"giving up for now; the operation stays in the outbox\");\n  else await new Promise((resolve) => setTimeout(resolve, wait));\n}", "note": "After the last try the loop stops rather than waiting. The operation is still in the outbox, and the next drain starts again from attempt 1."}]}
```

Start the server so that it answers 503 twice and then works, `node server.ts 503 503` in a second
terminal, and send. Then stop the server with Ctrl+C, start it as `node server.ts 400`, and send
again:

```
ana@dev:~/planner/retry$ node retry.ts
attempt 1: 503, waiting 2 ms
attempt 2: 503, waiting 24 ms
attempt 3: 201, saved as n1
ana@dev:~/planner/retry$ node retry.ts
attempt 1: 400, not retrying: minutes must be a number
```

The 503s were retried and the third try saved the session. The 400 was not retried at all, and the
server's reason was printed instead, because no number of tries turns a malformed request into a
good one.
