---
title: Três testes, uma mudança no markup
version: 1
---

Um teste de página web sabe dois tipos de coisa. Ele sabe **o que o cliente faz**: abre a loja,
põe uma banana, espera que a cesta diga 1. E sabe **onde as coisas estão na página**: a banana é
o elemento com o test id `product-banana`, o botão dela se chama *Add to basket*, a contagem
fica em `basket-count`. O primeiro tipo muda quando o comportamento da loja muda. O segundo muda
toda vez que alguém mexe no markup, o que acontece com muito mais frequência. Uma suíte que
escreve os dois tipos em cada teste paga cada mudança de markup uma vez por teste.

## Três testes, escritos do jeito óbvio

Estes três são a cara de uma suíte depois de uma semana de trabalho honesto. Cada um esvazia a
cesta, abre a loja, acha um cartão pelo test id e o botão dentro dele pelo papel e pelo nome, os
localizadores que a aula 2 defendeu como os que duram, e confere o cabeçalho. Salve como
`tests/page-object.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a banana goes into the basket', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});

test('two fruit make two items', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('2');
});

test('the total follows the price', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.locator('.basket-total')).toHaveText('R$ 7,90');
});
```

Toda execução desta aula que põe algo na cesta leva `--workers 1`. **A loja tem uma cesta só
para todo mundo**, e a documentação do Playwright diz que, por padrão, os arquivos de teste rodam
em paralelo, enquanto os testes de um mesmo arquivo rodam em ordem, num worker só. Rode este
arquivo ao lado de outro que põe frutas e um contaria as bananas do outro. A aula 15 trata dessa
falha; aqui a opção mantém cada transcrição sobre uma coisa de cada vez.

```
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js --workers 1

Running 3 tests using 1 worker

  ✓  1 tests/page-object.spec.js:7:1 › a banana goes into the basket (213ms)
  ✓  2 tests/page-object.spec.js:13:1 › two fruit make two items (386ms)
  ✓  3 tests/page-object.spec.js:21:1 › the total follows the price (288ms)

  3 passed (2.3s)
```

## A mudança

Agora a dona da loja decide que o botão deve dizer *Add to cart*. É uma edição de uma palavra em
`app/public/app.js`, a loja continua funcionando, e um cliente não perceberia que algo quebrou.
Faça a edição com `sed`, rode os mesmos três testes e ponha a palavra de volta:

```
ana@laptop:~/quitanda$ sed -i 's/>Add to basket</>Add to cart</' app/public/app.js
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js --workers 1

Running 3 tests using 1 worker

  ✘  1 tests/page-object.spec.js:7:1 › a banana goes into the basket (30.1s)
  ✘  2 tests/page-object.spec.js:13:1 › two fruit make two items (30.1s)
  ✘  3 tests/page-object.spec.js:21:1 › the total follows the price (30.0s)


  1) tests/page-object.spec.js:7:1 › a banana goes into the basket ─────────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })


       7 | test('a banana goes into the basket', async ({ page }) => {
       8 |   await page.goto('/');
    >  9 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
         |                                                                                           ^
      10 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
      11 | });
      12 |
        at /home/ana/quitanda/tests/page-object.spec.js:9:91

    Error Context: test-results/page-object-a-banana-goes-into-the-basket/error-context.md

  2) tests/page-object.spec.js:13:1 › two fruit make two items ─────────────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })


      13 | test('two fruit make two items', async ({ page }) => {
      14 |   await page.goto('/');
    > 15 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
         |                                                                                           ^
      16 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
      17 |   await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
      18 |   await expect(page.getByTestId('basket-count')).toHaveText('2');
        at /home/ana/quitanda/tests/page-object.spec.js:15:91

    Error Context: test-results/page-object-two-fruit-make-two-items/error-context.md

  3) tests/page-object.spec.js:21:1 › the total follows the price ──────────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' })


      21 | test('the total follows the price', async ({ page }) => {
      22 |   await page.goto('/');
    > 23 |   await page.getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' }).click();
         |                                                                                           ^
      24 |   await expect(page.locator('.basket-total')).toHaveText('R$ 7,90');
      25 | });
      26 |
        at /home/ana/quitanda/tests/page-object.spec.js:23:91

    Error Context: test-results/page-object-the-total-follows-the-price/error-context.md

  3 failed
    tests/page-object.spec.js:7:1 › a banana goes into the basket ──────────────────────────────────
    tests/page-object.spec.js:13:1 › two fruit make two items ──────────────────────────────────────
    tests/page-object.spec.js:21:1 › the total follows the price ───────────────────────────────────
ana@laptop:~/quitanda$ sed -i 's/>Add to cart</>Add to basket</' app/public/app.js
```

**Três falhas, uma causa, e um minuto e meio para descobrir.** Cada teste esperou um botão chamado
*Add to basket* até o teste inteiro esgotar o tempo: uma ação não tem relógio próprio, como a
aula 10 mediu, então cada um gastou os 30 segundos inteiros. O call log diz *waiting for* e mais
nada, que a aula 10 também ensinou a ler como um localizador que não encontra coisa alguma.

Nada na loja estava errado. **Os testes falharam porque cada um guardava a sua própria cópia de
um fato sobre o markup**, e o fato mudou. Conte as cópias no arquivo: o localizador do botão está
escrito quatro vezes em três testes, o da contagem três vezes, o endereço três vezes. Para
consertar a suíte você edita quatro linhas em três lugares, e a próxima suíte de trinta testes
tem quarenta. Alguém vai esquecer uma, e o teste esquecido falha na semana seguinte por um motivo
que parece novo.

A duplicação tem um segundo custo, que aparece antes de qualquer quebra. Leia o segundo teste em
voz alta: ele diz *pegue pelo test id product banana, pegue pelo papel o botão chamado Add to
basket, clique*. Isso é como a página foi construída, não o que o cliente fez. **Um teste que se
lê como uma lista de seletores esconde o próprio propósito**, e quem precisa decidir se uma falha
importa tem de traduzi-lo de volta primeiro.

A aula 10 de `manual-testing` trata das suítes de regressão e de por que elas crescem. O resto
desta aula é uma resposta ao que esse crescimento faz com o código de uma suíte automatizada.
