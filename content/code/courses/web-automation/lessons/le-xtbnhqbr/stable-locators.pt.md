---
title: "Localizadores que duram: papel, texto e test id"
version: 1
---

**Os localizadores que duram são os que se apoiam no assunto do teste.** Um teste de loja trata do
que o cliente encontra: um título que diz Mango, um botão que diz Add to basket, uma mensagem que
diz que o item entrou. Isso muda quando a página muda de verdade, e aí o teste deve olhar de novo.
O Playwright monta os seus localizadores principais exatamente em torno disso, e a documentação
dele os recomenda antes de CSS e XPath.

## Os localizadores do Playwright

| localizador | acha | na loja |
|---|---|---|
| `getByRole(role, { name })` | um elemento pelo **papel** e pelo **nome acessível**, o que um leitor de tela anuncia | `getByRole('button', { name: 'Add to basket' })` |
| `getByLabel(text)` | um campo de formulário pelo texto do seu rótulo | a página de busca que a aula 3 acrescenta tem uma caixa com o rótulo *Fruit* |
| `getByPlaceholder(text)` | um campo pelo placeholder | nenhum na loja |
| `getByText(text)` | um elemento pelo texto que mostra | `getByText('Mango')` |
| `getByAltText(text)` | uma imagem pelo `alt` | nenhuma na loja |
| `getByTestId(id)` | um elemento pelo `data-testid` | `getByTestId('product-mango')` |

O papel vem da tag (`<button>`, `<h2>`, `<li>`) ou de um atributo `role`, como o aviso da loja,
que é um `<p role="status">`. O nome de um botão é o texto dele. Por padrão, o `getByText` e o
`name` do `getByRole` batem com **parte** do texto e ignoram maiúsculas; `{ exact: true }` os faz
bater com o texto inteiro.

## Uma primeira tentativa, e duas falhas

Três testes que os usam. O terceiro compara um preço com o texto que uma pessoa digitaria. Salve-o
como `tests/locators.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/');
});

test('banana, by its test id', async ({ page }) => {
  const banana = page.getByTestId('product-banana');
  await expect(banana.getByRole('heading')).toHaveText('Banana');
});

test('add a mango, by role and name', async ({ page }) => {
  await page.getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByRole('status')).toHaveText('Added Mango');
});

test('a price, and the space nobody can see', async ({ page }) => {
  const price = page.getByTestId('product-banana').getByText('R$');
  await expect(price).toHaveText('R$ 5,90 / dozen');
  expect(await price.textContent()).toBe('R$ 5,90 / dozen');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/locators.spec.js

Running 3 tests using 1 worker

  ✓  1 tests/locators.spec.js:7:1 › banana, by its test id (241ms)
  ✘  2 tests/locators.spec.js:12:1 › add a mango, by role and name (201ms)
  ✘  3 tests/locators.spec.js:17:1 › a price, and the space nobody can see (210ms)


  1) tests/locators.spec.js:12:1 › add a mango, by role and name ───────────────────────────────────

    Error: locator.click: Error: strict mode violation: getByRole('button', { name: 'Add to basket' }) resolved to 8 elements:
        1) <button type="button">Add to basket</button> aka getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })
        2) <button type="button">Add to basket</button> aka getByTestId('product-mango').getByRole('button', { name: 'Add to basket' })
        3) <button type="button">Add to basket</button> aka getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' })
        4) <button type="button">Add to basket</button> aka getByTestId('product-guava').getByRole('button', { name: 'Add to basket' })
        5) <button type="button">Add to basket</button> aka getByTestId('product-cashew').getByRole('button', { name: 'Add to basket' })
        6) <button type="button">Add to basket</button> aka getByTestId('product-passion').getByRole('button', { name: 'Add to basket' })
        7) <button type="button">Add to basket</button> aka locator('#card-9158 > button')
        8) <button type="button">Add to basket</button> aka locator('#card-7101 > button')

    Call log:
      - waiting for getByRole('button', { name: 'Add to basket' })


      11 |
      12 | test('add a mango, by role and name', async ({ page }) => {
    > 13 |   await page.getByRole('button', { name: 'Add to basket' }).click();
         |                                                             ^
      14 |   await expect(page.getByRole('status')).toHaveText('Added Mango');
      15 | });
      16 |
        at /home/ana/quitanda/tests/locators.spec.js:13:61

    Error Context: test-results/locators-add-a-mango-by-role-and-name/error-context.md

  2) tests/locators.spec.js:17:1 › a price, and the space nobody can see ───────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: "R$ 5,90 / dozen"
    Received: "R$ 5,90 / dozen"

      18 |   const price = page.getByTestId('product-banana').getByText('R$');
      19 |   await expect(price).toHaveText('R$ 5,90 / dozen');
    > 20 |   expect(await price.textContent()).toBe('R$ 5,90 / dozen');
         |                                     ^
      21 | });
      22 |
        at /home/ana/quitanda/tests/locators.spec.js:20:37

    Error Context: test-results/locators-a-price-and-the-space-nobody-can-see/error-context.md

  2 failed
    tests/locators.spec.js:12:1 › add a mango, by role and name ────────────────────────────────────
    tests/locators.spec.js:17:1 › a price, and the space nobody can see ────────────────────────────
  1 passed (3.0s)
```

