---
title: A API debaixo de uma rede ruim
version: 1
---

**Uma rede ruim faz o estrago de verdade nas requisições que mudam alguma coisa.** Uma resposta
perdida a um `GET` custa uma nova tentativa. Uma resposta perdida a um `POST` que comprou um ingresso
deixa o cliente sem saber se comprou. As ferramentas da lição 13 para isso, chaves de idempotência
e novas tentativas, foram testadas lá contra falhas que o stub produzia quando pedido. Aqui a falha é
da rede, em dois lugares: do lado do cliente do boxoffice e do lado do próprio boxoffice, rumo ao
provedor de pagamento.

## Uma resposta perdida, sem chave

Primeiro um token, como na lição 3:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

Reinicie o proxy perdendo metade das respostas, a partir da semente 7, cujos dois primeiros sorteios
perdem. Depois o laço que todo cliente impaciente é. Ele tenta comprar um lugar do `sh-103`, e
tenta de novo enquanto nenhuma resposta vem, três vezes:

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

O código 52 do curl, *resposta vazia*, duas vezes, depois um pedido confirmado. O cliente viu uma
compra. **O espetáculo tinha quatro lugares e tem um**: cada resposta perdida foi um pedido que o
boxoffice fez e de que o cliente nunca soube. Nada na saída do cliente diz isso. Só o estado do
servidor diz, e é por isso que um teste disso precisa lê-lo.

## O mesmo, com chave

Reinicie o proxy com a mesma semente, para ele perder as mesmas duas respostas. Depois o mesmo laço,
com uma única `Idempotency-Key` para as três tentativas, no `sh-102` desta vez:

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

Duas respostas vazias de novo, depois um `201` marcado `idempotent-replayed: true`. O pedido que o
cliente recebe é o que a primeira tentativa fez, e o `sh-102` perdeu um lugar dos 120. O log do proxy
mostra que toda tentativa chegou ao boxoffice e foi respondida com `201`:

```
ana@laptop:~/boxoffice$ DROP=0.5 SEED=7 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE unlimited B/s, DROP 0.5, SEED 7
1 POST /v1/orders 201, answer dropped
2 POST /v1/orders 201, answer dropped
3 POST /v1/orders 201, answer sent
```

**A chave transformou três requisições em uma compra, e a rede nunca precisou ser consertada.** Esse
é o argumento inteiro a favor das chaves de idempotência num celular, onde respostas perdidas são um
dia comum e não uma pane.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 226\" role=\"img\" aria-label=\"Três tentativas de uma compra por um proxy que perde as duas primeiras respostas. O cliente vê o erro 52 do curl duas vezes e depois um 201. Sem chave, o boxoffice fez um pedido novo a cada tentativa, ord-1001, ord-1002 e ord-1003: três lugares a menos e um comprado. Com chave, a primeira tentativa fez o ord-1004 e as duas seguintes foram replays dele: um lugar a menos, um comprado.\"><text x=\"190\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que o cliente viu</text><text x=\"380\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">boxoffice, sem chave</text><text x=\"570\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">boxoffice, com chave</text><text x=\"60\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tentativa 1</text><rect x=\"110\" y=\"52\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">curl: (52)</text><rect x=\"300\" y=\"52\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ord-1001</text><text x=\"380\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">um pedido novo</text><rect x=\"490\" y=\"52\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ord-1004</text><text x=\"570\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">um pedido novo</text><text x=\"60\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tentativa 2</text><rect x=\"110\" y=\"102\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">curl: (52)</text><rect x=\"300\" y=\"102\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ord-1002</text><text x=\"380\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">um pedido novo</text><rect x=\"490\" y=\"102\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">replay do ord-1004</text><text x=\"570\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o mesmo pedido</text><text x=\"60\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tentativa 3</text><rect x=\"110\" y=\"152\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">201</text><rect x=\"300\" y=\"152\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ord-1003</text><text x=\"380\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">um pedido novo</text><rect x=\"490\" y=\"152\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">replay do ord-1004</text><text x=\"570\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o mesmo pedido</text><text x=\"380\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">três lugares a menos, um comprado</text><text x=\"570\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">um lugar a menos, um comprado</text></svg>", "caption": "O cliente vê os mesmos três resultados nos dois casos. Só o servidor mostra o que as respostas perdidas custaram."}
```

## Como teste

A mesma verificação, escrita com o helper de novas tentativas da lição 13, que tenta de novo uma
requisição que não recebeu resposta nenhuma. O teste inicia o próprio boxoffice e o próprio proxy em
portas que nada mais usa, perdendo metade das respostas a partir da semente 7.
Salve como `tests/poor-network.test.mjs`:

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

As asserções são os três fatos da execução acima: a compra deu certo, a resposta que chegou era um
replay, e exatamente um lugar sumiu. **A última é a asserção que importa.** Ela é feita contra o
próprio boxoffice, `BASE`, não pelo proxy. Uma verificação que também pudesse se perder às
vezes falharia pelo motivo errado.

## O boxoffice num link lento

A outra direção: o boxoffice cobrando o stub de pagamento da lição 11 por um proxy lento. Pare o
boxoffice e o proxy, e inicie três programas em três terminais. O primeiro é o stub. O segundo é
um proxy na porta 8071 que repassa ao stub e segura as respostas dele por 1,5 segundo. O terceiro é
o boxoffice, instruído a cobrar por esse proxy:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
ana@laptop:~/boxoffice$ PORT=8071 TARGET=http://localhost:8090 DELAY=1500 node slow-proxy.mjs
slow proxy listening on http://localhost:8071, forwarding to http://localhost:8090
  DELAY 1500 ms, RATE unlimited B/s, DROP 0, SEED 1
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8071 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Um pedido de dois lugares do `sh-103`, cronometrado:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2}'
201 1.565003
```

Um `201` depois de um segundo e meio, o atraso do proxy. O boxoffice espera até dois segundos pelo
provedor, como a lição 13 mostrou, e 1,5 está dentro disso. Reinicie o segundo proxy com 2,5 segundos, além do
limite, e peça de novo:

```
ana@laptop:~/boxoffice$ PORT=8071 TARGET=http://localhost:8090 DELAY=2500 node slow-proxy.mjs
slow proxy listening on http://localhost:8071, forwarding to http://localhost:8090
  DELAY 2500 ms, RATE unlimited B/s, DROP 0, SEED 1
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2}'
504 2.004330
```

`504` depois de dois segundos. Então, um segundo depois, o outro lado:

```
ana@laptop:~/boxoffice$ curl -s localhost:8090/__requests | jq -c '.[]'
{"idempotency_key":"ord-1001","amount_cents":13000,"reference":"ord-1001"}
{"idempotency_key":"ord-1002","amount_cents":13000,"reference":"ord-1002"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left
2
```

**O stub recebeu as duas cobranças e aprovou as duas.** Enquanto isso, o boxoffice reprovou o segundo
pedido e devolveu os dois lugares dele: o `sh-103` tem dois sobrando, só do primeiro pedido. Os logs
dizem como terminou:

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

O stub respondeu na hora, e o proxy segurou essa resposta até o boxoffice parar de escutar. É o
provedor lento da lição 13 de novo: um cliente cobrado por um pedido que o app chamou de falho. Uma
diferença importa num relato. **Aqui o provedor foi rápido e a rede foi lenta**, e nada de
nenhum dos lados conseguia dizer qual. Olhar os tempos de resposta do próprio provedor o livraria da
culpa, com razão, e o defeito continuaria lá.
