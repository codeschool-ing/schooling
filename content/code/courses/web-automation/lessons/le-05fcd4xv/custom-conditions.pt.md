---
title: Escrevendo a sua própria condição
version: 1
---

**Uma condição é uma pergunta de sim ou não, e a única regra é que ela tem de ser falsa até o
momento que você quer dizer e verdadeira daí em diante.** A aula 3 pôs isso em duas perguntas: *é
verdade quando a página terminou, e é falso até lá?* As condições prontas respondem essas duas para
os casos comuns, um elemento aparecer, um texto, um título. Quando a página sinaliza o próprio
estado de outro jeito, a condição tem de ser escrita à mão, e as duas ferramentas aceitam uma função
onde iria uma condição pronta.

## Selenium: qualquer função

O `driver.wait` aceita uma função e a chama a cada 200 ms até ela devolver algo verdadeiro, que é
também o que a espera devolve. Nada obriga a função a olhar um elemento, nem mesmo o navegador. Este
teste usa uma de cada tipo. A primeira pergunta à página pelo marcador de pronto com
`executeScript`, que roda uma linha de JavaScript dentro da página e devolve o resultado. A segunda
nunca toca no navegador: pergunta ao servidor da loja se a banana chegou à cesta. O terceiro
argumento é a mensagem que o `TimeoutError` vai levar, e vale escrevê-la, porque uma função não tem
descrição própria. Salve como `selenium/conditions.test.js`:

```javascript
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { Builder, By } from 'selenium-webdriver';
import chrome from 'selenium-webdriver/chrome.js';

const shop = 'http://localhost:3000';
let driver;

before(async () => {
  const options = new chrome.Options().addArguments('--headless=new');
  driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
});

after(async () => {
  await driver?.quit();
});

test('any function is a condition', async () => {
  await fetch(`${shop}/api/reset`, { method: 'POST' });
  await driver.get(`${shop}/ssr`);
  await driver.wait(
    async () => (await driver.executeScript('return document.body.dataset.ready')) === 'true',
    5000, 'the page never said it was ready');
  await driver.findElement(By.css('[data-testid=product-banana] button')).click();

  // This one never looks at the browser: it asks the server.
  const lines = await driver.wait(async () => {
    const basket = await (await fetch(`${shop}/api/basket`)).json();
    return basket.lines.length > 0 && basket.lines;
  }, 5000, 'the server never received the banana');
  assert.deepEqual(lines.map((line) => line.id), ['banana']);
});
```

Rode juntos os dois arquivos Selenium desta aula. O `node --test` roda cada arquivo num processo
próprio, ao mesmo tempo se ninguém disser o contrário. Os dois arquivos põem uma banana na mesma
cesta compartilhada, então `--test-concurrency=1` os roda um depois do outro:

```
ana@laptop:~/quitanda$ node --test --test-concurrency=1 --test-reporter=tap selenium/ssr.test.js selenium/conditions.test.js
TAP version 13
# Subtest: any function is a condition
ok 1 - any function is a condition
  ---
  duration_ms: 2161.758516
  type: 'test'
  ...
# Subtest: a click on /ssr counts once the page is ready
ok 2 - a click on /ssr counts once the page is ready
  ---
  duration_ms: 2252.671398
  type: 'test'
  ...
1..2
# tests 2
# suites 0
# pass 2
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 4941.910359
```

## Playwright: três jeitos de passar uma função

O Playwright tem uma forma para cada lugar onde uma condição pode morar.

- **`page.waitForFunction(fn)`** roda `fn` dentro da página até ela devolver algo verdadeiro. É o
  equivalente direto da condição com `executeScript` do Selenium.
- **`expect.poll(fn)`** roda `fn` no teste, no Node, e aplica um matcher comum ao que ela devolver,
  de novo e de novo. É a forma para um valor que nem está na página: a resposta de um servidor, um
  arquivo, uma linha de log.
