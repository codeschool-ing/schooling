---
title: Limpar, e quando a limpeza nunca roda
version: 1
---

**Há três lugares para limpar dados de teste, e eles falham de jeitos diferentes.** No fim de cada
teste, o teste apaga o que criou. No começo, ele põe a aplicação num estado conhecido, seja o que
for que a última execução deixou. Ou o ambiente inteiro é jogado fora depois da execução e a
próxima começa do zero. A crença tentadora é que o primeiro é o cuidadoso, porque arruma a própria
bagunça. É justamente o que quebra quando uma execução termina mal, que é quando as sobras causam
problema.

## Apagar no fim

O `test.afterEach` do Playwright roda depois de cada teste do arquivo, **tenha o teste passado ou
falhado**, então é o lugar natural para um delete. O arquivo de cadastro guarda uma lista dos nomes
que criou e os apaga. Salve como `tests/signup.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { randomUUID } from 'node:crypto';

// Every name this file makes, so that afterEach can delete it again.
const created = [];
function newName(who) {
  const name = `${who}-${randomUUID().slice(0, 8)}`;
  created.push(name);
  return name;
}

// Runs after every test, passed or failed: tidy, not essential.
test.afterEach(async ({ request }) => {
  for (const name of created.splice(0)) {
    await request.delete('/api/users', { params: { name } });
  }
});

test('a new customer can sign up', async ({ page }) => {
  const name = newName('maria');
  await page.goto('/signup.html');
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('status')).toHaveText(`Welcome, ${name}`);
});

test('a name that is taken is refused', async ({ page, request }) => {
  const name = newName('joao');
  // The setup goes through the API: this test is about the refusal.
  const created = await request.post('/api/users', { data: { name } });
  expect(created.status()).toBe(201);

  await page.goto('/signup.html');
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('status')).toHaveText(`${name} already exists`);
});
```

O `params` monta a query string, codificando o nome no caminho. Para ver os deletes acontecerem,
rode a loja com o registro de requisições num terminal e os testes em outro:

```
ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/signup.spec.js:19:1 › a new customer can sign up (212ms)
  ✓  2 tests/signup.spec.js:27:1 › a name that is taken is refused (269ms)

  2 passed (1.6s)
```

O terminal da loja, depois que você a para:

```

> start
> node app/server.js

quitanda is listening on http://localhost:3000
GET /api/products 200
GET /api/products 200
GET /signup.html 200
GET /style.css 200
POST /api/users 201
DELETE /api/users?name=maria-cfcdad45 204
POST /api/users 201
GET /signup.html 200
GET /style.css 200
POST /api/users 409
DELETE /api/users?name=joao-b7629e9a 204
```

Cada `DELETE` vem depois das requisições do seu teste e traz o cliente que aquele teste criou: `maria-cfcdad45` depois do cadastro, `joao-b7629e9a` depois da recusa. Os dois `GET /api/products` no topo vêm do Playwright perguntando ao `url` do bloco `webServer` se uma loja já responde. O comentário acima do `afterEach` diz *tidy, not essential*, arrumação e não necessidade,
e essa é a palavra importante deste arquivo. **Os testes já estão seguros porque os nomes são
únicos**; o delete só evita que a loja se encha de clientes que ninguém precisa. Um teste cuja
correção dependesse desse delete estaria de volta ao problema da primeira seção.

## Quando o fim nunca chega

O `afterEach` roda depois de uma falha, e depois de uma interrupção que o Playwright consegue
tratar. Não roda depois de uma que ele não consegue. Um arquivo só para o experimento, com um nome
fixo de propósito, um delete no `afterEach` e um teste que leva dez segundos. Salve-o como
`tests/interrupted.spec.js` e apague quando tiver visto as duas execuções:

```javascript
import { test, expect } from '@playwright/test';

test.afterEach(async ({ request }) => {
  await request.delete('/api/users', { params: { name: 'joao' } });
  console.log('afterEach: joao deleted');
});

test('a slow test that creates joao', async ({ page, request }) => {
  const created = await request.post('/api/users', { data: { name: 'joao' } });
  expect(created.status()).toBe(201);
  console.log('joao created');
  await page.goto('/signup.html');
  await page.waitForTimeout(10000);   // stands for ten seconds of real work
});
```

Com a loja rodando em outro terminal, inicie o teste e aperte **Ctrl+C** alguns segundos depois.
Aqui o `timeout -s INT 3` aperta por você depois de três segundos, e então o `curl` pede *joao* de
novo:

