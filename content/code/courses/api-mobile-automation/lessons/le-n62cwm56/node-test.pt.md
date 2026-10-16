---
title: Testes em Node puro, com node:test
version: 1
---

**O Node 22 traz o próprio executor de testes e as próprias asserções, então um teste de API não
precisa de nada instalado.** O `node:test` encontra os arquivos de teste, roda e relata. O
`node:assert` compara o que voltou com o que era esperado. O `fetch`, embutido no Node desde a versão
18, manda as requisições. Jest, Mocha e Vitest são frameworks populares, e acrescentam modo de
observação, mocks de módulos e arquivos de snapshot. Um teste que conversa com um servidor por HTTP
não usa nada disso. Por isso esta lição e a próxima usam o que o Node já tem, e toda linha dos testes
aparece na lição.

## Auxiliares compartilhados

Todo arquivo de teste precisa de um token e precisa fazer pedidos, então isso fica num módulo só. Crie
o diretório com `mkdir ~/boxoffice/tests` e salve como `tests/lib.mjs`:

```js
// tests/lib.mjs: what the test files share. Run the tests from ~/boxoffice.
export const BASE = process.env.BASE_URL || 'http://localhost:8080';
export const STUB = process.env.STUB_URL || 'http://localhost:8090';

// A token for the ci-tests client, from the boxoffice at `base`.
export async function token(base = BASE) {
  const res = await fetch(`${base}/oauth/token`, {
    method: 'POST',
    body: new URLSearchParams({ grant_type: 'client_credentials', client_id: 'ci-tests', client_secret: 'ci-secret' }),
  });
  if (res.status !== 200) throw new Error(`no token from ${base}: ${res.status}`);
  return (await res.json()).access_token;
}

// POST an order and return its status, headers and body.
export async function order(base, bearer, body, headers = {}) {
  const res = await fetch(`${base}/v1/orders`, {
    method: 'POST',
    headers: { authorization: `Bearer ${bearer}`, 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
  return { status: res.status, headers: res.headers, body: await res.json() };
}

// GET a URL and return its status and JSON body.
export async function get(url) {
  const res = await fetch(url);
  return { status: res.status, body: await res.json() };
}
```

`BASE` e `STUB` dizem onde estão os servidores. Uma variável de ambiente pode mudá-los, para os mesmos
testes rodarem contra outra máquina. `token`, `order` e `get` escondem cada um uma requisição e
devolvem aquilo sobre o que um teste afirma: um status, um corpo, às vezes cabeçalhos. **`token`
lança um erro quando não recebe token.** Um teste que seguisse com `undefined` como bearer falharia
três linhas depois, com um 401 que aponta para o lugar errado.

## Um primeiro arquivo de teste

Salve como `tests/shows.test.mjs`:

```js
// tests/shows.test.mjs: the shows, read from the boxoffice at BASE.
import test from 'node:test';
import assert from 'node:assert/strict';
import { BASE, get } from './lib.mjs';

test('the list holds the three shows', async () => {
  const { status, body } = await get(`${BASE}/v1/shows`);
  assert.equal(status, 200);
  assert.deepEqual(body.shows.map((s) => s.id), ['sh-101', 'sh-102', 'sh-103']);
});

test('a show has its price in cents', async () => {
  const { body } = await get(`${BASE}/v1/shows/sh-103`);
  assert.equal(body.price_cents, 6500);
  assert.ok(Number.isInteger(body.seats_left));
});

test('an unknown show is a 404 in problem details', async () => {
  const res = await fetch(`${BASE}/v1/shows/sh-999`);
  assert.equal(res.status, 404);
  assert.equal(res.headers.get('content-type'), 'application/problem+json');
});

test('HEAD answers like GET, without a body', async () => {
  const res = await fetch(`${BASE}/v1/shows/sh-103`, { method: 'HEAD' });
  assert.equal(res.status, 200);
});
```

Cada `test` tem um nome, escrito como uma frase sobre o boxoffice, e uma função `async`. O teste passa
se a função termina e falha se ela lança um erro, e o `assert` lança quando uma comparação não vale. O
`assert/strict` é a variante a usar: o `equal` dele compara com `===`, então `'6500'` não é `6500`. O
último teste é o defeito da lição 1, escrito como teste.

