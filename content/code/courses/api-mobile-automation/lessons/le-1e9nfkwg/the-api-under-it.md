---
title: The API under a bad network
version: 1
---

**A bad network does its real damage to requests that change something.** A lost answer to a `GET`
costs a retry. A lost answer to a `POST` that bought a ticket leaves the client not knowing whether
it bought one. Lesson 13's tools for that, idempotency keys and retries, were tested there against
failures the stub produced on demand. Here the failure is the network's, in two places: on the
client's side of boxoffice, and on boxoffice's own side, towards the payment provider.

## A lost answer, without a key

A token first, as in lesson 3:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

Restart the proxy losing half the answers, from seed 7, whose first two draws both lose. Then the loop every impatient client is. It tries to buy one seat of `sh-103`, and
tries again while no answer comes, three times:

```
ana@laptop:~/boxoffice$ DROP=0.5 SEED=7 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE unlimited B/s, DROP 0.5, SEED 7
ana@laptop:~/boxoffice$ for i in 1 2 3; do curl -sS localhost:8070/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":1}'; echo; done
curl: (52) Empty reply from server

curl: (52) Empty reply from server

{"id":"ord-1003","show_id":"sh-103","seats":1,"total_cents":6500,"status":"confirmed","payment":"ch-local-ord-1003"}

ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left
1
```

curl's code 52, *empty reply*, twice, then a confirmed order. The client saw one purchase. **The
show had four seats and has one**: every lost answer was an order boxoffice made and the client
never heard of. Nothing in the client's output says so. Only the server's state does, which is why
a test of this has to read it.

## The same, with a key

Restart the proxy with the same seed, so that it loses the same two answers. Then the same loop,
with one `Idempotency-Key` for all three tries, on `sh-102` this time:

```
ana@laptop:~/boxoffice$ DROP=0.5 SEED=7 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE unlimited B/s, DROP 0.5, SEED 7
ana@laptop:~/boxoffice$ for i in 1 2 3; do curl -sS -i localhost:8070/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -H 'idempotency-key: one-seat-7c1e' -d '{"show_id":"sh-102","seats":1}' | grep -iE '^HTTP|^idempotent|^\{'; echo; done
curl: (52) Empty reply from server

curl: (52) Empty reply from server

HTTP/1.1 201 Created
idempotent-replayed: true
{"id":"ord-1004","show_id":"sh-102","seats":1,"total_cents":8000,"status":"confirmed","payment":"ch-local-ord-1004"}

ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-102 | jq .seats_left
119
```

Two empty replies again, then a `201` marked `idempotent-replayed: true`. The order the client
receives is the one the first try made, and `sh-102` lost one seat of its 120. The proxy's log
shows that every try reached boxoffice and was answered `201`:

```
ana@laptop:~/boxoffice$ DROP=0.5 SEED=7 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE unlimited B/s, DROP 0.5, SEED 7
1 POST /v1/orders 201, answer dropped
2 POST /v1/orders 201, answer dropped
3 POST /v1/orders 201, answer sent
```

**The key turned three requests into one purchase, and the network never had to be fixed.** That is
the whole argument for idempotency keys on a phone, where lost answers are an ordinary day rather
than an outage.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 226\" role=\"img\" aria-label=\"Three tries of one purchase through a proxy that loses the first two answers. The client sees curl error 52 twice and then a 201. Without a key, boxoffice made a new order on every try, ord-1001, ord-1002 and ord-1003: three seats gone and one bought. With a key, the first try made ord-1004 and the next two were replays of it: one seat gone, one bought.\"><text x=\"190\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what the client saw</text><text x=\"380\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">boxoffice, no key</text><text x=\"570\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">boxoffice, with a key</text><text x=\"60\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">try 1</text><rect x=\"110\" y=\"52\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">curl: (52)</text><rect x=\"300\" y=\"52\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ord-1001</text><text x=\"380\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a new order</text><rect x=\"490\" y=\"52\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ord-1004</text><text x=\"570\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a new order</text><text x=\"60\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">try 2</text><rect x=\"110\" y=\"102\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">curl: (52)</text><rect x=\"300\" y=\"102\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ord-1002</text><text x=\"380\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a new order</text><rect x=\"490\" y=\"102\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">replay of ord-1004</text><text x=\"570\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the same order</text><text x=\"60\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">try 3</text><rect x=\"110\" y=\"152\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">201</text><rect x=\"300\" y=\"152\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ord-1003</text><text x=\"380\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a new order</text><rect x=\"490\" y=\"152\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">replay of ord-1004</text><text x=\"570\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the same order</text><text x=\"380\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">three seats gone, one bought</text><text x=\"570\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">one seat gone, one bought</text></svg>", "caption": "The client sees the same three outcomes either way. Only the server shows what the lost answers cost."}
```

## As a test

The same check, written with the retry helper of lesson 13, which retries a request that got no
answer at all. The test starts its own boxoffice and its own proxy on ports nothing else uses,
losing half the answers from seed 7. Save it as `tests/poor-network.test.mjs`:

```js
// tests/poor-network.test.mjs: boxoffice behind a link that loses half its answers
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, get } from './lib.mjs';
import { start } from './start.mjs';
import { withRetry } from './retry.mjs';