```
ana@laptop:~/quitanda$ timeout -s INT 3 npx playwright test tests/interrupted.spec.js

Running 1 test using 1 worker

joao created
afterEach: joao deleted
  ✘  1 tests/interrupted.spec.js:8:1 › a slow test that creates joao (966ms)


  1) tests/interrupted.spec.js:8:1 › a slow test that creates joao ─────────────────────────────────

    Test was interrupted.

    Error: page.waitForTimeout: Test ended.

      11 |   console.log('joao created');
      12 |   await page.goto('/signup.html');
    > 13 |   await page.waitForTimeout(10000);   // stands for ten seconds of real work
         |              ^
      14 | });
      15 |
        at /home/ana/quitanda/tests/interrupted.spec.js:13:14

  1 interrupted
    tests/interrupted.spec.js:8:1 › a slow test that creates joao ──────────────────────────────────
ana@laptop:~/quitanda$ curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"name":"joao"}' http://localhost:3000/api/users
{"name":"joao"} 201
ana@laptop:~/quitanda$ curl -s -X DELETE 'http://localhost:3000/api/users?name=joao'
```

O Playwright capturou o Ctrl+C, parou o teste, relatou *interrupted* e ainda rodou o `afterEach`:
o nome estava livre depois. Agora a mesma execução encerrada por `SIGKILL`, o sinal que nenhum
programa consegue capturar. É o que o sistema envia quando mata um processo por falta de memória,
e um job de build cancelado muitas vezes equivale a ele. Do ponto de vista do teste, um notebook
que morre sem bateria é a mesma coisa:

```
ana@laptop:~/quitanda$ timeout -s KILL 3 npx playwright test tests/interrupted.spec.js

Running 1 test using 1 worker

joao created
Killed
ana@laptop:~/quitanda$ curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"name":"joao"}' http://localhost:3000/api/users
{"error":"joao already exists"} 409
```

**`joao created`, e nada depois.** O executor e seus workers sumiram antes que o `afterEach`
pudesse começar, e a loja ficou com o cliente. A próxima execução desse teste falha na primeira
linha com `409`, e continua falhando até alguém apagar o *joao* à mão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A execução 1 cria joao e é morta por SIGKILL, então o afterEach dela nunca roda e a loja fica com joao. Uma segunda execução que depende do delete no fim pede joao de novo e falha com 409 na primeira linha. Uma segunda execução que reinicia no começo esvazia a loja primeiro, depois cria joao e passa.\"><text x=\"20\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">execução 1</text><text x=\"20\" y=\"112\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a loja</text><text x=\"20\" y=\"172\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">execução 2</text><text x=\"20\" y=\"188\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">delete no fim</text><text x=\"20\" y=\"242\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">execução 2</text><text x=\"20\" y=\"258\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reinício no começo</text><rect x=\"200\" y=\"32\" width=\"150\" height=\"30\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"275\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">cria joao</text><path d=\"M372 36 L392 58 M392 36 L372 58\" stroke=\"var(--amber)\" stroke-width=\"3\"></path><text x=\"382\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">SIGKILL</text><rect x=\"414\" y=\"32\" width=\"190\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect><text x=\"509\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">afterEach: nunca roda</text><rect x=\"275\" y=\"100\" width=\"425\" height=\"18\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"487\" y=\"113\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\">joao continua lá</text><path d=\"M275 62 L275 98\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><rect x=\"200\" y=\"160\" width=\"150\" height=\"30\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"275\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">cria joao</text><path d=\"M350 175 L398 175\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"400\" y=\"160\" width=\"200\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"500\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">409: falha na linha 1</text><rect x=\"200\" y=\"230\" width=\"100\" height=\"30\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"></rect><text x=\"250\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reinício</text><path d=\"M300 245 L318 245\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"320\" y=\"230\" width=\"150\" height=\"30\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"395\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">cria joao</text><path d=\"M470 245 L488 245\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"490\" y=\"230\" width=\"200\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"590\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">201: passa</text></svg>", "caption": "A mesma execução morta, seguida de dois tipos de execução seguinte. Só a que reinicia antes fica livre do que a execução morta deixou."}
```

## Reiniciar no começo

O outro lugar para limpar é antes do teste, e a loja tem a ferramenta para isso: `POST /api/reset`
devolve os produtos, a cesta, a oferta e os clientes ao estado inicial. Um reinício no começo **não
se importa com como a última execução terminou**. Uma execução morta, um teste que esqueceu o
delete, uma pessoa que pôs uma manga à mão: tudo some antes de o teste olhar.

É na cesta que isso importa, porque uma cesta não pode ser tornada única. Dois testes que esperam
começar de uma cesta vazia. Salve como `tests/basket-data.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

const add = (page, id) =>
  page.getByTestId(`product-${id}`).getByRole('button', { name: 'Add to basket' }).click();

