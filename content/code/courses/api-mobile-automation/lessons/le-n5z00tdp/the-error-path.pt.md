---
title: Testando o caminho do erro de propósito
version: 1
---

**A maioria dos testes confere que as coisas funcionam, e a maior parte do dinheiro se perde onde elas
não funcionam.** Pense nos caminhos em que o pagamento é recusado, o provedor está fora do ar ou o provedor demora.
Eles rodam raramente no desenvolvimento e todo dia em produção, e ninguém os vê até um cliente ver.
Eles também são os mais fáceis de testar quando um substituto falha sob encomenda, que é para o que
serve o stub da lição 11.

Cada caminho de erro pede as mesmas três conferências: a resposta que o cliente recebe, o
status e o corpo; o estado que fica para trás, aqui os lugares; e o que o outro serviço viu.

## Uma recusa, e um provedor fora do ar

Ponha o stub para recusar e peça os quatro lugares do sh-103, depois olhe os lugares:

```
ana@laptop:~/boxoffice$ curl -s -X PUT localhost:8090/__mode -d decline
{"mode":"decline"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":4}'
{"type":"about:blank","title":"Payment Required","status":402,"detail":"the payment was declined"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left
4
```

`402`, e os quatro lugares ainda livres: o pedido recusado não segurou nenhum. O provedor fora do ar,
o mesmo pedido:

```
ana@laptop:~/boxoffice$ curl -s -X PUT localhost:8090/__mode -d down
{"mode":"down"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":4}'
{"type":"about:blank","title":"Bad Gateway","status":502,"detail":"the payment provider failed"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left
4
```

`502`, *the payment provider failed*, no mesmo formato de problema de todo outro erro, e de novo
quatro lugares. As duas respostas estão certas para um cliente. O `402` diz para pedir outro cartão ao usuário; o
`502` diz que a culpa é do lado do servidor e que repetir pode ajudar.

## O que um pedido que falhou deixa para trás

O boxoffice criou um pedido antes de cobrar, `ord-1003` para o provedor fora do ar, e o manteve
quando a cobrança falhou. Peça por ele:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders/ord-1003 -H "authorization: Bearer $TOKEN"
{"id":"ord-1003","show_id":"sh-103","seats":4,"total_cents":26000,"status":"failed"}
```

**Um pedido com status `failed`, do qual o cliente nunca ficou sabendo**: o `502` não trazia id
nenhum. Isso é uma constatação que vale registrar, mais do que um defeito com resposta pronta. O
registro é útil para o teatro, que consegue ver vendas que falharam. Mas um cliente que quer conciliar não tem como ligá-lo à
requisição que o criou, e nem alguém do suporte respondendo "fui cobrado?". Quem testa levanta isso como pergunta: o id de um pedido que falhou deveria estar no erro, ou o
pedido não deveria existir?

O fim do terminal do boxoffice mostra tudo pelo lado dele. A recusa é um `402` comum. O provedor fora do ar deixou uma linha a mais, a que o boxoffice imprime quando captura uma cobrança que falhou:

```
POST /v1/orders 402
GET /v1/shows/sh-103 200
  payments: payments answered 500
POST /v1/orders 502
GET /v1/shows/sh-103 200
GET /v1/orders/ord-1003 200
```

## Como testes

Um arquivo, com o próprio boxoffice e o próprio stub. Os dois caminhos de erro dividem um corpo de
teste num laço, porque só diferem no modo, no status e no detalhe. O último teste prova que, depois
das duas falhas, os quatro lugares ainda podem ser vendidos. Salve como `tests/errors.test.mjs`:

```js
// tests/errors.test.mjs: what boxoffice does when the payment goes wrong.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order, get } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8185';
const STUB = 'http://localhost:8195';
const stops = [];
let bearer;

const mode = (name) => fetch(`${STUB}/__mode`, { method: 'PUT', body: name });
const seatsLeft = async () => (await get(`${BASE}/v1/shows/sh-103`)).body.seats_left;

before(async () => {
  stops.push(await start('payments-stub.mjs', { PORT: '8195' }));
  stops.push(await start('boxoffice.mjs', { PORT: '8185', PAYMENTS_URL: STUB }));
  bearer = await token(BASE);
});
after(() => Promise.all(stops.map((stop) => stop())));

for (const [name, status, detail] of [
  ['decline', 402, 'the payment was declined'],
  ['down', 502, 'the payment provider failed'],
]) {
  test(`${name}: ${status}, and the seats are not held`, async () => {
    await mode(name);
    const before = await seatsLeft();
    const placed = await order(BASE, bearer, { show_id: 'sh-103', seats: 4 });
    assert.equal(placed.status, status);
    assert.equal(placed.body.detail, detail);
    assert.equal(placed.headers.get('content-type'), 'application/problem+json');
    assert.equal(await seatsLeft(), before);
  });
}

test('after the failures, all four seats can still be sold', async () => {
  await mode('approve');
  const placed = await order(BASE, bearer, { show_id: 'sh-103', seats: 4 });
  assert.equal(placed.status, 201);
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/errors.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - decline: 402, and the seats are not held
ok 2 - down: 502, and the seats are not held
ok 3 - after the failures, all four seats can still be sold
# pass 3
# fail 0
# todo 0
```

**As conferências de lugares são o que pega uma classe real de defeito**: um caminho de erro que
esquece de liberar o que reservou. O boxoffice segura os lugares enquanto cobra e precisa devolvê-los
em toda falha. Se um caminho esquecesse disso, o status dele continuaria certo. Só a contagem de
lugares, ou a venda do último teste, mostraria um espetáculo perdendo lugares que nunca vendeu.
