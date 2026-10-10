---
title: boxoffice, a API que o curso testa
version: 1
---

**A API que toda lição da primeira metade testa se chama boxoffice.** Ela vende ingressos de um
pequeno teatro em São Paulo: lista os espetáculos, diz quantos lugares cada um ainda tem e aceita
pedidos de programas que tenham um token válido. É um arquivo de JavaScript, 230 linhas, escrito para
este curso e mostrado inteiro abaixo. Usa só os módulos do próprio Node, então não há nada para
instalar.

**Ela tem defeitos, e alguns são de propósito.** Um curso sobre testes precisa de algo que valha a
pena testar, e uma API sem falhas ensina a escrever testes que passam. Você acha o primeiro na seção
07. Ainda assim vale ler o arquivo: não é preciso acompanhar cada linha, e cada lição aponta a parte
de que trata.

## O projeto

Crie um diretório para o projeto, onde toda lição trabalha, e entre nele:

```sh
mkdir ~/boxoffice
cd ~/boxoffice
```

Copie o programa com o botão do bloco em vez de redigitá-lo, depois abra o editor, cole e salve como
`boxoffice.mjs`:

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

A terminação `.mjs` diz ao Node que o arquivo é um módulo JavaScript moderno, e é isso que deixa as
primeiras linhas dizerem `import`.

## O que ela guarda

Três espetáculos, em datas fixas de novembro de 2026, para que o curso leia igual quando quer que
você o faça:

| id | espetáculo | quando | preço | lugares |
|---|---|---|---|---|
| `sh-101` | Auto da Compadecida | 6 de novembro, 20:00 | R$ 80,00 | 120 |
| `sh-102` | Auto da Compadecida | 7 de novembro, 20:00 | R$ 80,00 | 120 |
| `sh-103` | O Pagador de Promessas | 8 de novembro, 18:00 | R$ 65,00 | 4 |

O último é pequeno de propósito: quatro lugares é uma sessão que se esgota com duas requisições, e é
assim que a lição 2 testa o que acontece quando não sobra nenhum.

Tudo vive na memória do programa. **Parar o boxoffice e iniciá-lo de novo o deixa exatamente como
começou**, com todos os lugares livres e o primeiro pedido numerado `ord-1001`. Os testes dependem
disso, e a lição 12 trata do que dá errado quando eles esquecem.

## Iniciando

O boxoffice roda até você pará-lo, então precisa de um terminal só para ele. Abra um segundo
terminal, vá ao projeto e inicie-o ali:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Deixe esse terminal aberto; ele imprime uma linha para cada requisição que o boxoffice responde.
Aperte Ctrl-C nele quando quiser parar o servidor. Todo o resto desta lição é digitado no primeiro
terminal, e a primeira requisição pergunta se ele está vivo:

```
ana@laptop:~/boxoffice$ curl localhost:8080/health
{"status":"ok"}
```

`{"status":"ok"}` é a resposta. Duas observações sobre a requisição. `localhost` é o nome que todo
computador dá a si mesmo, então a requisição nunca sai da sua máquina, e `:8080` é a porta em que o
boxoffice escuta. A próxima requisição lista os espetáculos; `-s` cala o progresso do curl, e `| jq`
passa a resposta ao jq, que dispõe o JSON um campo por linha:

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

`price_cents` é o preço em centavos, então `8000` é R$ 80,00. A lição 2 diz por que dinheiro viaja
assim.
