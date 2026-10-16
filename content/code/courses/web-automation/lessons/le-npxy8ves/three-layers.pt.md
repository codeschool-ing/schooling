---
title: Um comportamento, três camadas
version: 1
---

Uma **camada** é quanto do sistema um teste põe para rodar, não a ferramenta em que ele é escrito.
Esta seção pega um comportamento da loja, *uma banana na cesta custa R$ 5,90*, e o verifica três
vezes: chamando a função que soma a cesta, perguntando ao servidor por HTTP e clicando no botão num
navegador. Três arquivos, o mesmo fato, e três quantidades muito diferentes de maquinário ligado
para estabelecê-lo.

A crença comum é que são três jeitos de testar a mesma coisa, então o mais realista é o melhor. Só
que cada camada vê uma parte diferente da loja, e as duas próximas seções medem quanto cada parte
custa e o que ela consegue ver.

## A camada de unidade: uma função e nada mais

`total()` em `app/store.js`, da aula 1, recebe uma lista de linhas da cesta e devolve o preço em
centavos. Não precisa de servidor, de rede nem de página, então o teste mais barato dela é uma
chamada. O Node tem um executor de testes próprio, `node --test`, sem pacote para instalar, e o
`node:assert` para as verificações.

**O arquivo fica fora de `tests/`.** O Playwright roda todo arquivo dessa pasta cujo nome termina em
`.test.js` ou `.spec.js`, e um teste do Node não é um teste do Playwright. Crie a pasta com
`mkdir unit`. Salve-o como `unit/total.test.js`:

```javascript
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { total } from '../app/store.js';

test('an empty basket costs nothing', () => {
  assert.equal(total([]), 0);
});

test('one banana costs 590 cents', () => {
  assert.equal(total([{ id: 'banana', qty: 1 }]), 590);
});

test('quantities multiply and lines add up', () => {
  // three bananas and two guavas: 3 * 590 + 2 * 1290
  assert.equal(total([{ id: 'banana', qty: 3 }, { id: 'guava', qty: 2 }]), 4350);
});
```

Rode-o com o relatório TAP, como a aula 8 fez, que escreve texto simples que um terminal consegue
mostrar:

```
ana@laptop:~/quitanda$ node --test --test-reporter=tap unit/total.test.js
TAP version 13
# Subtest: an empty basket costs nothing
ok 1 - an empty basket costs nothing
  ---
  duration_ms: 0.929121
  type: 'test'
  ...
# Subtest: one banana costs 590 cents
ok 2 - one banana costs 590 cents
  ---
  duration_ms: 0.22451
  type: 'test'
  ...
# Subtest: quantities multiply and lines add up
ok 3 - quantities multiply and lines add up
  ---
  duration_ms: 0.133609
  type: 'test'
  ...
1..3
# tests 3
# suites 0
# pass 3
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 68.064941
```

Três testes, e o `duration_ms` debaixo de cada um é quanto aquele teste levou: 0,929, 0,225 e 0,134
milissegundos. A última linha diz que o arquivo inteiro levou 68 milissegundos, e quase nada disso
foram os testes. **Três casos não custam nada para acrescentar**, e é por isso que o terceiro, com
quantidades, está aqui.

## A camada de API: HTTP, e nenhum navegador

O mesmo fato uma camada acima: reiniciar a loja, mandar `POST /api/basket` com uma banana e ler a
resposta. A fixture `request` do Playwright, que as aulas 6 e 15 usaram, manda a requisição e
conhece o `baseURL`, e o `webServer` da configuração sobe a loja antes. Salve-o como
`tests/basket-api.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Only the request fixture: HTTP to the shop, and no browser.
test('a banana in the basket costs 590 cents', async ({ request }) => {
  await request.post('/api/reset');
  const response = await request.post('/api/basket', { data: { id: 'banana' } });
  expect(response.status()).toBe(200);
  expect(await response.json()).toEqual({ lines: [{ id: 'banana', qty: 1 }], total: 590 });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-api.spec.js

Running 1 test using 1 worker

  ✓  1 tests/basket-api.spec.js:4:1 › a banana in the basket costs 590 cents (51ms)

  1 passed (1.2s)
```

Um teste, 51 ms pela conta do Playwright, e 1,2 s para a execução inteira. Este teste também roda
`total()`, dentro do servidor, junto com a rota, o JSON nos dois sentidos e o próprio servidor HTTP:
um defeito em qualquer um deles o deixa vermelho.

## A camada do navegador: a página, como um cliente a usa

E o mesmo fato como alguém o vê: abrir a loja, apertar Add to basket na banana, ler a contagem e o
total no cabeçalho. Salve-o como `tests/basket-ui.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('a banana in the basket shows R$ 5,90', async ({ page, request }) => {
  await request.post('/api/reset');
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
});
```

O texto esperado foi digitado com um espaço comum, e passa: a aula 2 mostrou que o `toHaveText`
trata o espaço inseparável depois de `R$` como espaço em branco.

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-ui.spec.js

Running 1 test using 1 worker

  ✓  1 tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 (281ms)

  1 passed (1.6s)
```

281 ms para o teste e 1,6 s para a execução. **O teste levou cinco vezes e meia o tempo do teste de
API, e a execução só um pouco mais**, porque a maior parte de uma execução avulsa é o que os dois
arquivos pagam antes de qualquer teste começar. A próxima seção separa as duas coisas.

## Que camada precisa de navegador

A diferença entre os dois últimos é fácil de dizer e vale ver uma vez. Aponte o Playwright para uma
pasta vazia de navegadores e rode os dois arquivos. Eles escrevem na mesma cesta compartilhada, então
rodam num worker só, como todo teste que mexe na cesta até as aulas 15 e 19 cuidarem disso:

```
ana@laptop:~/quitanda$ PLAYWRIGHT_BROWSERS_PATH=~/no-browsers npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1

Running 2 tests using 1 worker

  ✓  1 tests/basket-api.spec.js:4:1 › a banana in the basket costs 590 cents (55ms)
  ✘  2 tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 (2ms)


  1) tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ────────────────────────────

    Error: browserType.launch: Executable doesn't exist at /home/ana/no-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell
    ╔═════════════════════════════════════════════════════════════════════════╗
    ║ Looks like Playwright Test or Playwright was just installed or updated. ║
    ║ Please run the following command to download new browsers:              ║
    ║                                                                         ║
    ║     npx playwright install                                              ║
    ║                                                                         ║
    ║ <3 Playwright Team                                                      ║
    ╚═════════════════════════════════════════════════════════════════════════╝

  1 failed
    tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ─────────────────────────────
  1 passed (1.3s)
```

**O teste de API passou sem navegador nenhum na máquina**; o teste de navegador falhou no primeiro
passo, abrir um. Essa é a diferença entre as duas camadas numa execução só: uma precisa que um
navegador exista, inicie e desenhe uma página, e a outra nunca pede um.
