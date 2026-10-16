---
title: A payment provider of your own
version: 1
---

**The first stand-in is about sixty lines of Node, written for this course, with no packages.** It plays
the payment provider boxoffice calls: it takes a charge at `POST /charges` and answers `201` with an
id and a status. It also does the two things the real provider never would. It answers however you
tell it to, and it keeps a list of every charge it received.

What it has to imitate is fixed by boxoffice's own code, in the function `charge`: a `POST` to
`$PAYMENTS_URL/charges` with a JSON body holding `amount_cents` and `reference`, an `idempotency-key`
header, an answer expected within two seconds, and **anything but `201` treated as a failure**. That
last rule comes back in section 06.

In `~/boxoffice`, open a new file and save it as `payments-stub.mjs`:

```js
// payments-stub.mjs: a stand-in for the payment provider boxoffice charges.
// Start it with `node payments-stub.mjs`. It listens on port 8090 (PORT changes
// that) and answers every charge the way MODE says:
//   approve  201, the charge approved (the default)
//   decline  201, the charge declined
//   slow     201 approved, after 3 seconds: past boxoffice's 2-second timeout
//   down     500, the way a provider in trouble answers
// PUT /__mode changes the mode while it runs. GET /__requests lists every
// charge it received, and DELETE /__requests forgets them.
import http from 'node:http';

const PORT = Number(process.env.PORT || 8090);
const MODES = ['approve', 'decline', 'slow', 'down'];
let mode = process.env.MODE || 'approve';
let received = [];
let next = 1;

if (!MODES.includes(mode)) {
  console.error(`MODE must be one of ${MODES.join(', ')}, not "${mode}"`);
  process.exit(1);
}

function send(res, status, body) {
  res.writeHead(status, body === undefined ? {} : { 'content-type': 'application/json' });
  res.end(body === undefined ? '' : `${JSON.stringify(body)}\n`);
}

async function readBody(req) {
  let text = '';
  for await (const chunk of req) text += chunk;
  return text;
}

async function route(req, res, text) {
  if (req.url === '/__requests' && req.method === 'GET') return send(res, 200, received);
  if (req.url === '/__requests' && req.method === 'DELETE') {
    received = [];
    return send(res, 204);
  }
  if (req.url === '/__mode' && req.method === 'PUT') {
    if (!MODES.includes(text.trim())) return send(res, 400, { error: `mode is one of ${MODES.join(', ')}` });
    mode = text.trim();
    return send(res, 200, { mode });
  }
  if (req.url !== '/charges' || req.method !== 'POST') return send(res, 404, { error: 'no such thing here' });
  let charge;
  try { charge = JSON.parse(text); } catch { return send(res, 400, { error: 'the body is not JSON' }); }
  received.push({ idempotency_key: req.headers['idempotency-key'] ?? null, ...charge });
  if (mode === 'down') return send(res, 500, { error: 'payments are down' });
  if (mode === 'slow') await new Promise((done) => setTimeout(done, 3000));
  send(res, 201, { id: `ch-${next++}`, status: mode === 'decline' ? 'declined' : 'approved' });
}

http.createServer(async (req, res) => {
  const text = await readBody(req);
  res.on('close', () => {
    const outcome = res.writableFinished ? res.statusCode : 'the caller hung up first';
    console.log(`${req.method} ${req.url} ${outcome} (${mode})`);
  });
  await route(req, res, text);
}).listen(PORT, () => console.log(`payments stub listening on http://localhost:${PORT}, mode ${mode}`));
```

Its control surface is four requests, kept apart from the provider's own address by names starting
with two underscores, a common convention for "this belongs to the stand-in, not to the thing it
imitates":

| request | does |
|---|---|
| `POST /charges` | records the charge, then answers as the current mode says |
| `PUT /__mode` | changes the mode; the body is the mode's name |
| `GET /__requests` | the charges received so far, oldest first |
| `DELETE /__requests` | forgets them |

## boxoffice, pointed at it

Start the stub in a terminal of its own, from `~/boxoffice`:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
```

Then stop boxoffice with Ctrl-C in its terminal and start it again with the variable set. **Nothing
in boxoffice changes but an address**, which is the whole point:

```
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Ask for a token the way lesson 1 did, and place an order for two seats of sh-101:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}' | jq
{
  "id": "ord-1001",
  "show_id": "sh-101",
  "seats": 2,
  "total_cents": 16000,
  "status": "confirmed",
  "payment": "ch-1"
}
```

`"payment": "ch-1"`: the id came from the stub, so the call happened. The stub can also show what
boxoffice sent:

```
ana@laptop:~/boxoffice$ curl -s localhost:8090/__requests | jq
[
  {
    "idempotency_key": "ord-1001",
    "amount_cents": 16000,
    "reference": "ord-1001"
  }
]
```

That is the observation the real provider would never give you. The amount is two seats at 8000
cents, the reference is the order's id, and **the idempotency key is the order's id too**, because
the request did not carry an `Idempotency-Key` of its own; boxoffice's code says `key || id`. Lesson
13 is about that key.

## A failure, on demand

Switch the stub to declining and place the same order:

```
ana@laptop:~/boxoffice$ curl -s -X PUT localhost:8090/__mode -d decline
{"mode":"decline"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}'
{"type":"about:blank","title":"Payment Required","status":402,"detail":"the payment was declined"}
```

`402 Payment Required`, which is boxoffice's answer to a declined charge, and a test of it took one
request to set up. The stub's terminal kept a line for each request, with the mode it was in:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
POST /charges 201 (approve)
GET /__requests 200 (approve)
PUT /__mode 200 (decline)
POST /charges 201 (decline)
```

The other two modes, `slow` and `down`, make boxoffice answer `504` and `502`; lesson 13 tests both,
and what a failed order leaves behind. A stand-in that trusted its own configuration would be a
silent failure waiting to happen, so this one refuses a mode it does not know, before it listens on
anything:

```
ana@laptop:~/boxoffice$ MODE=declined node payments-stub.mjs
MODE must be one of approve, decline, slow, down, not "declined"
```

**A typo in a mode would otherwise approve every charge**, and the test meant to see a decline would
pass while testing nothing. Lessons 12 and 13 start the stub again, so keep the file.
