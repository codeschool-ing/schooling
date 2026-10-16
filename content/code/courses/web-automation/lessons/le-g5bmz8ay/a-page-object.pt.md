---
title: Um page object
version: 1
---

**Um page object é uma classe que representa uma página da aplicação, e é o único código da suíte
que sabe como essa página é construída.** Os testes falam com ele nas palavras do cliente:
*abrir*, *pôr uma banana*, *a contagem da cesta*. Ele responde achando os elementos, clicando
neles e devolvendo o que o teste precisa conferir. Quando o markup muda, muda o page object, e os
testes não. A descrição do padrão por Martin Fowler põe isso como regra: o page object deve deixar
um teste fazer e ver tudo o que uma pessoa faz e vê, por uma interface que não menciona o HTML.

A primeira ideia comum é que um page object é um lugar para guardar seletores: um arquivo de
constantes, `BANANA_BUTTON = '[data-testid=product-banana] button'`, importado por todos os
testes. Isso muda as strings de lugar e mantém o problema. Os testes continuam dizendo *clique
neste botão*, então continuam se lendo como o markup, e um passo de três ações continua escrito
três vezes. **O que o page object guarda é comportamento, e os localizadores vêm junto.**

## A classe

O Playwright não precisa de nada especial para isso: um page object é uma classe JavaScript comum
que guarda o `page` que recebe. Crie uma pasta `pages` ao lado de `tests`, para que o executor não
confunda a classe com um arquivo de teste. Salve como `pages/shop-page.js`:

```schooling-example
{"language": "javascript", "file": "pages/shop-page.js", "parts": [{"code": "// The shop's one page, as a test sees it: what a customer can do on it,\n// and what it shows them. Every locator for the page is written here.\nexport class ShopPage {\n  constructor(page) {\n    this.page = page;\n  }\n", "note": "Uma classe comum. Ela recebe o `page` que o teste ganhou e o guarda; não abre navegador nem página por conta própria. O comentário diz a única regra que justifica o arquivo."}, {"code": "  async open() {\n    await this.page.goto('/');\n  }\n", "note": "O endereço mora aqui agora. O teste diz *abra a loja* e nunca menciona onde a loja fica."}, {"code": "  async addToBasket(product) {\n    const card = this.page.getByTestId(`product-${product}`);\n    await card.getByRole('button', { name: 'Add to basket' }).click();\n  }\n", "note": "O método tem o nome do que o cliente faz, não do botão. O test id do cartão e o nome do botão estão escritos uma vez, aqui, para todos os produtos."}, {"code": "  basketCount() {\n    return this.page.getByTestId('basket-count');\n  }\n\n  basketTotal() {\n    return this.page.locator('.basket-total');\n  }\n}", "note": "Estes dois devolvem um **localizador**, e não o texto dentro dele, para que o teste ponha nele uma asserção web-first. A seção 05 desta aula explica por que isso importa."}]}
```

**Criar um localizador não custa nada.** A aula 10 mostrou que `getByTestId(...)` não encontra
nada quando é escrito; é uma descrição, resolvida a cada uso. Então um page object pode criar os
seus localizadores quantas vezes quiser, e cada um olha a página como ela está quando o teste o
usa, não como estava quando o objeto foi criado.

## Os testes, em cima dele

Os mesmos três testes, agora falando com o page object. Salve como `tests/page-object.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { ShopPage } from '../pages/shop-page.js';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a banana goes into the basket', async ({ page }) => {
  const shop = new ShopPage(page);
  await shop.open();
  await shop.addToBasket('banana');
  await expect(shop.basketCount()).toHaveText('1');
});

test('two fruit make two items', async ({ page }) => {
  const shop = new ShopPage(page);
  await shop.open();
  await shop.addToBasket('banana');
  await expect(shop.basketCount()).toHaveText('1');
  await shop.addToBasket('mango');
  await expect(shop.basketCount()).toHaveText('2');
});

test('the total follows the price', async ({ page }) => {
  const shop = new ShopPage(page);
  await shop.open();
  await shop.addToBasket('papaya');
  await expect(shop.basketTotal()).toHaveText('R$ 7,90');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js --workers 1

Running 3 tests using 1 worker

  ✓  1 tests/page-object.spec.js:8:1 › a banana goes into the basket (474ms)
  ✓  2 tests/page-object.spec.js:15:1 › two fruit make two items (416ms)
  ✓  3 tests/page-object.spec.js:24:1 › the total follows the price (381ms)

  3 passed (3.2s)
```

