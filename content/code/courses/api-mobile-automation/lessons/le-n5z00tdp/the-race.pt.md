---
title: A corrida na idempotência do boxoffice
version: 1
---

**Uma chave de idempotência protege contra uma requisição mandada de novo mais tarde. Se ela protege
contra a mesma requisição mandada duas vezes ao mesmo tempo é outra pergunta, e muitas vezes a
resposta é não.** Um toque duplo num celular lento, ou uma repetição que dispara enquanto a primeira
tentativa ainda está em andamento, manda duas requisições idênticas com poucos milissegundos de
diferença. A seção 02 mostrou o boxoffice repetindo certo quando a segunda requisição veio depois de a
primeira terminar. Esta seção manda as duas juntas.

## Duas ao mesmo tempo

No bash, o `&` põe um comando em segundo plano, então um laço que termina cada `curl` com `&` inicia os
dois antes de qualquer um terminar, e o `wait` espera os dois. Antes, o stub voltou a aprovar e teve o
registro esvaziado:

```
ana@laptop:~/boxoffice$ for i in 1 2; do curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -H 'idempotency-key: tap-tap' -d '{"show_id":"sh-102","seats":1}' & done; wait
{"id":"ord-1004","show_id":"sh-102","seats":1,"total_cents":8000,"status":"confirmed","payment":"ch-3"}
{"id":"ord-1005","show_id":"sh-102","seats":1,"total_cents":8000,"status":"confirmed","payment":"ch-4"}
ana@laptop:~/boxoffice$ curl -s localhost:8090/__requests | jq -c '.[]'
{"idempotency_key":"tap-tap","amount_cents":8000,"reference":"ord-1004"}
{"idempotency_key":"tap-tap","amount_cents":8000,"reference":"ord-1005"}
```

**Dois pedidos, dois ids, e duas cobranças com a mesma chave de idempotência.** A chave deveria
transformar a segunda requisição numa repetição, e não fez nada. Um cliente que tocou duas vezes em
*Comprar* pagou duas vezes.

## Por que acontece

O código do boxoffice mostra isso no `createOrder`: a resposta só é lembrada com `replies.set(...)`
depois que a cobrança voltou. Até lá, uma segunda requisição com a mesma chave não encontra nada
lembrado e faz todo o trabalho de novo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 262\" role=\"img\" aria-label=\"Duas requisições com a mesma chave, lado a lado, B começando um instante depois de A. Cada uma pergunta se a chave está lembrada e ouve não, cria um pedido, ord-1001 para A e ord-1002 para B, cobra no provedor, e só então lembra a chave. Uma barra marca a janela, de A conferir a chave até A lembrá-la, enquanto a cobrança está em andamento; B conferiu dentro dela.\"><defs><marker id=\"f13race-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"200\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">requisição A</text><text x=\"500\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">requisição B, mesma chave</text><rect x=\"110\" y=\"38\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">chave lembrada? não</text><line x1=\"200\" y1=\"74\" x2=\"200\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"110\" y=\"90\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cria um pedido</text><text x=\"200\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">ord-1001</text><line x1=\"200\" y1=\"126\" x2=\"200\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"110\" y=\"142\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cobra no provedor</text><line x1=\"200\" y1=\"178\" x2=\"200\" y2=\"192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"110\" y=\"194\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lembra a chave</text><rect x=\"410\" y=\"64\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">chave lembrada? não</text><line x1=\"500\" y1=\"100\" x2=\"500\" y2=\"114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"410\" y=\"116\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cria um pedido</text><text x=\"500\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">ord-1002</text><line x1=\"500\" y1=\"152\" x2=\"500\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"410\" y=\"168\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cobra no provedor</text><line x1=\"500\" y1=\"204\" x2=\"500\" y2=\"218\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"410\" y=\"220\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lembra a chave</text><line x1=\"40\" y1=\"30\" x2=\"40\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><text x=\"48\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo</text><rect x=\"318\" y=\"38\" width=\"6\" height=\"192\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"324\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">a janela: a cobrança em andamento</text></svg>", "caption": "As duas requisições conferem a chave antes de qualquer uma lembrá-la, então as duas fazem todo o trabalho."}
```

A janela é o tempo que a cobrança leva, alguns milissegundos contra um stub local e muito mais contra
um provedor de verdade, então **o defeito fica pior em produção do que em qualquer teste**. O teste de
repetição da seção 02 passou porque as duas requisições dele eram sequenciais, e nenhuma quantidade de
testes sequenciais teria achado isto.

## O teste que o mantém à vista

O `Promise.all` inicia as duas requisições antes de esperar qualquer uma, que é o toque duplo em
código. O teste afirma o que deveria ser verdade, uma cobrança e um pedido, e leva a opção `todo` da
lição 12, porque o defeito é conhecido e não está corrigido. Salve como `tests/race.test.mjs`:

```js
// tests/race.test.mjs: two requests with one key, at the same moment.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order, get } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8186';
const STUB = 'http://localhost:8196';
const stops = [];
let bearer;