const BASE = 'http://localhost:8188'; // boxoffice itself
const LINK = 'http://localhost:8178'; // the same boxoffice, through the slow proxy
const stops = [];
let bearer;

before(async () => {
  stops.push(await start('boxoffice.mjs', { PORT: '8188' }));
  stops.push(await start('slow-proxy.mjs', { PORT: '8178', TARGET: BASE, DROP: '0.5', SEED: '7' }));
  bearer = await token(BASE);
});
after(() => Promise.all(stops.map((stop) => stop())));

// One order for one seat, sent through the link until an answer comes back.
function buy(key) {
  return withRetry(() => fetch(`${LINK}/v1/orders`, {
    method: 'POST',
    headers: { authorization: `Bearer ${bearer}`, 'content-type': 'application/json', 'idempotency-key': key },
    body: JSON.stringify({ show_id: 'sh-103', seats: 1 }),
  }), { attempts: 6 });
}

test('with a key, answers lost on the way back cost one order', async () => {
  const res = await buy('poor-network-1');
  assert.equal(res.status, 201);
  assert.equal(res.headers.get('idempotent-replayed'), 'true');
  assert.equal((await get(`${BASE}/v1/shows/sh-103`)).body.seats_left, 3);
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/poor-network.test.mjs | grep -E '^(not )?ok|^# (pass|fail)'
ok 1 - with a key, answers lost on the way back cost one order
# pass 1
# fail 0
```

The assertions are the three facts of the run above: the purchase succeeded, the answer that
arrived was a replay, and exactly one seat is gone. **The last one is the assertion that matters.** It
is made against boxoffice itself, `BASE`, not through the proxy. A check that could itself be lost
would sometimes fail for the wrong reason.

## boxoffice on a slow link

The other direction: boxoffice charging the payment stub of lesson 11 through a slow proxy. Stop
boxoffice and the proxy, and start three programs in three terminals. The first is the stub. The
second is a proxy on port 8071 that forwards to the stub and holds its answers for 1.5 seconds. The
third is boxoffice, told to charge through that proxy:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
ana@laptop:~/boxoffice$ PORT=8071 TARGET=http://localhost:8090 DELAY=1500 node slow-proxy.mjs
slow proxy listening on http://localhost:8071, forwarding to http://localhost:8090
  DELAY 1500 ms, RATE unlimited B/s, DROP 0, SEED 1
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8071 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

An order of two seats of `sh-103`, timed:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2}'
201 1.565003
```

A `201` after a second and a half, the proxy's delay. boxoffice waits up to two seconds for the
provider, as lesson 13 showed, and 1.5 is inside that. Restart the second proxy with 2.5 seconds, past the
limit, and order again:

```
ana@laptop:~/boxoffice$ PORT=8071 TARGET=http://localhost:8090 DELAY=2500 node slow-proxy.mjs
slow proxy listening on http://localhost:8071, forwarding to http://localhost:8090
  DELAY 2500 ms, RATE unlimited B/s, DROP 0, SEED 1
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2}'
504 2.004330
```

`504` after two seconds. Then, a second later, the other side:

```
ana@laptop:~/boxoffice$ curl -s localhost:8090/__requests | jq -c '.[]'
{"idempotency_key":"ord-1001","amount_cents":13000,"reference":"ord-1001"}
{"idempotency_key":"ord-1002","amount_cents":13000,"reference":"ord-1002"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left
2
```

**The stub received both charges and approved both.** Meanwhile boxoffice failed the second order
and put its two seats back: `sh-103` has two left, from the first order alone. The logs say how it
ended:

```
ana@laptop:~/boxoffice$ PORT=8071 TARGET=http://localhost:8090 DELAY=2500 node slow-proxy.mjs
slow proxy listening on http://localhost:8071, forwarding to http://localhost:8090
  DELAY 2500 ms, RATE unlimited B/s, DROP 0, SEED 1
1 POST /charges 201, but the client had hung up
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
POST /charges 201 (approve)
POST /charges 201 (approve)
GET /__requests 200 (approve)
```

The stub answered at once, and the proxy held that answer until boxoffice had stopped listening.
It is lesson 13's slow provider again: a customer charged for an order the app called failed. One
difference matters in a report. **Here the provider was fast and the network was slow**, and
nothing on either side could tell which. Looking at the provider's own response times would clear
it of blame, correctly, and the defect would still be there.