Leia o segundo teste em voz alta de novo: *abra a loja, ponha uma banana, a contagem é 1, ponha
uma manga, a contagem é 2*. É o caso de teste que uma pessoa teria escrito em `manual-testing`, e
quem lê consegue julgar se é o caso certo sem conhecer um único test id. As asserções ficaram no
teste, e o motivo vem duas seções adiante.

## A mesma mudança, de novo

O botão vira *Add to cart*, e a suíte falha exatamente como antes:

```
ana@laptop:~/quitanda$ sed -i 's/>Add to basket</>Add to cart</' app/public/app.js
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js --workers 1

Running 3 tests using 1 worker

  ✘  1 tests/page-object.spec.js:8:1 › a banana goes into the basket (30.0s)
  ✘  2 tests/page-object.spec.js:15:1 › two fruit make two items (30.0s)
  ✘  3 tests/page-object.spec.js:24:1 › the total follows the price (30.0s)


  1) tests/page-object.spec.js:8:1 › a banana goes into the basket ─────────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })


       at ../pages/shop-page.js:14

      12 |   async addToBasket(product) {
      13 |     const card = this.page.getByTestId(`product-${product}`);
    > 14 |     await card.getByRole('button', { name: 'Add to basket' }).click();
         |                                                               ^
      15 |   }
      16 |
      17 |   basketCount() {
        at ShopPage.addToBasket (/home/ana/quitanda/pages/shop-page.js:14:63)
        at /home/ana/quitanda/tests/page-object.spec.js:11:14

    Error Context: test-results/page-object-a-banana-goes-into-the-basket/error-context.md

  2) tests/page-object.spec.js:15:1 › two fruit make two items ─────────────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })


       at ../pages/shop-page.js:14

      12 |   async addToBasket(product) {
      13 |     const card = this.page.getByTestId(`product-${product}`);
    > 14 |     await card.getByRole('button', { name: 'Add to basket' }).click();
         |                                                               ^
      15 |   }
      16 |
      17 |   basketCount() {
        at ShopPage.addToBasket (/home/ana/quitanda/pages/shop-page.js:14:63)
        at /home/ana/quitanda/tests/page-object.spec.js:18:14

    Error Context: test-results/page-object-two-fruit-make-two-items/error-context.md

  3) tests/page-object.spec.js:24:1 › the total follows the price ──────────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' })


       at ../pages/shop-page.js:14

      12 |   async addToBasket(product) {
      13 |     const card = this.page.getByTestId(`product-${product}`);
    > 14 |     await card.getByRole('button', { name: 'Add to basket' }).click();
         |                                                               ^
      15 |   }
      16 |
      17 |   basketCount() {
        at ShopPage.addToBasket (/home/ana/quitanda/pages/shop-page.js:14:63)
        at /home/ana/quitanda/tests/page-object.spec.js:27:14

    Error Context: test-results/page-object-the-total-follows-the-price/error-context.md

  3 failed
    tests/page-object.spec.js:8:1 › a banana goes into the basket ──────────────────────────────────
    tests/page-object.spec.js:15:1 › two fruit make two items ──────────────────────────────────────
    tests/page-object.spec.js:24:1 › the total follows the price ───────────────────────────────────
```

**Veja para onde as falhas apontam.** Os três stack traces passam por `pages/shop-page.js`, linha
14, a única linha que nomeia o botão; o arquivo de testes só diz qual passo estava em andamento. O
conserto é uma edição, no único lugar que sabe:

```
ana@laptop:~/quitanda$ sed -i "s/name: 'Add to basket'/name: 'Add to cart'/" pages/shop-page.js
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js --workers 1

Running 3 tests using 1 worker

  ✓  1 tests/page-object.spec.js:8:1 › a banana goes into the basket (215ms)
  ✓  2 tests/page-object.spec.js:15:1 › two fruit make two items (422ms)
  ✓  3 tests/page-object.spec.js:24:1 › the total follows the price (178ms)

  3 passed (2.4s)
```

Antes, a troca de nome custava quatro edições em três testes; agora custa uma, e vai continuar
custando uma quando houver trinta testes. Se você fez a mudança, ponha os dois arquivos de volta
do mesmo jeito, com `sed`, trocando os dois nomes de lugar.

A falha em si não sumiu, e não deveria. **Um page object deixa uma mudança de markup barata de
consertar; não a deixa invisível.** A suíte ainda ficou vermelha quando o botão mudou de nome, e
alguém ainda teve de decidir se o texto novo era intencional. O que mudou é que a decisão termina
numa linha, e não numa busca pela suíte inteira.
