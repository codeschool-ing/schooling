---
title: Um teste que atravessa dois serviços
version: 1
---

**Um teste de integração confere que dois programas concordam, então precisa olhar para os dois.** Um
teste de pedido que lê só a resposta do boxoffice prova que o boxoffice disse `201`. Ele não prova que
a cobrança foi feita, feita uma vez só, ou feita no valor certo, e cada uma dessas é um jeito de os
dois programas discordarem enquanto a resposta do boxoffice parece perfeita. O stub de pagamentos da
lição 11 registra toda cobrança que recebe, então um teste consegue ler o outro lado também.

## O arquivo de teste

Ele precisa dos dois servidores rodando e conversa com os dois. Salve como `tests/payments.test.mjs`:

```js
// tests/payments.test.mjs: boxoffice and the payments stub, together.
// Needs both running: the stub on STUB, and boxoffice on BASE with
// PAYMENTS_URL pointing at it.
import { test, before, beforeEach, after } from 'node:test';
import assert from 'node:assert/strict';
import { BASE, STUB, token, order, get } from './lib.mjs';

const mode = (name) => fetch(`${STUB}/__mode`, { method: 'PUT', body: name });
let bearer;

before(async () => { bearer = await token(); });
beforeEach(async () => {
  await fetch(`${STUB}/__requests`, { method: 'DELETE' });
  await mode('approve');
});
after(() => mode('approve'));

test('an order is charged once, for its total', async () => {
  const placed = await order(BASE, bearer, { show_id: 'sh-102', seats: 1 });
  assert.equal(placed.status, 201);
  const { body: charges } = await get(`${STUB}/__requests`);
  assert.equal(charges.length, 1);
  assert.equal(charges[0].amount_cents, 8000);
  assert.equal(charges[0].reference, placed.body.id);
});

test('a declined charge is a 402, and the order is refused', async () => {
  await mode('decline');
  const placed = await order(BASE, bearer, { show_id: 'sh-102', seats: 1 });
  assert.equal(placed.status, 402);
  assert.equal(placed.body.detail, 'the payment was declined');
});
```

Três hooks mantêm os testes separados, e cada um está ali por um motivo que os testes mostrariam
falhando:

| hook | roda | por quê |
|---|---|---|
| `before` | uma vez, antes do primeiro teste | um token basta para o arquivo inteiro |
| `beforeEach` | antes de cada teste | cada teste começa com o registro vazio e o stub aprovando, seja o que for que o teste anterior fez |
| `after` | uma vez, depois do último teste | o stub fica aprovando para quem o usar em seguida |

O primeiro teste é o que uma tela nunca conseguiria rodar: **uma cobrança, de 8000 centavos, cuja
referência é o id do pedido.** O segundo põe o stub para recusar e confere o lado do boxoffice. Um
teste que trocasse o modo do stub e não o devolvesse deixaria o teste seguinte, neste arquivo ou em
outro, rodando contra um provedor que recusa tudo.

## Rodando

Inicie o stub num terminal só dele e reinicie o boxoffice com o `PAYMENTS_URL` definido, como na lição
11:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Depois rode o arquivo; o `grep` fica com as linhas de resultado e o resumo:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/payments.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - an order is charged once, for its total
ok 2 - a declined charge is a 402, and the order is refused
# pass 2
# fail 0
# todo 0
```

O terminal do stub mostra a conversa pelo outro lado, em ordem:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
DELETE /__requests 204 (approve)
PUT /__mode 200 (approve)
POST /charges 201 (approve)
GET /__requests 200 (approve)
DELETE /__requests 204 (approve)
PUT /__mode 200 (approve)
PUT /__mode 200 (decline)
POST /charges 201 (decline)
PUT /__mode 200 (approve)
```

Leia contra os hooks: o `DELETE` e o `PUT` antes de cada teste, a cobrança, a leitura do registro pelo
primeiro teste, e o `PUT` de volta para `approve` no final. Quando um teste de integração falha e a
própria mensagem não basta, **os logs dos dois serviços, lado a lado**, são onde a resposta está.