**O segundo teste é o Playwright se recusando a adivinhar.** Oito botões se chamam *Add to
basket*, e o teste mandou clicar, que é uma ação sobre um elemento. O Playwright chama isso de
**violação do modo estrito** (*strict mode violation*): uma ação, ou uma asserção sobre um
elemento, num localizador que acha mais de um, falha na hora em vez de escolher o primeiro. Essa é
a defesa contra a falha silenciosa do fim da seção anterior. Leia também a lista que ele imprime.
Para cada resultado, sugere um localizador que acharia só aquele, e a maioria encadeia o test id
do cartão com o papel do botão. Olhe os últimos: onde não achou nada melhor para oferecer, ofereceu
o `id` sorteado do cartão, a falha que a seção anterior encontrou. **A sugestão de uma ferramenta é
um ponto de partida, não um veredito**, e essa falharia no próximo carregamento.

**O terceiro teste falhou numa comparação, não num localizador.** A primeira linha dele passou: o
`toHaveText` trata qualquer sequência de espaço em branco como um espaço antes de comparar, e o
espaço inseparável conta como espaço em branco. A segunda linha leu o texto e o comparou com
`toBe`, que compara caracteres. Os dois textos da mensagem parecem idênticos, e diferem num
caractere que você não vê.

## Estreitar, encadear e filtrar

Um localizador pode partir de outro. `page.getByTestId('product-mango').getByRole('button')` é o
botão dentro daquele cartão; `filter({ hasText: 'Mango' })` fica só com os resultados que contêm o
texto. Esta versão acha o cartão como um cliente acha, o item da lista que diz Mango, depois o
botão dentro dele, e escreve o preço com o caractere que ele tem de verdade, `\u00a0`. Salve-o
como `tests/locators.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/');
});

test('banana, by its test id', async ({ page }) => {
  const banana = page.getByTestId('product-banana');
  await expect(banana.getByRole('heading')).toHaveText('Banana');
});

test('add a mango, by role and name', async ({ page }) => {
  const mango = page.getByRole('listitem').filter({ hasText: 'Mango' });
  await mango.getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByRole('status')).toHaveText('Added Mango');
});

test('a price, and the space nobody can see', async ({ page }) => {
  const price = page.getByTestId('product-banana').getByText('R$');
  await expect(price).toHaveText('R$ 5,90 / dozen');
  expect(await price.textContent()).toBe('R$\u00a05,90 / dozen');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/locators.spec.js

Running 3 tests using 1 worker

  ✓  1 tests/locators.spec.js:7:1 › banana, by its test id (202ms)
  ✓  2 tests/locators.spec.js:12:1 › add a mango, by role and name (215ms)
  ✓  3 tests/locators.spec.js:18:1 › a price, and the space nobody can see (131ms)

  3 passed (2.1s)
```

## Uma classificação, e os seus motivos

| | localizador | quebra quando | o que ele afirma no caminho |
|---|---|---|---|
| 1 | papel e nome | o que o cliente encontra muda | que o elemento é anunciado como o que ele é |
| 2 | rótulo, placeholder, texto alternativo | um formulário ou uma imagem muda de texto | o mesmo, para campos e imagens |
| 3 | texto visível | as palavras mudam: uma revisão, uma tradução | que as palavras estão lá |
| 4 | test id | alguém tira o atributo | nada que o cliente veja |
| 5 | CSS sobre estrutura ou classes de estilo | um redesenho | nada que o cliente veja |
| 6 | XPath por posição ou desde a raiz | quase qualquer mudança | nada que o cliente veja |
| — | `id` ou classe gerados | o próximo carregamento, ou o próximo build | nada |

**O topo da lista é onde as equipes discordam.** Um test id não muda por acidente: não significa
nada para um designer nem para um tradutor, e sobrevive ao dia em que a loja for traduzida para o
português, quando todo nome de papel da página muda. Essa é também a fraqueza dele. Se o botão
perdesse o texto, `getByTestId('product-mango').locator('button')` ainda o clicaria e passaria,
enquanto um teste que pede o papel e o nome *Add to basket* falharia, e essa falha é um defeito real
para um cliente que usa leitor de tela; as aulas 12 a 15 de `non-functional-testing` tratam desse
tipo de teste. A ordem aqui põe primeiro o que o cliente encontra, e usa o test id onde as palavras
do cliente não distinguem um elemento só: oito cartões com o mesmo botão são o exemplo da loja.
