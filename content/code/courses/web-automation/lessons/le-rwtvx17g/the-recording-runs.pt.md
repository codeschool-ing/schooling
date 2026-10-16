---
title: Rodando uma gravação
version: 1
---

Nenhum dos gravadores pôde ser operado aqui, mas o que eles produzem pode ser rodado. A gravação do
Selenium IDE vira um teste Playwright passo a passo, com o comportamento que o código de reprodução
dela tem; a do codegen já é Playwright. **As duas vão para uma pasta própria**, porque uma gravação
está para falhar e a suíte em `tests/` é aquela em que um vermelho precisa significar alguma coisa.
A aula 14 separou o teste intermitente dela do mesmo jeito. Salve isto como `recorded.config.js`:

```javascript
// Recordings, run as tests but kept apart from the suite in tests/.
// Everything else comes from the project's own configuration.
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

export default defineConfig({
  ...base,
  testDir: 'recorded',
});
```

## A gravação do IDE, reproduzida

Cada comando do arquivo `.side` da seção do Selenium IDE vira uma linha, e cada linha faz o que a
reprodução do IDE faz: um clique espera até cinco segundos pelo alvo, a pausa é um segundo fixo, e
o `assertText` lê o texto uma vez. Salve-o como `recorded/side.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The Selenium IDE recording, one command per line, played the way the IDE
// plays it: a click waits up to 5 s for its target, assertText reads once.
test('two fruit', async ({ page }) => {
  await page.goto('/');
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.locator('#card-4821 > button').click({ timeout: 5000 });
  await page.locator('#card-1730 > button').click({ timeout: 5000 });
  await page.waitForTimeout(1000);
  expect(await page.locator('[data-testid="basket-count"]').textContent()).toBe('2');
});
```

```
ana@laptop:~/quitanda$ npx playwright test --config recorded.config.js recorded/side.spec.js

Running 1 test using 1 worker

  ✘  1 recorded/side.spec.js:5:1 › two fruit (5.3s)


  1) recorded/side.spec.js:5:1 › two fruit ─────────────────────────────────────────────────────────

    TimeoutError: locator.click: Timeout 5000ms exceeded.
    Call log:
      - waiting for locator('#card-4821 > button')


       6 |   await page.goto('/');
       7 |   await page.setViewportSize({ width: 1280, height: 800 });
    >  8 |   await page.locator('#card-4821 > button').click({ timeout: 5000 });
         |                                             ^
       9 |   await page.locator('#card-1730 > button').click({ timeout: 5000 });
      10 |   await page.waitForTimeout(1000);
      11 |   expect(await page.locator('[data-testid="basket-count"]').textContent()).toBe('2');
        at /home/ana/quitanda/recorded/side.spec.js:8:45

    Error Context: test-results/side-two-fruit/error-context.md

  1 failed
    recorded/side.spec.js:5:1 › two fruit ──────────────────────────────────────────────────────────
```

**Ele falhou no primeiro passo que nomeia um elemento**, depois exatamente dos cinco segundos que o
IDE teria esperado, e pelo motivo que a aula 2 deu: o cartão que era `#card-4821` enquanto alguém
gravava agora tem outro número. A pausa e a verificação de leitura única nem rodaram. Consertar o id
só as revelaria, e a aula 3 já mostrou o que uma pausa fixa faz com uma verificação que lê uma vez.

## As gravações do codegen, reproduzidas

Três sessões do codegen, salvas num arquivo só e renomeadas, porque três testes chamados `test` são
uma duplicata que o Playwright recusa. As duas primeiras usam os nomes que o gerador deu na seção
anterior. A terceira clica na acerola, que o gerador nomeou pelo `id` aleatório; o número ali foi
copiado de uma execução do `pick.mjs`, e o seu vai ser outro. Salve-o como
`recorded/codegen.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('banana', async ({ page }) => {
  await page.goto('http://localhost:3000/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toContainText('1');
});

test('two fruit', async ({ page }) => {
  await page.goto('http://localhost:3000/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toContainText('2');
});

test('acerola', async ({ page }) => {
  await page.goto('http://localhost:3000/');
  await page.locator('#card-8155 > button').click();
  await expect(page.getByRole('status')).toContainText('Added Acerola');
});
```

```
ana@laptop:~/quitanda$ npx playwright test --config recorded.config.js recorded/codegen.spec.js

Running 3 tests using 1 worker

  ✓  1 recorded/codegen.spec.js:3:1 › banana (386ms)
  ✘  2 recorded/codegen.spec.js:9:1 › two fruit (5.3s)
  ✘  3 recorded/codegen.spec.js:16:1 › acerola (30.0s)


  1) recorded/codegen.spec.js:9:1 › two fruit ──────────────────────────────────────────────────────

    Error: expect(locator).toContainText(expected) failed

    Locator: getByTestId('basket-count')
    Expected substring: "2"
    Received string:    "3"
    Timeout: 5000ms

    Call log:
      - Expect "toContainText" with timeout 5000ms
      - waiting for getByTestId('basket-count')
        9 × locator resolved to <span data-testid="basket-count">3</span>
          - unexpected value "3"


      11 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
      12 |   await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
    > 13 |   await expect(page.getByTestId('basket-count')).toContainText('2');
         |                                                  ^
      14 | });
      15 |
      16 | test('acerola', async ({ page }) => {
        at /home/ana/quitanda/recorded/codegen.spec.js:13:50

    Error Context: test-results/codegen-two-fruit/error-context.md

  2) recorded/codegen.spec.js:16:1 › acerola ───────────────────────────────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for locator('#card-8155 > button')


      16 | test('acerola', async ({ page }) => {
      17 |   await page.goto('http://localhost:3000/');
    > 18 |   await page.locator('#card-8155 > button').click();
         |                                             ^
      19 |   await expect(page.getByRole('status')).toContainText('Added Acerola');
      20 | });
      21 |
        at /home/ana/quitanda/recorded/codegen.spec.js:18:45

    Error Context: test-results/codegen-acerola/error-context.md

  2 failed
    recorded/codegen.spec.js:9:1 › two fruit ───────────────────────────────────────────────────────
    recorded/codegen.spec.js:16:1 › acerola ────────────────────────────────────────────────────────
  1 passed (38.1s)
```

