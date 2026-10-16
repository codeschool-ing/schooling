---
title: O sleep fixo, medido
version: 1
---

**Um sleep fixo é um palpite sobre quanto a página vai demorar, escrito como número.** No dia em
que o número é escolhido, ele está certo para aquela máquina e aquele servidor. Em qualquer outro
dia, ou é curto demais, e o teste falha numa página sem nada de errado, ou é longo demais, e o teste
gasta tempo esperando algo que aconteceu faz tempo. Nunca é exato, porque a página não leva o mesmo
tempo duas vezes. A aula 3 mostrou um sleep decidindo um teste por sorte; esta seção põe em
segundos o custo do hábito.

A defesa de costume do sleep é que ele é simples e que um segundo aqui e ali não faz diferença. As
duas metades merecem ser conferidas contra uma suíte de verdade, então aqui vai uma, escrita do
jeito que uma suíte cheia de sleeps acaba escrita: cada pausa é um número redondo que pareceu
generoso.

## Quatro testes, quatro palpites

Os testes cobrem quatro páginas de aulas anteriores. A página inicial desenha os produtos depois de
carregar (aula 3); um clique mostra o aviso *Added Banana*; a página renderizada no servidor, em
`/ssr`, ignora cliques até o script dela chegar (aula 6); e a página de busca acha uma fruta para
`papaya` colado de uma vez. Cada teste pausa antes de ler, e lê uma vez. A cesta é de todo mundo
que usa a loja, então cada teste a esvazia primeiro. Salve como `tests/sleeps.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('the home page lists eight fruit', async ({ page }) => {
  await page.goto('/');
  await page.waitForTimeout(1000);
  expect(await page.locator('#products li').count()).toBe(8);
});

test('adding a banana says so', async ({ page }) => {
  await page.goto('/');
  await page.waitForTimeout(1000);
  await page.getByTestId('product-banana').getByRole('button').click();
  await page.waitForTimeout(500);
  expect(await page.locator('.toast').textContent()).toBe('Added Banana');
});

test('a click on /ssr adds to the basket', async ({ page }) => {
  await page.goto('/ssr');
  await page.waitForTimeout(1000);
  await page.getByTestId('product-banana').getByRole('button').click();
  await page.waitForTimeout(500);
  expect(await page.getByTestId('basket-count').textContent()).toBe('1');
});

test('searching for papaya finds one fruit', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').fill('papaya');
  await page.waitForTimeout(1000);
  expect(await page.locator('#results li').count()).toBe(1);
});
```

Rode com um worker só. Quatro testes ao mesmo tempo poriam coisas numa mesma cesta ao mesmo tempo,
que é assunto da aula 15; aqui só embaralharia os tempos:

```
ana@laptop:~/quitanda$ npx playwright test tests/sleeps.spec.js --workers 1

Running 4 tests using 1 worker

  ✓  1 tests/sleeps.spec.js:7:1 › the home page lists eight fruit (1.2s)
  ✓  2 tests/sleeps.spec.js:13:1 › adding a banana says so (1.7s)
  ✘  3 tests/sleeps.spec.js:21:1 › a click on /ssr adds to the basket (1.7s)
  ✓  4 tests/sleeps.spec.js:29:1 › searching for papaya finds one fruit (1.3s)


  1) tests/sleeps.spec.js:21:1 › a click on /ssr adds to the basket ────────────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: "1"
    Received: "0"

      24 |   await page.getByTestId('product-banana').getByRole('button').click();
      25 |   await page.waitForTimeout(500);
    > 26 |   expect(await page.getByTestId('basket-count').textContent()).toBe('1');
         |                                                                ^
      27 | });
      28 |
      29 | test('searching for papaya finds one fruit', async ({ page }) => {
        at /home/ana/quitanda/tests/sleeps.spec.js:26:64

    Error Context: test-results/sleeps-a-click-on-ssr-adds-to-the-basket/error-context.md

  1 failed
    tests/sleeps.spec.js:21:1 › a click on /ssr adds to the basket ─────────────────────────────────
  3 passed (8.8s)
```

