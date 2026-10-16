---
title: Testes que dependem da ordem
version: 1
---

**Um teste que passa sozinho e falha ao lado de outro tem uma entrada escondida: o que rodou antes
dele.** A crença de costume é que uma falha assim é azar, um teste "instável" para rodar de novo até
ficar verde. Não é azar. Dois testes compartilham algum estado, aqui os lugares de um espetáculo, e o
resultado depende de quem mexeu primeiro. Rodar de novo esconde a causa e a mantém.

## Dois testes que dividem quatro lugares

O sh-103 tem quatro lugares, o que facilita mostrar.
O primeiro teste compra dois deles; salve como `tests/seats.test.mjs`:

```js
// tests/seats.test.mjs: buying seats takes them off the show.
import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { BASE, token, order, get } from './lib.mjs';

let bearer;
before(async () => { bearer = await token(); });

test('two seats of sh-103 leave two', async () => {
  const placed = await order(BASE, bearer, { show_id: 'sh-103', seats: 2 });
  assert.equal(placed.status, 201);
  const { body } = await get(`${BASE}/v1/shows/sh-103`);
  assert.equal(body.seats_left, 2);
});
```

O segundo compra os quatro; salve como `tests/sellout.test.mjs`:

```js
// tests/sellout.test.mjs: a show with no seats left refuses the next order.
import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { BASE, token, order } from './lib.mjs';

let bearer;
before(async () => { bearer = await token(); });

test('sh-103 sells out at four seats', async () => {
  const all = await order(BASE, bearer, { show_id: 'sh-103', seats: 4 });
  assert.equal(all.status, 201);
  const one = await order(BASE, bearer, { show_id: 'sh-103', seats: 1 });
  assert.equal(one.status, 409);
  assert.equal(one.body.detail, 'only 0 seats left');
});
```

Os dois usam o boxoffice em `BASE`, o que está rodando no seu outro terminal, e os dois estão certos
sobre um boxoffice que acabou de iniciar. Reinicie o boxoffice com Ctrl-C e o mesmo comando, para ele
ter um sh-103 novo, e rode o segundo:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/sellout.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - sh-103 sells out at four seats
# pass 1
# fail 0
# todo 0
```

Reinicie o boxoffice de novo e rode o primeiro:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/seats.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - two seats of sh-103 leave two
# pass 1
# fail 0
# todo 0
```

