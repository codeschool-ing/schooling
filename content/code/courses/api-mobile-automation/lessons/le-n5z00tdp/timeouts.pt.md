---
title: O que um timeout diz, e o que não diz
version: 1
---

**Um timeout não é uma falha. É a ausência de uma resposta, e a requisição pode muito bem ter dado
certo.** O boxoffice espera dois segundos pelo provedor, como a função `charge` dele diz com
`AbortSignal.timeout(2000)`, e então desiste e responde `504`. Desistir é o certo para um servidor,
porque um cliente esperando para sempre é pior que um cliente que ouve "não deu tempo". Mas desistir não desfaz nada do outro lado.

## Um provedor que responde tarde demais

O modo `slow` do stub aprova a cobrança depois de três segundos, um a mais do que o boxoffice espera.
O `-w` do curl imprime o status e o tempo total da requisição:

```
ana@laptop:~/boxoffice$ curl -s -X PUT localhost:8090/__mode -d slow
{"mode":"slow"}
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":4}'
504 2.005139
```

`504` depois de pouco mais de dois segundos: o prazo do próprio boxoffice, não o do stub. Agora olhe o
outro lado, depois que o stub terminou:

```
ana@laptop:~/boxoffice$ curl -s localhost:8090/__requests | jq -c '.[]'
{"idempotency_key":"ord-1006","amount_cents":26000,"reference":"ord-1006"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left
4
```

**O provedor recebeu a cobrança, e o boxoffice liberou os lugares.** O log do stub diz como terminou:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
POST /charges 201 (approve)
GET /__requests 200 (approve)
PUT /__mode 200 (decline)
POST /charges 201 (decline)
PUT /__mode 200 (down)
POST /charges 500 (down)
PUT /__mode 200 (approve)
DELETE /__requests 204 (approve)
POST /charges 201 (approve)
POST /charges 201 (approve)
GET /__requests 200 (approve)
DELETE /__requests 204 (approve)
PUT /__mode 200 (slow)
POST /charges the caller hung up first (slow)
GET /__requests 200 (slow)
```

`the caller hung up first`: o stub registrou a cobrança quando ela chegou. Ele a aprovou um segundo
depois de o boxoffice parar de escutar. Com um provedor de verdade, isso é um cliente cobrado por um
pedido que o app relatou como falho. **Esta é a falha mais cara da lição, e nenhum status a revela.** A única parte que sabia o resultado já tinha sido deixada falando sozinha.

## O que um teste deve afirmar

Um teste de timeout pode conferir quatro coisas, e a quarta é a que precisa de outro serviço:

- o status, `504`, e o corpo de problema dele;
- a duração, contra uma janela em volta do prazo do servidor: pelo menos 1,9 segundo, porque um `504`
  muito mais rápido quer dizer que o prazo não é o que diz ser, e menos de 3, porque um muito mais
  lento quer dizer que ele não é cumprido;
- o estado: os lugares estão livres de novo;
- o outro lado: o provedor recebeu uma cobrança, então o resultado real do pedido é desconhecido, e
  não falho.

O teste também precisa de um prazo próprio. Se o timeout do boxoffice estivesse quebrado, a requisição
ficaria pendurada, e um teste sem limite ficaria junto. A opção `{ timeout: 5000 }` do node reprova o
teste depois de cinco segundos. Salve como `tests/timeout.test.mjs`:

```js
// tests/timeout.test.mjs: a provider that answers too late.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order, get } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8187';
const STUB = 'http://localhost:8197';
const stops = [];
let bearer;

before(async () => {
  stops.push(await start('payments-stub.mjs', { PORT: '8197', MODE: 'slow' }));
  stops.push(await start('boxoffice.mjs', { PORT: '8187', PAYMENTS_URL: STUB }));
  bearer = await token(BASE);
});
after(() => Promise.all(stops.map((stop) => stop())));

test('a slow provider is a 504 after about two seconds', { timeout: 5000 }, async () => {
  const started = performance.now();
  const placed = await order(BASE, bearer, { show_id: 'sh-103', seats: 4 });
  const took = performance.now() - started;
  assert.equal(placed.status, 504);
  assert.ok(took >= 1900 && took < 3000, `took ${Math.round(took)} ms`);
  assert.equal((await get(`${BASE}/v1/shows/sh-103`)).body.seats_left, 4);
  const { body: charges } = await get(`${STUB}/__requests`);
  assert.equal(charges.length, 1, 'the provider received the charge boxoffice gave up on');
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/timeout.test.mjs | grep -E '^(not )?ok|duration_ms|^# (pass|fail)'
ok 1 - a slow provider is a 504 after about two seconds
  duration_ms: 2225.285863
# pass 1
# fail 0
# duration_ms 2358.232913
```

O `performance.now()` mede tempo decorrido com um relógio que nunca pula quando a hora do sistema é
ajustada, o que o `Date.now()` não pode prometer.

## O que um cliente deve fazer com um 504

**Tratá-lo como "desconhecido", nunca como "falhou".** Os movimentos seguros vêm do resto da lição. Um é
repetir a mesma requisição com a mesma chave de idempotência, para que, se a primeira tentativa tiver
passado, a repetição a encontre. O outro é perguntar ao servidor o estado do pedido antes de dizer
qualquer coisa ao usuário. Os dois dependem de o servidor cumprir a promessa. O boxoffice só lembra uma chave
depois que uma cobrança dá certo, então uma repetição depois do `504` dele faz um pedido novo. Ele repassa, sim, a chave do cliente ao
provedor, o único lugar capaz de reconhecer a repetição. O stub daqui não reconhece. Um provedor de verdade que respeita chaves de idempotência responderia a segunda
cobrança com a primeira. Essa corrente, da chave do cliente ao servidor e ao provedor, é o que quem
testa segue de ponta a ponta quando a palavra *timeout* aparece num relatório.
