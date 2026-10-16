---
title: Um nome que ninguém mais tem
version: 1
---

**A cura do nome fixo é um nome que não pode já existir.** Se cada execução de cada teste inventa
um cliente novo, nenhuma execução anterior e nenhum outro teste pode tê-lo tomado, e o teste deixa
de depender da história. O trabalho está em escolher de onde vem a unicidade, porque há várias
fontes óbvias e duas delas não são únicas no sentido que importa.

A ideia errada comum é que basta um valor *diferente* por teste. Diferente de quê, essa é a
pergunta: dos outros testes rodando no mesmo instante, ou de toda execução que já tocou este
servidor? O primeiro é unicidade no espaço, o segundo unicidade no tempo, e a falha do nome fixo
na seção anterior foi uma falha no tempo.

## Quatro candidatos, impressos

O Playwright entrega a cada teste um objeto `testInfo`, o segundo argumento da função do teste, e
dois dos seus campos parecem identidades. O Node dá os outros dois: o relógio, e
`crypto.randomUUID()`, que devolve 122 bits aleatórios escritos como UUID. Um teste que imprime os
quatro, para você compará-los entre workers e entre execuções. Salve como `tests/names.spec.js`:

```javascript
import { test } from '@playwright/test';
import { randomUUID } from 'node:crypto';

// Prints four candidates for a unique name, to compare across runs.
test('four ways to make a name', async ({}, testInfo) => {
  console.log(`worker ${testInfo.workerIndex}  test ${testInfo.testId}  time ${Date.now()}  uuid ${randomUUID()}`);
});
```

`--repeat-each 2` roda o teste duas vezes na mesma execução, e `--workers 2` deixa as duas cópias
rodarem ao mesmo tempo em dois processos worker, que é o que dois testes de uma suíte real fazem.
Rode, e rode de novo:

```
ana@laptop:~/quitanda$ npx playwright test tests/names.spec.js --repeat-each 2 --workers 2

Running 2 tests using 2 workers

worker 0  test 5cb21a92ffec044e7e47-b870072407ed43c8a900  time 1792112954542  uuid fd9cf333-f069-4ea1-8863-59d91e640ae5
worker 1  test 5cb21a92ffec044e7e47-887d21061a9cc03c31e7  time 1792112954553  uuid f7b7440f-93a7-4f0c-8438-48e3e4cdca64
  ✓  1 tests/names.spec.js:5:1 › four ways to make a name (5ms)
  ✓  2 tests/names.spec.js:5:1 › four ways to make a name (4ms)

  2 passed (1.2s)
ana@laptop:~/quitanda$ npx playwright test tests/names.spec.js --repeat-each 2 --workers 2

Running 2 tests using 2 workers

worker 1  test 5cb21a92ffec044e7e47-887d21061a9cc03c31e7  time 1792112956989  uuid 276092ff-84d4-4071-8c90-831666385646
worker 0  test 5cb21a92ffec044e7e47-b870072407ed43c8a900  time 1792112957002  uuid e1035f6a-bfa9-429d-8db2-ee798dca09cd
  ✓  1 tests/names.spec.js:5:1 › four ways to make a name (5ms)
  ✓  2 tests/names.spec.js:5:1 › four ways to make a name (5ms)

  2 passed (1.2s)
```

Leia coluna por coluna.

| fonte | única entre workers? | única entre execuções? | o que mais ela diz |
|---|---|---|---|
| `testInfo.workerIndex` | sim, enquanto rodam | **não**: 0 e 1 voltam a cada execução | qual worker, nada sobre o teste |
| `testInfo.testId` | sim, até para duas cópias de um teste | **não**: os mesmos dois ids voltam | qual teste criou o dado, se você guardar um mapa |
| `Date.now()` | quase: as duas cópias ficaram a 11 e a 13 ms uma da outra, e poderiam ter dividido um milissegundo | sim, o relógio anda | **quando** foi criado, o que ajuda ao ler um banco depois |
| `randomUUID()` | sim | sim | nada; para uma pessoa, é ruído |

Os dois primeiros foram feitos para outro trabalho. O `workerIndex` existe para que cada worker
tenha um recurso só seu, uma conta ou um banco, guardado para aquele worker; a documentação do
Playwright o usa assim. O `testId` dá nome ao teste, e é estável de propósito, para que os
relatórios sigam um teste entre execuções. **Os dois são únicos no espaço e se repetem no tempo**,
então um nome feito só de um deles falha exatamente como `maria` falhou, na segunda execução
contra uma loja que continua de pé.

O relógio é único no tempo e quase único no espaço. Dois workers que começam um teste no mesmo
milissegundo recebem o mesmo número, e numa máquina rápida isso não é raro. O UUID é único nos
dois, e o preço é que `maria-3f1c7a02-…` não diz nada a quem lê uma execução que falhou.

## Legível na frente, aleatório atrás

A resposta de costume combina os dois: um prefixo fixo que diz o que criou o dado, e uma cauda
aleatória que o torna único. Oito caracteres hexadecimais de um UUID são 32 bits aleatórios, uns
quatro bilhões de valores, o que sobra para os clientes que uma suíte cria. Se você quiser ler a
data no nome depois, um carimbo de tempo no meio não custa nada. Salve como
`tests/signup.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { randomUUID } from 'node:crypto';

// A name no other test and no earlier run has used: readable at the
// front, random at the back.
const newName = (who) => `${who}-${randomUUID().slice(0, 8)}`;

test('a new customer can sign up', async ({ page }) => {
  const name = newName('maria');
  await page.goto('/signup.html');
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('status')).toHaveText(`Welcome, ${name}`);
});
```

Com a loja deixada rodando, que era a condição que falhava antes, duas vezes:

```
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 1 test using 1 worker

  ✓  1 tests/signup.spec.js:8:1 › a new customer can sign up (200ms)

  1 passed (1.3s)
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 1 test using 1 worker

  ✓  1 tests/signup.spec.js:8:1 › a new customer can sign up (225ms)

  1 passed (1.2s)
```

**A saudação esperada é montada com a mesma variável do nome digitado.** Essa é a linha que as
pessoas esquecem: um teste que digita um nome único e depois confere `Welcome, maria` só mudou o
defeito de lugar.

## O que dados únicos não resolvem

Um nome único protege o teste dos dados dos outros quando o teste **cria** o que precisa. Não faz
nada pelos dados que o teste só **lê** e que outra pessoa pode mudar, e não faz nada por aquilo de
que só existe um. A cesta da loja é do segundo tipo: não há *cesta da maria-3f1c7a02* para criar,
só a cesta. A seção sobre estado compartilhado volta a ela. E dados únicos se acumulam. Cada
execução acrescenta clientes que ninguém apaga, o que numa loja em memória é inofensivo e num banco
de verdade é uma tabela que cresce milhares de linhas por semana; a seção sobre limpeza trata
disso.
