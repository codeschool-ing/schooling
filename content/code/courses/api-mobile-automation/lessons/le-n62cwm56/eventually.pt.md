---
title: Resultados que chegam depois
version: 1
---

**Algumas respostas só ficam certas depois de um tempo, e um teste precisa esperar por elas sem
adivinhar quanto.** O relatório de vendas do boxoffice é uma delas. Ele é refeito em segundo plano,
`REPORT_DELAY` milissegundos depois que um pedido muda, 500 se a variável não disser outra coisa.
Muitos sistemas de verdade se comportam assim: um índice de busca, um cache, um painel alimentado por
uma fila. O nome disso é *consistência eventual*: o relatório vai concordar com os pedidos, só não no
instante em que eles mudam.

## Vendo o atraso

Reinicie o boxoffice para o relatório começar do zero, e pegue um token. Depois faça um pedido e peça
o relatório na mesma linha, para a segunda requisição vir logo depois da primeira:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":3}'; curl -s localhost:8080/v1/reports/sales -H 'x-api-key: lab-only-staff-key'
201
{"orders":0,"seats":0,"revenue_cents":0}
ana@laptop:~/boxoffice$ sleep 1; curl -s localhost:8080/v1/reports/sales -H 'x-api-key: lab-only-staff-key'
{"orders":1,"seats":3,"revenue_cents":24000}
```

O pedido foi criado e o relatório ainda dizia que nada tinha sido vendido. Um segundo depois ele tinha
alcançado. **Um teste que lê o relatório logo depois do pedido falha, embora nada esteja errado** no
boxoffice; quem leu mal a promessa foi o teste.

## Duas correções erradas

A primeira que todo mundo escreve é um sleep: esperar um segundo e então ler. Ela falha duas vezes.
É lenta em toda execução, um segundo inteiro onde meio bastaria, multiplicado por todo teste que faz
isso. E ainda falha no dia em que a máquina está ocupada e a reconstrução leva mais que o segundo. A
suíte então fica vermelha ao acaso num runner de CI carregado, que é o pior tipo de vermelho.

A segunda é parar de conferir: tirar a asserção sobre o relatório porque ela "falha às vezes". Isso
transforma uma promessa real do boxoffice em algo que nenhum teste segura.

## Perguntando de novo, até um prazo

A forma certa é perguntar e, se a resposta ainda não estiver certa, esperar um pouco e perguntar de
novo. Pare num prazo, e falhe com o que ainda estava errado. Escreva isso como um auxiliar, e salve
como `tests/eventually.mjs`:

```js
// tests/eventually.mjs: wait for something that becomes true later.

// Run check() until it stops throwing, every `every` ms, for at most
// `timeout` ms. Then throw the last error, so a failure still says what was
// wrong, and not only that time ran out.
export async function eventually(check, { timeout = 3000, every = 100 } = {}) {
  const deadline = Date.now() + timeout;
  for (;;) {
    try {
      return await check();
    } catch (err) {
      if (Date.now() + every > deadline) throw err;
      await new Promise((wake) => setTimeout(wake, every));
    }
  }
}
```

Três escolhas nele são de propósito. **Ele retorna assim que a conferência passa**, então uma máquina
rápida espera 500 ms e não um segundo fixo. O prazo dele, três segundos por padrão, é generoso, porque
só custa tempo quando algo está quebrado. E **ele lança o último erro de verdade**, não "tempo
esgotado", então uma falha diz que campo estava errado e o que ele tinha.

O teste o usa em volta da asserção que precisa de tempo. Ele inicia o próprio boxoffice, como a seção
04 fez, para os pedidos de nenhum outro teste chegarem ao relatório dele. Salve como
`tests/report.test.mjs`:

```js
// tests/report.test.mjs: the sales report catches up with the orders.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order } from './lib.mjs';
import { start } from './start.mjs';
import { eventually } from './eventually.mjs';

const BASE = 'http://localhost:8183';
const report = async () => (await fetch(`${BASE}/v1/reports/sales`,
  { headers: { 'x-api-key': 'lab-only-staff-key' } })).json();
let stop, bearer;

before(async () => {
  stop = await start('boxoffice.mjs', { PORT: '8183' });
  bearer = await token(BASE);
});
after(() => stop());

test('an order shows up in the sales report', async () => {
  const placed = await order(BASE, bearer, { show_id: 'sh-101', seats: 3 });
  assert.equal(placed.status, 201);
  await eventually(async () => {
    assert.deepEqual(await report(), { orders: 1, seats: 3, revenue_cents: 24000 });
  });
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/report.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - an order shows up in the sales report
# pass 1
# fail 0
# todo 0
```

Passou. Agora deixe a reconstrução mais lenta que o prazo. O boxoffice iniciado pelo teste herda o
ambiente do teste, então o `REPORT_DELAY` na linha de comando chega até ele:

```
ana@laptop:~/boxoffice$ REPORT_DELAY=5000 node --test --test-reporter=tap tests/report.test.mjs > slow.tap
ana@laptop:~/boxoffice$ echo $?
1
ana@laptop:~/boxoffice$ head -30 slow.tap
TAP version 13
# Subtest: an order shows up in the sales report
not ok 1 - an order shows up in the sales report
  ---
  duration_ms: 3132.656154
  type: 'test'
  location: '/home/ana/boxoffice/tests/report.test.mjs:19:1'
  failureType: 'testCodeFailure'
  error: |-
    Expected values to be strictly deep-equal:
    + actual - expected
    
      {
    +   orders: 0,
    +   revenue_cents: 0,
    +   seats: 0
    -   orders: 1,
    -   revenue_cents: 24000,
    -   seats: 3
      }
    
  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  expected:
    orders: 1
    seats: 3
    revenue_cents: 24000
  actual:
    orders: 0
    seats: 0
```

**A falha é a que você quer ler**: código de saída 1, e o relatório ainda tinha zeros quando os três
segundos acabaram. O diff mostra os campos que eram esperados. Um teste que dormisse diria a mesma
coisa sem prazo nenhum a culpar. Um teste que esperasse para sempre não diria nada.
