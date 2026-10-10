---
title: boxoffice, the API the course tests
version: 1
---

**The API every lesson of the first half tests is called boxoffice.** It sells tickets for a small
theatre in São Paulo: it lists the shows, says how many seats each has left, and takes orders from
programs that hold a valid token. It is one file of JavaScript, 230 lines, written
for this course and shown whole below. It uses nothing but Node's own modules, so there is nothing
to install.

**It has defects, and some of them are deliberate.** A course about testing needs something worth
testing, and an API with no flaws teaches you to write tests that pass. You find the first one in
section 07. The file is still worth reading: you do not need to follow every line, and each lesson
points at the part it is about.

## The project

Make a directory for the project, which every lesson works in, and go into it:

```sh
mkdir ~/boxoffice
cd ~/boxoffice
```

Copy the program with the button on its block rather than retyping it, then open your editor, paste
it and save it as `boxoffice.mjs`:

```js
// boxoffice.mjs: the ticket API of a small theatre in São Paulo.
// Start it with `node boxoffice.mjs`. It listens on port 8080 (PORT changes
// that) and keeps everything in memory, so a restart puts it back as it began.
import http from 'node:http';
import crypto from 'node:crypto';

const PORT = Number(process.env.PORT || 8080);
const TOKEN_TTL = Number(process.env.TOKEN_TTL || 900); // seconds a token lives
const REPORT_DELAY = Number(process.env.REPORT_DELAY || 500); // ms behind the orders
const PAYMENTS_URL = process.env.PAYMENTS_URL || ''; // empty: every charge is approved here
const SECRET = process.env.TOKEN_SECRET || 'lab-only-secret';
const STAFF_KEY = process.env.STAFF_KEY || 'lab-only-staff-key';

// The programs allowed to ask for a token, and what each may do.
const CLIENTS = {
  'ci-tests': { secret: 'ci-secret', scope: 'orders:read orders:write' },
  'auditor': { secret: 'auditor-secret', scope: 'orders:read' },
};

const shows = [
  { id: 'sh-101', title: 'Auto da Compadecida', starts_at: '2026-11-06T20:00:00-03:00', price_cents: 8000, seats: 120 },
  { id: 'sh-102', title: 'Auto da Compadecida', starts_at: '2026-11-07T20:00:00-03:00', price_cents: 8000, seats: 120 },
  { id: 'sh-103', title: 'O Pagador de Promessas', starts_at: '2026-11-08T18:00:00-03:00', price_cents: 6500, seats: 4 },
];
const orders = new Map(); // 'ord-1001' -> order
const replies = new Map(); // client + Idempotency-Key -> the first reply
let nextOrder = 1001;
let report = { orders: 0, seats: 0, revenue_cents: 0 };

const seatsLeft = (show) => show.seats - [...orders.values()]
  .filter((o) => o.show_id === show.id && o.status === 'confirmed')
  .reduce((sum, o) => sum + o.seats, 0);
const publicShow = (s) => ({ id: s.id, title: s.title, starts_at: s.starts_at,
  price_cents: s.price_cents, seats_left: seatsLeft(s) });

// The sales report is rebuilt in the background, REPORT_DELAY behind the orders.
function rebuildReportSoon() {
  setTimeout(() => {
    const done = [...orders.values()].filter((o) => o.status === 'confirmed');
    report = { orders: done.length, seats: done.reduce((n, o) => n + o.seats, 0),
      revenue_cents: done.reduce((n, o) => n + o.total_cents, 0) };
  }, REPORT_DELAY);
}

function send(res, status, body, headers = {}) {
  const text = body === undefined ? '' : `${JSON.stringify(body)}\n`;
  res.writeHead(status, { ...(text && { 'content-type': 'application/json' }), ...headers });
  res.end(text);
}

// Every error has the same shape, RFC 9457's problem details.
function problem(res, status, detail, headers = {}) {
  send(res, status, { type: 'about:blank', title: http.STATUS_CODES[status], status, detail },
    { 'content-type': 'application/problem+json', ...headers });
}

const b64 = (s) => Buffer.from(s).toString('base64url');
const hmac = (s) => crypto.createHmac('sha256', SECRET).update(s).digest('base64url');

function signToken(client, scope) {
  const now = Math.floor(Date.now() / 1000);
  const head = b64(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const body = b64(JSON.stringify({ sub: client, scope, iat: now, exp: now + TOKEN_TTL }));
  return `${head}.${body}.${hmac(`${head}.${body}`)}`;
}

// The claims of a valid token, or the reason it is not one.
function readToken(req) {
  const [kind, token] = (req.headers.authorization || '').split(' ');
  if (kind !== 'Bearer' || !token) return { error: 'no bearer token' };
  const [head, body, sig] = token.split('.');
  const good = hmac(`${head}.${body}`);
  if (!sig || sig.length !== good.length || !crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(good))) {
    return { error: 'bad signature' };
  }
  let claims;
  try { claims = JSON.parse(Buffer.from(body, 'base64url')); } catch { return { error: 'bad token' }; }
  if (claims.exp <= Math.floor(Date.now() / 1000)) return { error: 'token expired' };
  return { claims };
}

// One answer for every request that is not allowed in, and the header that says why.
function refuse(res, status, error, detail) {
  problem(res, status, detail, { 'www-authenticate': `Bearer error="${error}", error_description="${detail}"` });
}

async function readBody(req) {
  let text = '';
  for await (const chunk of req) text += chunk;
  return text;
}

async function charge(amount, reference, key) {
  if (!PAYMENTS_URL) return { id: `ch-local-${reference}`, status: 'approved' };
  const res = await fetch(`${PAYMENTS_URL}/charges`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'idempotency-key': key },
    body: JSON.stringify({ amount_cents: amount, reference }),
    signal: AbortSignal.timeout(2000),
  });
  if (res.status !== 201) throw new Error(`payments answered ${res.status}`);
  return res.json();
}

async function createOrder(req, res, claims) {
  if (!claims.scope.split(' ').includes('orders:write')) {
    return refuse(res, 403, 'insufficient_scope', 'this token may not create orders');
  }
  if (!(req.headers['content-type'] || '').startsWith('application/json')) {
    return problem(res, 415, 'send the order as application/json');
  }
  const text = await readBody(req);
  const key = req.headers['idempotency-key'];
  const remembered = key && replies.get(`${claims.sub} ${key}`);
  if (remembered) {
    if (remembered.text !== text) return problem(res, 422, 'this Idempotency-Key was used with a different body');
    return send(res, remembered.status, remembered.body, { ...remembered.headers, 'idempotent-replayed': 'true' });
  }
  let input;
  try { input = JSON.parse(text); } catch { return problem(res, 400, 'the body is not valid JSON'); }
  const show = shows.find((s) => s.id === input.show_id);
  if (!show) return problem(res, 422, `there is no show ${JSON.stringify(input.show_id)}`);
  if (!Number.isInteger(input.seats) || input.seats < 1 || input.seats > 6) {
    return problem(res, 422, 'seats must be a whole number from 1 to 6');
  }
  const left = seatsLeft(show);
  if (input.seats > left) return problem(res, 409, `only ${left} seat${left === 1 ? '' : 's'} left`);
  const id = `ord-${nextOrder++}`;
  const order = { id, show_id: show.id, seats: input.seats, total_cents: input.seats * show.price_cents,
    status: 'confirmed', client: claims.sub };
  orders.set(id, order); // the seats are held while the charge is made
  try {
    const paid = await charge(order.total_cents, id, key || id);
    if (paid.status !== 'approved') {
      order.status = 'declined';
      return problem(res, 402, 'the payment was declined');
    }
    order.payment = paid.id;
  } catch (err) {
    order.status = 'failed';
    const timedOut = err.name === 'TimeoutError';
    console.log(`  payments: ${err.message}`);
    return problem(res, timedOut ? 504 : 502, timedOut ? 'the payment provider did not answer in time'
      : 'the payment provider failed');
  }
  rebuildReportSoon();
  const { client, ...body } = order;
  const headers = { location: `/v1/orders/${id}` };
  if (key) replies.set(`${claims.sub} ${key}`, { text, status: 201, body, headers });
  send(res, 201, body, headers);
}

async function route(req, res) {
  const url = new URL(req.url, 'http://localhost');
  const path = url.pathname;
  const allow = (...methods) => {
    if (methods.includes(req.method)) return true;
    problem(res, 405, `${req.method} is not allowed here`, { allow: methods.join(', ') });
    return false;
  };

  if (path === '/health') return allow('GET') && send(res, 200, { status: 'ok' });

  if (path === '/v1/shows') {
    if (!allow('GET')) return;
    const date = url.searchParams.get('date');
    const list = shows.filter((s) => !date || s.starts_at.startsWith(date)).map(publicShow);
    return send(res, 200, { shows: list }, { 'cache-control': 'max-age=60' });
  }

  const showPath = path.match(/^\/v1\/shows\/([^/]+)$/);
  if (showPath) {
    if (!allow('GET')) return;
    const show = shows.find((s) => s.id === showPath[1]);
    if (!show) return problem(res, 404, `there is no show ${showPath[1]}`);
    const body = publicShow(show);
    const etag = `"${crypto.createHash('sha256').update(JSON.stringify(body)).digest('hex').slice(0, 16)}"`;
    if (req.headers['if-none-match'] === etag) return send(res, 304, undefined, { etag });
    return send(res, 200, body, { etag });
  }

  if (path === '/oauth/token') {
    if (!allow('POST')) return;
    const form = new URLSearchParams(await readBody(req));
    if (form.get('grant_type') !== 'client_credentials') {
      return send(res, 400, { error: 'unsupported_grant_type' });
    }
    const client = CLIENTS[form.get('client_id')];
    if (!client || client.secret !== form.get('client_secret')) {
      return send(res, 401, { error: 'invalid_client' });
    }
    return send(res, 200, { access_token: signToken(form.get('client_id'), client.scope),
      token_type: 'Bearer', expires_in: TOKEN_TTL, scope: client.scope }, { 'cache-control': 'no-store' });
  }

  if (path === '/v1/reports/sales') {
    if (!allow('GET')) return;
    if (req.headers['x-api-key'] !== STAFF_KEY) return problem(res, 401, 'send the staff key in X-Api-Key');
    return send(res, 200, report);
  }

  if (path === '/v1/orders' || path.startsWith('/v1/orders/')) {
    const { claims, error } = readToken(req);
    if (!claims) return refuse(res, 401, 'invalid_token', error);
    if (path === '/v1/orders') return allow('POST') && createOrder(req, res, claims);
    const order = orders.get(path.slice('/v1/orders/'.length));
    if (!allow('GET', 'DELETE')) return;
    if (!order || order.client !== claims.sub) return problem(res, 404, 'there is no such order');
    if (req.method === 'DELETE') {
      if (!claims.scope.split(' ').includes('orders:write')) {
        return refuse(res, 403, 'insufficient_scope', 'this token may not cancel orders');
      }
      if (order.status === 'confirmed') rebuildReportSoon();
      order.status = 'cancelled';
      return send(res, 204);
    }
    const { client, ...body } = order;
    return send(res, 200, body);
  }

  problem(res, 404, `nothing lives at ${path}`);
}

http.createServer((req, res) => {
  res.on('finish', () => console.log(`${req.method} ${req.url} ${res.statusCode}`));
  route(req, res).catch((err) => {
    console.error(err);
    if (!res.headersSent) problem(res, 500, 'something broke on our side');
  });
}).listen(PORT, () => console.log(`boxoffice listening on http://localhost:${PORT}`));
```

The `.mjs` ending tells Node the file is a modern JavaScript module, which is what lets the first
lines say `import`.

## What it holds

Three shows, at fixed dates in November 2026, so the course reads the same whenever you take it:

| id | show | when | price | seats |
|---|---|---|---|---|
| `sh-101` | Auto da Compadecida | 6 November, 20:00 | R$ 80,00 | 120 |
| `sh-102` | Auto da Compadecida | 7 November, 20:00 | R$ 80,00 | 120 |
| `sh-103` | O Pagador de Promessas | 8 November, 18:00 | R$ 65,00 | 4 |

The last one is small on purpose: four seats is a show you can sell out with two requests, which
is how lesson 2 tests what happens when there are none left.

Everything lives in the program's memory. **Stopping boxoffice and starting it again puts it back
exactly as it began**, with every seat free and the first order numbered `ord-1001`. Tests depend on
that, and lesson 12 is about what goes wrong when they forget it.

## Starting it

boxoffice runs until you stop it, so it needs a terminal of its own. Open a second terminal, go to
the project, and start it there:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Leave that terminal open; it prints one line for every request boxoffice answers. Press Ctrl-C in
it when you want to stop the server. Everything else in this lesson is typed in your first
terminal, and the first request asks whether it is alive:

```
ana@laptop:~/boxoffice$ curl localhost:8080/health
{"status":"ok"}
```

`{"status":"ok"}` is the answer. Two notes on the request. `localhost` is the name every computer
gives itself, so the request never leaves your machine, and `:8080` is the port boxoffice listens
on. The next request lists the shows; `-s` keeps curl quiet about its progress, and `| jq` hands the
answer to jq, which lays JSON out one field per line:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows | jq
{
  "shows": [
    {
      "id": "sh-101",
      "title": "Auto da Compadecida",
      "starts_at": "2026-11-06T20:00:00-03:00",
      "price_cents": 8000,
      "seats_left": 120
    },
    {
      "id": "sh-102",
      "title": "Auto da Compadecida",
      "starts_at": "2026-11-07T20:00:00-03:00",
      "price_cents": 8000,
      "seats_left": 120
    },
    {
      "id": "sh-103",
      "title": "O Pagador de Promessas",
      "starts_at": "2026-11-08T18:00:00-03:00",
      "price_cents": 6500,
      "seats_left": 4
    }
  ]
}
```

`price_cents` is the price in cents, so `8000` is R$ 80,00. Lesson 2 says why money travels that
way.