**Um segundo foi pouco para o `/ssr`.** O script que liga os botões chega cerca de um segundo e meio
depois de a página carregar, então o clique caiu no vão e a contagem ficou em `0`. Os outros três
passaram, e cada um levou um pouco mais que os próprios sleeps.

## O conserto de sempre

O conserto que todo mundo tenta primeiro é um número maior. Troque o primeiro
`waitForTimeout(1000)` do teste de `/ssr` por `waitForTimeout(2000)` e rode o arquivo de novo:

```
ana@laptop:~/quitanda$ npx playwright test tests/sleeps.spec.js --workers 1

Running 4 tests using 1 worker

  ✓  1 tests/sleeps.spec.js:7:1 › the home page lists eight fruit (1.3s)
  ✓  2 tests/sleeps.spec.js:13:1 › adding a banana says so (1.8s)
  ✓  3 tests/sleeps.spec.js:21:1 › a click on /ssr adds to the basket (2.7s)
  ✓  4 tests/sleeps.spec.js:29:1 › searching for papaya finds one fruit (1.1s)

  4 passed (8.5s)
```

Verde, e o preço está nas durações: 1,3 s, 1,8 s, 2,7 s e 1,1 s, e 8,5 s para a execução. Cada
teste agora leva o tempo dos próprios sleeps, seja lá do que a página precisasse. **A suíte espera
pelo dia mais lento que alguém imaginou, em toda execução.** E 2000 ainda é um palpite: num servidor
de build ocupado o bastante para entregar o script meio segundo depois, o mesmo teste volta a
falhar, e o próximo conserto é 3000.

## Os mesmos quatro testes, esperando um estado

Cada sleep fazia as vezes de uma pergunta que a página sabe responder: *há oito produtos*, *o aviso
diz isso*, *a página já disse que está pronta*, *a lista tem Papaya*. Feitas como asserções
web-first, que repetem até serem verdade ou o tempo delas acabar, as perguntas tomam o lugar dos
números. O teste de `/ssr` espera o marcador `data-ready` que a aula 6 apresentou. Esta versão
substitui a primeira. Salve como `tests/sleeps.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('the home page lists eight fruit', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
});

test('adding a banana says so', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button').click();
  await expect(page.locator('.toast')).toHaveText('Added Banana');
});

test('a click on /ssr adds to the basket', async ({ page }) => {
  await page.goto('/ssr');
  await expect(page.locator('body')).toHaveAttribute('data-ready', 'true');
  await page.getByTestId('product-banana').getByRole('button').click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});

test('searching for papaya finds one fruit', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').fill('papaya');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/sleeps.spec.js --workers 1

Running 4 tests using 1 worker

  ✓  1 tests/sleeps.spec.js:7:1 › the home page lists eight fruit (202ms)
  ✓  2 tests/sleeps.spec.js:12:1 › adding a banana says so (265ms)
  ✓  3 tests/sleeps.spec.js:18:1 › a click on /ssr adds to the basket (2.1s)
  ✓  4 tests/sleeps.spec.js:25:1 › searching for papaya finds one fruit (139ms)

  4 passed (4.3s)
```

**Três dos quatro agora terminam numa fração de segundo, e o quarto leva o que a página leva**:
4,3 s para a execução, contra 8,5 s com os sleeps. O teste de `/ssr` é o único lento, porque a
própria página é lenta, e ele continuaria verde no dia em que o script levasse quatro segundos em
vez de um e meio. O arquivo mantém o nome, como lembrete do que ele foi.

Comparar os resumos é a medida que esta seção prometeu: as mesmas quatro verificações, as mesmas
páginas, com os sleeps e sem eles. Uma suíte de algumas centenas de testes multiplica essa
diferença por algumas centenas. O resto desta aula é sobre as esperas que substituem o sleep, no
Selenium e no Playwright, e sobre onde cada uma deixa de funcionar.