**O primeiro teste passou.** Numa loja recém-iniciada a cesta estava vazia, que é o estado em que
ele foi gravado.

**O segundo falhou com a fruta certa na cesta errada.** Os dois cliques funcionaram e a contagem
disse `3`: a banana que o primeiro teste pôs ainda estava lá, porque a cesta é a lista única que a
loja inteira compartilha, desde a aula 1, e nada nas duas gravações a esvazia. Cada sessão foi
gravada numa loja nova, então cada uma passou enquanto era feita.

**E na execução seguinte o mesmo teste passou, com os mesmos três itens.** Suba a loja você mesmo
com `npm start`, para ela sobreviver à execução, rode de novo os dois primeiros testes e pergunte à
loja o que a cesta guarda:

```
ana@laptop:~/quitanda$ npx playwright test --config recorded.config.js recorded/codegen.spec.js -g 'banana|two fruit' | grep -E '✓|✘'
  ✓  1 recorded/codegen.spec.js:3:1 › banana (220ms)
  ✓  2 recorded/codegen.spec.js:9:1 › two fruit (223ms)
ana@laptop:~/quitanda$ curl -s http://localhost:3000/api/basket
{"lines":[{"id":"banana","qty":2},{"id":"mango","qty":1}],"total":1630}
```

Duas bananas e uma manga, sob um teste cujo nome promete dois itens, e desta vez com um visto ao
lado. **A asserção passou por causa do que ela pergunta.** `toContainText('2')` quer o caractere
`2` em algum lugar da contagem, e continua perguntando: se ela olha entre a chegada da banana do
teste e a da manga, a contagem diz `2` por um instante, e um instante basta. Se ela olha nessa
hora é questão de tempo, e por isso uma execução falhou e a seguinte passou. São os assuntos de duas
aulas chegando por um gravador só: um teste intermitente, o da aula 14, e uma verificação satisfeita
pelo estado errado, o jeito silencioso de errar da aula 2, possível porque falta o reinício da aula
15.

**O terceiro falhou no id aleatório**, desta vez depois do limite de trinta segundos do próprio
Playwright para um teste inteiro, já que o codegen não escreve tempo-limite próprio no clique.

## As mesmas verificações, escritas à mão

A aula 12 construiu o page object e a fixture `shop`, que esvazia a cesta e abre a loja antes de
todo teste que a pede. Escrita com eles, a verificação das duas frutas não precisa de ids, nem de
pausa, nem de endereço. Salve-a como `tests/two-fruit.spec.js`:

```javascript
import { test, expect } from './fixtures.js';

test('a banana and a mango make two items', async ({ shop }) => {
  await shop.addToBasket('banana');
  await shop.addToBasket('mango');
  await expect(shop.basketCount()).toHaveText('2');
  await expect(shop.page.getByRole('status')).toHaveText('Added Mango');
});
```

Rode três vezes, com um worker. Dois workers rodariam cópias ao mesmo tempo contra a única cesta
compartilhada, e o reinício de uma cópia cairia no meio dos cliques da outra; as aulas 15 e 19
desmontam esse problema.

```
ana@laptop:~/quitanda$ npx playwright test tests/two-fruit.spec.js --repeat-each 3 --workers 1

Running 3 tests using 1 worker

  ✓  1 tests/two-fruit.spec.js:3:1 › a banana and a mango make two items (378ms)
  ✓  2 tests/two-fruit.spec.js:3:1 › a banana and a mango make two items (419ms)
  ✓  3 tests/two-fruit.spec.js:3:1 › a banana and a mango make two items (344ms)

  3 passed (4.8s)
```

## Por que as gravações ficam onde estão

Os dois arquivos em `recorded/` falham, e ficam guardados de propósito, como os testes que falham e
que a aula 16 guarda em `evidence/`: são espécimes do que uma gravação faz, para rodar pelo nome com
a configuração própria. Um `npx playwright test` simples lê `tests/` e nunca os encontra.

**`test.fail()` seria o jeito errado de guardá-los.** As aulas 3, 5 e 7 o usaram para um teste que
documenta um defeito da loja, e disseram a fraqueza dele: qualquer falha o satisfaz. Aqui seria
pior, porque não há defeito da loja a documentar. O `codegen.spec.js` tem um teste que passa e um
que passa ou falha conforme o tempo, e marcar o arquivo como falha esperada transformaria o primeiro
numa linha vermelha e deixaria o segundo intermitente no sentido contrário. O defeito está
nas gravações, e o lugar honesto para uma gravação que não consegue passar é fora da suíte, com uma
configuração cujo nome diz o que ela guarda.