test('a banana costs R$ 5,90', async ({ page }) => {
  await page.goto('/');
  await add(page, 'banana');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
});

test('two mangoes cost R$ 9,00', async ({ page }) => {
  await page.goto('/');
  await add(page, 'mango');
  await add(page, 'mango');
  await expect(page.getByTestId('basket-count')).toHaveText('2');
  await expect(page.locator('.basket-total')).toHaveText('R$ 9,00');
});
```

O ` ` é o espaço inseparável de que a aula 1 avisou. Um worker, o padrão para um arquivo, de
modo que os dois testes rodam um depois do outro:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/basket-data.spec.js:6:1 › a banana costs R$ 5,90 (212ms)
  ✘  2 tests/basket-data.spec.js:13:1 › two mangoes cost R$ 9,00 (5.2s)


  1) tests/basket-data.spec.js:13:1 › two mangoes cost R$ 9,00 ─────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  locator('.basket-total')
    Expected: "R$ 9,00"
    Received: "R$ 14,90"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for locator('.basket-total')
        - locator resolved to <span class="basket-total">R$ 10,40</span>
        - unexpected value "R$ 10,40"
        8 × locator resolved to <span class="basket-total">R$ 14,90</span>
          - unexpected value "R$ 14,90"


      16 |   await add(page, 'mango');
      17 |   await expect(page.getByTestId('basket-count')).toHaveText('2');
    > 18 |   await expect(page.locator('.basket-total')).toHaveText('R$ 9,00');
         |                                               ^
      19 | });
      20 |
        at /home/ana/quitanda/tests/basket-data.spec.js:18:47

    Error Context: test-results/basket-data-two-mangoes-cost-R-9-00/error-context.md

  1 failed
    tests/basket-data.spec.js:13:1 › two mangoes cost R$ 9,00 ──────────────────────────────────────
  1 passed (7.0s)
```

**O segundo teste achou a banana do primeiro**: R$ 14,90 é uma banana e duas mangas. Nenhum dos
dois testes está errado sozinho, e o segundo passa quando roda só. Um reinício no começo de cada
teste resolve. Salve como `tests/basket-data.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

const add = (page, id) =>
  page.getByTestId(`product-${id}`).getByRole('button', { name: 'Add to basket' }).click();

// Every test starts from an empty basket.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a banana costs R$ 5,90', async ({ page }) => {
  await page.goto('/');
  await add(page, 'banana');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
});

test('two mangoes cost R$ 9,00', async ({ page }) => {
  await page.goto('/');
  await add(page, 'mango');
  await add(page, 'mango');
  await expect(page.getByTestId('basket-count')).toHaveText('2');
  await expect(page.locator('.basket-total')).toHaveText('R$ 9,00');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/basket-data.spec.js:11:1 › a banana costs R$ 5,90 (266ms)
  ✓  2 tests/basket-data.spec.js:18:1 › two mangoes cost R$ 9,00 (330ms)

  2 passed (2.1s)
```

O reinício tem um preço, e ele está no código da loja: `reset()` esvazia **tudo**, inclusive os
clientes. É uma ferramenta bruta para uma loja num notebook, e perigosa em qualquer outro lugar.
Num ambiente de teste compartilhado, um reinício no começo do seu teste apaga os dados de todas as
outras pessoas e suítes que o usam; a maioria das aplicações reais não tem um endpoint assim, e as
que têm o recusam fora dos ambientes de teste.

## Jogar o ambiente fora

O terceiro lugar fica fora dos testes: dar a cada execução um ambiente só dela e descartá-lo
depois. Você usou isso a aula inteira sem dar nome. Sem loja rodando, o `webServer` do Playwright
inicia uma nova, em memória, para cada execução, e por isso o nome fixo passou duas vezes na
primeira seção. Num servidor de build, onde `CI` está definida, ele sempre faz isso. Para uma
aplicação com banco de dados, a mesma ideia é um contêiner iniciado para a execução e removido
depois dela; rodar uma suíte num servidor de build é a aula 5 de `testing-cicd`.

| onde | sobrevive a uma execução morta? | custo |
|---|---|---|
| apagar no fim (`afterEach`) | **não** | precisa saber o que o teste criou |
| reiniciar no começo (`beforeEach`) | sim | apaga os dados de todo mundo, e precisa de um endpoint que a aplicação pode não ter |
| ambiente descartável | sim | um ambiente por execução, e minutos para subir um |

O arranjo que se sustenta usa os três juntos: **dados únicos para que os testes não colidam, um
delete no fim para manter a arrumação, e um ambiente novo onde for possível ter um.** O reinício
fica para os dados que não podem ser tornados únicos, e a próxima seção mostra onde até isso para
de funcionar.