before(async () => {
  stops.push(await start('payments-stub.mjs', { PORT: '8196' }));
  stops.push(await start('boxoffice.mjs', { PORT: '8186', PAYMENTS_URL: STUB }));
  bearer = await token(BASE);
});
after(() => Promise.all(stops.map((stop) => stop())));

test('two requests with one key make one order', { todo: 'boxoffice makes two: the race of lesson 13' }, async () => {
  const key = { 'idempotency-key': 'double-tap' };
  const body = { show_id: 'sh-102', seats: 1 };
  const [a, b] = await Promise.all([order(BASE, bearer, body, key), order(BASE, bearer, body, key)]);
  const { body: charges } = await get(`${STUB}/__requests`);
  assert.equal(charges.length, 1, `charged ${charges.length} times`);
  assert.equal(a.body.id, b.body.id);
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/race.test.mjs
TAP version 13
# Subtest: two requests with one key make one order
not ok 1 - two requests with one key make one order # TODO boxoffice makes two: the race of lesson 13
  ---
  duration_ms: 196.281567
  type: 'test'
  location: '/home/ana/boxoffice/tests/race.test.mjs:19:1'
  failureType: 'testCodeFailure'
  error: |-
    charged 2 times
    
    2 !== 1
    
  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  expected: 1
  actual: 2
  operator: 'strictEqual'
  stack: |-
    TestContext.<anonymous> (file:///home/ana/boxoffice/tests/race.test.mjs:24:10)
    process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    async Test.run (node:internal/test_runner/test:1054:7)
    async startSubtestAfterBootstrap (node:internal/test_runner/harness:296:3)
  ...
1..1
# tests 1
# suites 0
# pass 0
# fail 0
# cancelled 0
# skipped 0
# todo 1
# duration_ms 315.525839
```

`not ok … # TODO`, com a evidência na falha: `charged 2 times`. A execução passa, então a suíte
continua utilizável, e o relatório diz em toda execução que o defeito ainda está lá.

## O relatório

| | |
|---|---|
| **título** | Dois pedidos simultâneos com o mesmo Idempotency-Key dão certo e cobram os dois |
| **passos** | mandar dois `POST /v1/orders` idênticos com o mesmo `Idempotency-Key`, o segundo antes de o primeiro responder |
| **esperado** | um pedido; a segunda requisição responde com o resultado da primeira, ou com `409` enquanto a primeira está em andamento |
| **obtido** | dois pedidos com ids diferentes, os dois confirmados; o provedor recebe duas cobranças com a mesma chave |
| **evidência** | a transcrição acima, e o `tests/race.test.mjs` |
| **impacto** | um cliente que toca duas vezes paga duas vezes; a janela cresce com o tempo de resposta do provedor |

**A correção é reservar a chave antes de fazer o trabalho.** Na primeira requisição, registre a chave
como "em andamento" no mesmo passo que a confere, para que uma segunda requisição com essa chave a
encontre ocupada e espere a primeira resposta ou ouça `409 Conflict` para tentar de novo em
instantes, que é o que o rascunho da IETF sobre chaves de idempotência sugere. No boxoffice isso são
poucas linhas; num serviço com várias cópias rodando, a reserva precisa ser atômica num armazenamento
compartilhado, como uma inserção numa tabela em que a chave é única. Seja como for, o teste acima é
como a correção vai ser conferida: no dia em que ele passar, tire o `todo`.
