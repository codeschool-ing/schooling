---
title: The payment that was sent twice
version: 1
---

**A person taps Buy on a train. The request reaches the server, the card is charged, and the answer
is lost in a tunnel. The app does what lesson 9 taught it and tries again, and the card is charged
a second time.** Nobody made a mistake that any single line of code would show. The client retried
a request that failed, as it should; the server charged a card for a valid request, as it should.
The defect is in the space between them, and it costs the person money and the company a refund
and a support conversation.

It is the same shape as lesson 9's duplicated session, with a number attached. A second study
session costs the person a confusing week; a second charge of R$ 49.00 costs them a call to their
bank. Payment companies met it first and at scale, which is why the fix carries their vocabulary.

## Seeing it

This lesson's folder is `~/planner/idempotency`. The server is lesson 9's, grown: it sells courses
at `/purchases`, and it can remember answers, which the next section is about. For now, read the
part that charges: a purchase is appended to `purchases`, and that is the card being charged. Save
this as `server.ts`:

```typescript
// server.ts: lesson 9's server, grown for this lesson. It sells courses, and it remembers the
// answer it gave to each Idempotency-Key, per user, for 24 hours. `node server.ts drop slow`
// misbehaves on the first two requests that change something, as in lesson 9.
import { createServer, type ServerResponse } from "node:http";
import { createHash } from "node:crypto";

type Saved = { fingerprint: string; status: number; body: unknown; at: number } | "in progress";
const purchases: { id: string; user: string; course: string; cents: number }[] = [];
const sessions = new Map<string, unknown>();
const answers = new Map<string, Saved>(); // "<user> <key>" -> the answer given
const DAY = 24 * 60 * 60 * 1000;
const faults = process.argv.slice(2);

function reply(res: ServerResponse, status: number, body: unknown, headers = {}) {
  res.writeHead(status, { "content-type": "application/json", ...headers }).end(JSON.stringify(body) + "\n");
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  const user = String(req.headers["x-user"]); // stands in for the signed-in account
  if (req.method === "GET" && req.url === "/purchases") return reply(res, 200, purchases);
  if (req.method === "GET") return reply(res, 200, [...sessions.values()]);
  const fault = faults.shift();
  console.log(req.method, req.url, user, fault ?? "ok");

  // PUT /sessions/<id>: the client chose the id, so doing it twice is doing it once.
  if (req.method === "PUT") {
    sessions.set(req.url!, JSON.parse(text));
    return reply(res, 200, JSON.parse(text));
  }

  // POST /purchases: charging money, so a retry must not charge again.
  const key = req.headers["idempotency-key"];
  const slot = `${user} ${key}`;
  const fingerprint = createHash("sha256").update(text).digest("hex");
  const saved = key ? answers.get(slot) : undefined;
  if (saved === "in progress") return reply(res, 409, { error: "a request with this key is still running" });
  if (saved && Date.now() - saved.at < DAY) {
    if (saved.fingerprint !== fingerprint) return reply(res, 422, { error: "this key was used with a different body" });
    return reply(res, saved.status, saved.body, { "idempotent-replayed": "true" });
  }
  if (key) answers.set(slot, "in progress");
  if (fault === "slow") await new Promise((resolve) => setTimeout(resolve, 1000));
  const purchase = { id: `p${purchases.length + 1}`, user, ...JSON.parse(text) };
  purchases.push(purchase); // the card is charged here
  if (key) answers.set(slot, { fingerprint, status: 201, body: purchase, at: Date.now() });
  if (fault === "drop") return req.socket.destroy();
  reply(res, 201, purchase);
}).listen(8010, "127.0.0.1", () => console.log("listening on 8010"));
```

The client is the Buy button: one purchase of the Statistics course, 4900 cents, retried on a lost
answer exactly as lesson 9's loop retries. With no argument it sends no key. Save this as
`buy.ts`:

```typescript
// buy.ts: buy a course from the planner, retrying a lost answer as lesson 9 does.
// `node buy.ts` sends no key; `node buy.ts key` makes one when the person taps Buy.
import { randomUUID } from "node:crypto";

const withKey = process.argv[2] === "key";
const key = randomUUID(); // made once, before the first try, and sent with every retry
const body = JSON.stringify({ course: "statistics", cents: 4900 });

for (let attempt = 1; attempt <= 3; attempt++) {
  try {
    const res = await fetch("http://127.0.0.1:8010/purchases", {
      method: "POST",
      body,
      headers: { "content-type": "application/json", "x-user": "ana", ...(withKey ? { "idempotency-key": key } : {}) },
      signal: AbortSignal.timeout(2000),
    });
    const replayed = res.headers.get("idempotent-replayed") ? ", replayed" : "";
    console.log(`attempt ${attempt}: ${res.status}${replayed}`, await res.json());
    break;
  } catch {
    console.log(`attempt ${attempt}: no answer, trying again`);
    await new Promise((resolve) => setTimeout(resolve, 300));
  }
}
```

Start the server as `node server.ts drop`, so it charges and then loses the answer, and tap Buy:

```
ana@dev:~/planner/idempotency$ node buy.ts
attempt 1: no answer, trying again
attempt 2: 201 { id: 'p2', user: 'ana', course: 'statistics', cents: 4900 }
ana@dev:~/planner/idempotency$ curl -s http://127.0.0.1:8010/purchases
[{"id":"p1","user":"ana","course":"statistics","cents":4900},{"id":"p2","user":"ana","course":"statistics","cents":4900}]
```

**One tap, two charges.** `p1` was the first try, charged, its answer lost; `p2` was the retry,
charged again. The client printed one success, so the screen said "bought" once. The person's
statement will say it twice.

## The fix, in one sentence

The client gives the operation a name before the first try and sends the name with every retry; the
server remembers the answer it gave to each name and, on seeing a name again, gives the same answer
without doing the work again. **The name is an idempotency key.** An operation is *idempotent* when
doing it twice has the same effect as doing it once, and the key is what makes a `POST`, which is
not, behave as if it were.

Stripe's API takes it as a header, `Idempotency-Key`, and most payment APIs copied the shape. The
IETF's HTTP API working group has a draft standardising it, *The Idempotency-Key HTTP Header Field*;
it is still a draft, not an RFC, and the course cites it as one.