- **`expect(fn).toPass()`** roda um bloco inteiro de verificações até o bloco parar de lançar erro.
  É a forma para verificações que só fazem sentido juntas.

A página de busca da aula 3 precisa da primeira. O sinal dela, `aria-busy="false"`, já é verdade
antes da primeira tecla, então uma espera por ele pode ser satisfeita cedo demais; a linha da
contagem, por outro lado, fica vazia até a primeira resposta ser desenhada. **Juntos, os dois formam
uma condição que é falsa até a busca ter respondido e nada estar pendente**, que é o que diz
`settled` abaixo. Depois que um teste esperou um estado que é final, uma leitura só é honesta, então
as verificações seguintes leem uma vez, com `allTextContents()`, em vez de repetir.

O segundo teste digita a palavra tecla por tecla e encontra o defeito que a aula 3 relatou, então
leva o mesmo `test.fail()` e a mesma frase sobre apagá-lo. Os dois últimos usam `expect.poll` para
perguntar ao servidor, e `toPass` para a contagem e o total da cesta, que a loja muda num passo só.
Salve como `tests/conditions.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

// Runs in the page. True once an answer has been drawn and none is
// outstanding: false before the first key, unlike aria-busy on its own.
const settled = () =>
  document.querySelector('#count').textContent !== ''
  && document.querySelector('#results').getAttribute('aria-busy') === 'false';

test('waitForFunction: filled, the search settles on papaya', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').fill('papaya');
  await page.waitForFunction(settled);
  expect(await page.locator('#results li').allTextContents()).toEqual(['Papaya']);
});

test('waitForFunction: typed, the search settles on papaya', async ({ page }) => {
  // The defect lesson 3 reported: the answer to "p" arrives last and
  // replaces the list. Delete this line when it is fixed.
  test.fail();
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await page.waitForFunction(settled);
  expect(await page.locator('#results li').allTextContents()).toEqual(['Papaya']);
});

test('expect.poll: the server has the banana from /ssr', async ({ page, request }) => {
  await page.goto('/ssr');
  await page.waitForFunction(() => document.body.dataset.ready === 'true');
  await page.getByTestId('product-banana').getByRole('button').click();
  await expect.poll(async () => {
    const basket = await (await request.get('/api/basket')).json();
    return basket.lines.map((line) => line.id);
  }).toEqual(['banana']);
});

test('toPass: the count and the total change together', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-mango').getByRole('button').click();
  await expect(async () => {
    expect(await page.getByTestId('basket-count').textContent()).toBe('1');
    expect(await page.locator('.basket-total').textContent()).toBe('R$ 4,50');
  }).toPass({ timeout: 5000 });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/conditions.spec.js --workers 1

Running 4 tests using 1 worker

  ✓  1 tests/conditions.spec.js:13:1 › waitForFunction: filled, the search settles on papaya (320ms)
  ✘  2 tests/conditions.spec.js:20:1 › waitForFunction: typed, the search settles on papaya (953ms)
  ✓  3 tests/conditions.spec.js:30:1 › expect.poll: the server has the banana from /ssr (1.7s)
  ✓  4 tests/conditions.spec.js:40:1 › toPass: the count and the total change together (224ms)

  4 passed (4.8s)
```

**O teste digitado falhou em menos de um segundo, e isso é a condição funcionando.** Na aula 3 o
mesmo defeito levou cinco segundos para aparecer, porque a asserção ficou repetindo uma lista que
nunca ia mudar. Aqui a espera terminou quando a página terminou, e uma leitura achou as três frutas
na hora. O ` ` no total é o espaço inseparável que a aula 1 achou depois de `R$`.

Dois detalhes são fáceis de errar. **O `toPass` não tem tempo limite próprio**: o padrão dele, no
código instalado, é `0`, então sem `{ timeout }` ele repete até o tempo do teste inteiro acabar. E um
bloco dentro do `toPass` deve só ler. Um bloco que clica, dentro de um laço que repete até passar,
pode clicar duas vezes e passar na segunda banana.