## Rodando

O boxoffice precisa estar rodando, como em toda lição anterior:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

O `node --test` roda os arquivos que você indica, cada um num processo próprio. **Num terminal, o
relatório padrão dele desenha um visto ou um xis ao lado de cada teste.** Este curso pede o reporter
`tap` no lugar. Ele escreve os mesmos resultados em texto puro no Test Anything Protocol, um formato
que o Perl inventou nos anos 1980 e que ferramentas de teste escrevem desde então. Os sistemas de CI
o leem:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/shows.test.mjs
TAP version 13
# Subtest: the list holds the three shows
ok 1 - the list holds the three shows
  ---
  duration_ms: 50.71813
  type: 'test'
  ...
# Subtest: a show has its price in cents
ok 2 - a show has its price in cents
  ---
  duration_ms: 5.27458
  type: 'test'
  ...
# Subtest: an unknown show is a 404 in problem details
ok 3 - an unknown show is a 404 in problem details
  ---
  duration_ms: 3.52822
  type: 'test'
  ...
# Subtest: HEAD answers like GET, without a body
not ok 4 - HEAD answers like GET, without a body
  ---
  duration_ms: 4.604792
  type: 'test'
  location: '/home/ana/boxoffice/tests/shows.test.mjs:24:1'
  failureType: 'testCodeFailure'
  error: |-
    Expected values to be strictly equal:
    
    405 !== 200
    
  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  expected: 200
  actual: 405
  operator: 'strictEqual'
  stack: |-
    TestContext.<anonymous> (file:///home/ana/boxoffice/tests/shows.test.mjs:26:10)
    process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    async Test.run (node:internal/test_runner/test:1054:7)
    async Test.processPendingSubtests (node:internal/test_runner/test:744:7)
  ...
1..4
# tests 4
# suites 0
# pass 3
# fail 1
# cancelled 0
# skipped 0
# todo 0
# duration_ms 193.479738
ana@laptop:~/boxoffice$ echo $?
1
```

Leia de baixo para cima. O resumo diz quatro testes, três passaram, um falhou. **O código de saída é
1**, e é isso que um pipeline lê para ficar vermelho. Acima, cada teste tem uma linha, `ok` ou `not
ok`. A falha traz o que um relatório de defeito precisa: a comparação que falhou (`405 !== 200`), os
valores `expected` e `actual`, e a `location` do teste como arquivo, linha e coluna. O stack trace
abaixo é do próprio Node; a primeira linha dele é a do teste.

## Um defeito conhecido, à vista

O teste de HEAD falha porque o boxoffice está errado, e vai continuar falhando até alguém corrigir o
boxoffice. Deixá-lo vermelho acostuma todo mundo a ignorar uma execução vermelha; apagá-lo perde o
defeito. A resposta do Node é a opção `todo`. O teste continua rodando e o resultado continua no
relatório, mas um todo que falha não reprova a execução. Troque a primeira linha do teste de HEAD por
esta:

```js
test('HEAD answers like GET, without a body', { todo: 'boxoffice answers HEAD with 405, lesson 1' }, async () => {
```

Desta vez o relatório vai para um arquivo, `shows.tap`, e o `grep` separa as linhas que valem a
leitura:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/shows.test.mjs > shows.tap
ana@laptop:~/boxoffice$ echo $?
0
ana@laptop:~/boxoffice$ grep -E '^(not )?ok|^# (pass|fail|todo)' shows.tap
ok 1 - the list holds the three shows
ok 2 - a show has its price in cents
ok 3 - an unknown show is a 404 in problem details
not ok 4 - HEAD answers like GET, without a body # TODO boxoffice answers HEAD with 405, lesson 1
# pass 3
# fail 0
# todo 1
```

**Código de saída 0, e o defeito continua no relatório**, marcado `# TODO` com o motivo escrito ao
lado. No dia em que o HEAD for corrigido, essa linha vira `ok … # TODO`. Esse é o sinal para tirar a
opção.
