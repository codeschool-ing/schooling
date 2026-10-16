---
title: Chaves de idempotência
version: 1
---

**Um `POST` mandado duas vezes faz a coisa duas vezes, e o cliente nem sempre sabe se o primeiro
chegou.** A lição 1 disse que o `POST` não é seguro nem idempotente. Num celular que perde o sinal no
meio do *Comprar*, o app não vê resposta e tem duas escolhas ruins: mandar de novo e talvez comprar
dois ingressos, ou desistir e talvez não comprar nenhum, dizendo ao usuário que falhou. Uma chave de
idempotência desfaz o dilema. O cliente inventa uma chave para uma intenção, "comprar estes dois
lugares", e a manda em toda tentativa daquela intenção; o servidor faz o trabalho na primeira vez e,
para a mesma chave, responde toda tentativa seguinte com uma cópia da primeira resposta.

O boxoffice suporta isso pelo cabeçalho `Idempotency-Key`, o nome que um rascunho da IETF padroniza e
que a Stripe, entre outros provedores de pagamento, usa. A chave é escolha do cliente; um UUID
aleatório é o de costume, e qualquer string que ninguém mais vá usar serve.

## Uma repetição

Inicie o stub e o boxoffice como na lição 12, em terminais só deles, e pegue um token:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

Depois o mesmo pedido duas vezes, com a mesma chave. Na segunda vez, o `-i` mostra os cabeçalhos
também:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -H 'idempotency-key: buy-7f3a' -d '{"show_id":"sh-101","seats":2}'
{"id":"ord-1001","show_id":"sh-101","seats":2,"total_cents":16000,"status":"confirmed","payment":"ch-1"}
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -H 'idempotency-key: buy-7f3a' -d '{"show_id":"sh-101","seats":2}'
HTTP/1.1 201 Created
content-type: application/json
location: /v1/orders/ord-1001
idempotent-replayed: true
Date: Fri, 16 Oct 2026 01:14:20 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"id":"ord-1001","show_id":"sh-101","seats":2,"total_cents":16000,"status":"confirmed","payment":"ch-1"}
```

**O mesmo pedido, `ord-1001`, as duas vezes**, e na segunda resposta um cabeçalho a mais do que um
`201` comum traz: `idempotent-replayed: true`, que diz que esta resposta é uma cópia. Nenhum segundo
pedido foi criado. Uma chave representa uma intenção, então o boxoffice também confere que uma
repetição é mesmo a mesma requisição:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -H 'idempotency-key: buy-7f3a' -d '{"show_id":"sh-101","seats":3}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"this Idempotency-Key was used with a different body"}
```

`422`: uma chave reaproveitada para outro pedido é um defeito do cliente, e repetir em silêncio a
resposta antiga diria ao cliente que ele comprou três lugares quando comprou dois. O stub mostra a
outra metade da promessa, **uma cobrança para a chave**:

```
ana@laptop:~/boxoffice$ curl -s localhost:8090/__requests | jq -c '.[]'
{"idempotency_key":"buy-7f3a","amount_cents":16000,"reference":"ord-1001"}
```

## Como teste

Um teste de idempotência precisa olhar os dois lados, como o teste de integração da lição 12 fez: as
respostas do boxoffice e o número de cobranças. Ele inicia o próprio boxoffice e o próprio stub, em
portas que ninguém mais usa, para as contagens serem dele. Salve como `tests/idempotency.test.mjs`:

```js
// tests/idempotency.test.mjs: the same Idempotency-Key, sent again.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order, get } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8184';
const STUB = 'http://localhost:8194';
const stops = [];
let bearer;

before(async () => {
  stops.push(await start('payments-stub.mjs', { PORT: '8194' }));
  stops.push(await start('boxoffice.mjs', { PORT: '8184', PAYMENTS_URL: STUB }));
  bearer = await token(BASE);
});
after(() => Promise.all(stops.map((stop) => stop())));

test('a replay gets the first answer, and nothing is charged twice', async () => {
  const key = { 'idempotency-key': 'replay-1' };
  const first = await order(BASE, bearer, { show_id: 'sh-101', seats: 2 }, key);
  const again = await order(BASE, bearer, { show_id: 'sh-101', seats: 2 }, key);
  assert.equal(first.status, 201);
  assert.equal(again.status, 201);
  assert.deepEqual(again.body, first.body);
  assert.equal(again.headers.get('idempotent-replayed'), 'true');
  const { body: charges } = await get(`${STUB}/__requests`);
  assert.equal(charges.filter((c) => c.idempotency_key === 'replay-1').length, 1);
});

test('the same key with a different body is refused', async () => {
  const key = { 'idempotency-key': 'replay-2' };
  await order(BASE, bearer, { show_id: 'sh-101', seats: 1 }, key);
  const other = await order(BASE, bearer, { show_id: 'sh-101', seats: 3 }, key);
  assert.equal(other.status, 422);
  assert.equal(other.body.detail, 'this Idempotency-Key was used with a different body');
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/idempotency.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - a replay gets the first answer, and nothing is charged twice
ok 2 - the same key with a different body is refused
# pass 2
# fail 0
# todo 0
```

O que quem testa confere numa chave de idempotência, além destes dois testes: que a repetição traz o
mesmo status e os mesmos cabeçalhos, e não só o mesmo corpo; que as chaves pertencem a um cliente, então
outro cliente que mande a mesma chave ganha um pedido próprio e nunca o seu (o boxoffice as guarda pelo
`sub` do token); e por quanto tempo as chaves são lembradas. O boxoffice as lembra até reiniciar, e um
serviço de verdade documenta um período, muitas vezes um dia, depois do qual a mesma chave faz um
pedido novo.