Os dois passam sozinhos. **Agora rode o primeiro uma segunda vez, sem reiniciar:**

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/seats.test.mjs
TAP version 13
# Subtest: two seats of sh-103 leave two
not ok 1 - two seats of sh-103 leave two
  ---
  duration_ms: 26.370324
  type: 'test'
  location: '/home/ana/boxoffice/tests/seats.test.mjs:9:1'
  failureType: 'testCodeFailure'
  error: |-
    Expected values to be strictly equal:
    
    0 !== 2
    
  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  expected: 2
  actual: 0
  operator: 'strictEqual'
  stack: |-
    TestContext.<anonymous> (file:///home/ana/boxoffice/tests/seats.test.mjs:13:10)
    process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    async Test.run (node:internal/test_runner/test:1054:7)
    async startSubtestAfterBootstrap (node:internal/test_runner/harness:296:3)
  ...
1..1
# tests 1
# suites 0
# pass 0
# fail 1
# cancelled 0
# skipped 0
# todo 0
# duration_ms 201.28103
```

`0 !== 2`: a primeira execução vendeu dois lugares, a segunda vendeu os outros dois, e o teste esperava
que sobrassem dois, porque foi escrito como se fosse a única coisa que já tivesse acontecido ao
sh-103. Reinicie o boxoffice mais uma vez e rode os dois, um arquivo por vez com
`--test-concurrency=1`:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap --test-concurrency=1 tests/seats.test.mjs tests/sellout.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - two seats of sh-103 leave two
not ok 2 - sh-103 sells out at four seats
# pass 1
# fail 1
# todo 0
```

O teste de lugares passou e o de esgotamento falhou: ele pediu quatro lugares, e dois já estavam
vendidos. Troque os dois nomes de lugar na linha de comando e nada muda:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap --test-concurrency=1 tests/sellout.test.mjs tests/seats.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - two seats of sh-103 leave two
not ok 2 - sh-103 sells out at four seats
# pass 1
# fail 1
# todo 0
```

**O node ordena os arquivos que recebe**, então `seats` roda antes de `sellout` de qualquer jeito. É
bom saber e não ajuda: a ordem continua sendo um acaso dos nomes, e renomear um arquivo mudaria a
falha de lugar. Sem `--test-concurrency=1`, o Node roda os arquivos em paralelo, um processo cada, e
qual requisição chega primeiro ao sh-103 vira uma corrida entre processos. Os mesmos dois arquivos
podem então passar na sua máquina e falhar numa mais lenta.

## A correção: estado que pertence ao teste

Existem dois remédios, e qual serve depende do que é compartilhado:

| remédio | como | aqui |
|---|---|---|
| **dados únicos por teste** | cada teste cria o que precisa, com um nome que ninguém mais usa: o próprio cliente, o próprio produto | não dá: o boxoffice tem três espetáculos e nenhum jeito de acrescentar um |
| **estado novo por suíte** | cada arquivo de teste ganha um sistema só dele, iniciado limpo e jogado fora | o boxoffice inicia numa fração de segundo e esquece tudo quando para |

Então cada arquivo ganha um boxoffice só dele, numa porta só dele. O `child_process` do Node o
inicia, e um auxiliar espera a linha que diz que ele está escutando. Salve como `tests/start.mjs`:

```js
// tests/start.mjs: a server of the test's own, started and stopped by it.
import { spawn } from 'node:child_process';

// Start `node file` with extra environment variables, and resolve once it
// prints "listening". The value is a function that stops it.
export function start(file, env = {}) {
  const child = spawn(process.execPath, [file], {
    env: { ...process.env, ...env },
    stdio: ['ignore', 'pipe', 'inherit'],
  });
  return new Promise((resolve, reject) => {
    let said = '';
    child.stdout.on('data', (chunk) => {
      said += chunk;
      if (said.includes('listening')) resolve(() => new Promise((done) => {
        child.once('exit', done);
        child.kill();
      }));
    });
    child.once('exit', (code) => reject(new Error(`${file} exited (${code}) before it was listening`)));
  });
}
```

**Ele rejeita se o programa termina antes de escutar**, então um servidor que não conseguiu iniciar,
porque a porta estava ocupada, por exemplo, reprova o arquivo de teste no `before` com o motivo, em
vez de deixar todo teste esgotar o tempo contra o nada. Agora o primeiro teste corrigido; salve como
`tests/seats.test.mjs`:

```js
// tests/seats.test.mjs: buying seats takes them off the show.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order, get } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8181';
let stop, bearer;

before(async () => {
  stop = await start('boxoffice.mjs', { PORT: '8181' });
  bearer = await token(BASE);
});
after(() => stop());

test('two seats of sh-103 leave two', async () => {
  const placed = await order(BASE, bearer, { show_id: 'sh-103', seats: 2 });
  assert.equal(placed.status, 201);
  const { body } = await get(`${BASE}/v1/shows/sh-103`);
  assert.equal(body.seats_left, 2);
});
```

e o segundo corrigido; salve como `tests/sellout.test.mjs`:

```js
// tests/sellout.test.mjs: a show with no seats left refuses the next order.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8182';
let stop, bearer;

before(async () => {
  stop = await start('boxoffice.mjs', { PORT: '8182' });
  bearer = await token(BASE);
});
after(() => stop());

test('sh-103 sells out at four seats', async () => {
  const all = await order(BASE, bearer, { show_id: 'sh-103', seats: 4 });
  assert.equal(all.status, 201);
  const one = await order(BASE, bearer, { show_id: 'sh-103', seats: 1 });
  assert.equal(one.status, 409);
  assert.equal(one.body.detail, 'only 0 seats left');
});
```

Cada um inicia o próprio boxoffice no `before`, na 8181 e na 8182, e o para no `after`. Rode os dois
juntos, em paralelo desta vez, e duas vezes:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/seats.test.mjs tests/sellout.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - two seats of sh-103 leave two
ok 2 - sh-103 sells out at four seats
# pass 2
# fail 0
# todo 0
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/seats.test.mjs tests/sellout.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - two seats of sh-103 leave two
ok 2 - sh-103 sells out at four seats
# pass 2
# fail 0
# todo 0
```

**A mesma resposta em qualquer ordem, quantas vezes for**, porque nenhum teste enxerga o que o outro
fez. O custo é um servidor iniciado por arquivo, uma fração de segundo aqui, o que sai barato perto de
uma tarde gasta num teste que falha uma vez a cada cinco.
