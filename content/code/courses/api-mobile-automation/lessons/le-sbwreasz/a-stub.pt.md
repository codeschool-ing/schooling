---
title: Um provedor de pagamento só seu
version: 1
---

**O primeiro substituto tem umas sessenta linhas de Node, escritas para este curso, sem pacotes.** Ele
faz o papel do provedor de pagamento que o boxoffice chama: recebe uma cobrança em `POST /charges` e
responde `201` com um id e um status. Ele também faz as duas coisas que o provedor de verdade nunca
faria. Responde do jeito que você mandar, e guarda uma lista de toda cobrança que recebeu.

O que ele precisa imitar está fixado pelo próprio código do boxoffice, na função `charge`: um `POST`
para `$PAYMENTS_URL/charges` com um corpo JSON contendo `amount_cents` e `reference`, um cabeçalho
`idempotency-key`, uma resposta esperada em até dois segundos, e **qualquer coisa diferente de `201`
tratada como falha**. Essa última regra volta na seção 06.

Em `~/boxoffice`, abra um arquivo novo e salve como `payments-stub.mjs`:

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

O painel de controle dele são quatro requisições, separadas do endereço do próprio provedor por nomes
que começam com dois sublinhados, uma convenção comum para "isto pertence ao substituto, não à coisa
que ele imita":

| requisição | faz |
|---|---|
| `POST /charges` | registra a cobrança e responde como o modo atual manda |
| `PUT /__mode` | troca o modo; o corpo é o nome do modo |
| `GET /__requests` | as cobranças recebidas até agora, da mais antiga para a mais nova |
| `DELETE /__requests` | esquece todas |

## O boxoffice, apontado para ele

Inicie o stub num terminal só dele, a partir de `~/boxoffice`:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
```

Depois pare o boxoffice com Ctrl-C no terminal dele e inicie de novo com a variável definida.
**Nada no boxoffice muda além de um endereço**, e a graça está toda aí:

```
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Peça um token do jeito que a lição 1 pediu e faça um pedido de dois lugares do sh-101:

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

`"payment": "ch-1"`: o id veio do stub, então a chamada aconteceu. O stub também mostra o que o
boxoffice mandou:

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

Essa é a observação que o provedor de verdade nunca daria a você. O valor são dois lugares a 8000
centavos, a referência é o id do pedido, e **a chave de idempotência também é o id do pedido**, porque
a requisição não trouxe um `Idempotency-Key` próprio; o código do boxoffice diz `key || id`. A lição
13 é sobre essa chave.

## Uma falha, sob encomenda

Ponha o stub para recusar e faça o mesmo pedido:

```
ana@laptop:~/boxoffice$ curl -s -X PUT localhost:8090/__mode -d decline
{"mode":"decline"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}'
{"type":"about:blank","title":"Payment Required","status":402,"detail":"the payment was declined"}
```

`402 Payment Required`, que é a resposta do boxoffice para uma cobrança recusada, e preparar um teste
disso custou uma requisição. O terminal do stub guardou uma linha para cada requisição, com o modo em
que ele estava:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
POST /charges 201 (approve)
GET /__requests 200 (approve)
PUT /__mode 200 (decline)
POST /charges 201 (decline)
```

Os outros dois modos, `slow` e `down`, fazem o boxoffice responder `504` e `502`; a lição 13 testa
os dois, e o que um pedido que falhou deixa para trás. Um substituto que confiasse na própria
configuração seria uma falha silenciosa esperando para acontecer, então este recusa um modo que não
conhece, antes de escutar qualquer coisa:

```
ana@laptop:~/boxoffice$ MODE=declined node payments-stub.mjs
MODE must be one of approve, decline, slow, down, not "declined"
```

**Um erro de digitação no modo aprovaria toda cobrança**, e o teste feito para ver uma recusa
passaria sem testar nada. As lições 12 e 13 iniciam o stub de novo, então guarde o arquivo.
