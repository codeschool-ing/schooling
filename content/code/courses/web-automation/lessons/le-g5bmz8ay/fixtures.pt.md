---
title: Entregando a cada teste o seu page object
version: 1
---

Todo teste de `tests/page-object.spec.js` ainda começa com as mesmas três linhas: esvaziar a
cesta, criar um `ShopPage`, abri-lo. **Isso é preparação, e o Playwright tem um lugar para a
preparação melhor do que uma linha no topo de cada teste: uma fixture.** Você usa fixtures desde a
aula 1, porque `page` e `request` são fixtures: o teste as nomeia no primeiro argumento e o
executor as constrói antes do teste e faz a limpeza depois. O `test.extend` acrescenta fixtures
suas a essa lista.

Um `beforeEach` também poderia guardar as três linhas, e os arquivos da aula 10 fazem algo
parecido. Os limites dele aparecem quando a suíte cresce: roda para todo teste do arquivo, precise
o teste da loja ou não, compartilha o resultado por uma variável fora do teste, e um segundo
arquivo tem de copiá-lo. Uma fixture é declarada uma vez, importada onde for preciso, e construída
só para o teste que a pede pelo nome. A documentação do Playwright diz exatamente isso: as
fixtures são preparadas sob demanda, e um teste que não nomeia uma não paga por ela.

## A fixture

Uma fixture é uma função `async`. Ela recebe as fixtures de que depende, constrói o seu valor e o
passa para `use`; o teste roda enquanto `use` espera, e o que vier escrito depois é a limpeza, que
roda quando o teste termina. Deixe o arquivo em `tests`, ao lado das specs: o nome dele não termina
em `.spec.js`, então o executor não o toma por um arquivo de teste. Salve como `tests/fixtures.js`:

```javascript
import { test as base, expect } from '@playwright/test';
import { ShopPage } from '../pages/shop-page.js';

// A test that asks for `shop` gets an empty basket and the shop open on it.
export const test = base.extend({
  shop: async ({ page, request }, use) => {
    await request.post('/api/reset');
    const shop = new ShopPage(page);
    await shop.open();
    await use(shop);
  },
});

export { expect };
```

A fixture `shop` depende de duas embutidas, `page` e `request`, e o Playwright constrói essas
primeiro. Não há o que limpar aqui, porque o executor já fecha a página; a limpeza da cesta
acontece *antes* de cada teste, e não depois, para que um teste sempre comece de uma cesta que ele
conhece, mesmo quando o anterior quebrou no meio.

## Os testes, pedindo por ela

A spec importa `test` e `expect` do arquivo de fixtures em vez de `@playwright/test`, e nomeia
`shop` onde antes nomeava `page`. Salve como `tests/page-object.spec.js`:

```javascript
import { test, expect } from './fixtures.js';

test('a banana goes into the basket', async ({ shop }) => {
  await shop.addToBasket('banana');
  await expect(shop.basketCount()).toHaveText('1');
});

test('two fruit make two items', async ({ shop }) => {
  await shop.addToBasket('banana');
  await expect(shop.basketCount()).toHaveText('1');
  await shop.addToBasket('mango');
  await expect(shop.basketCount()).toHaveText('2');
});

test('the total follows the price', async ({ shop }) => {
  await shop.addToBasket('papaya');
  await expect(shop.basketTotal()).toHaveText('R$ 7,90');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js tests/page-object-card.spec.js --workers 1

Running 5 tests using 1 worker

  ✓  1 tests/page-object-card.spec.js:7:3 › the guava card on / (195ms)
  ✓  2 tests/page-object-card.spec.js:7:3 › the guava card on /ssr (130ms)
  ✓  3 tests/page-object.spec.js:3:1 › a banana goes into the basket (217ms)
  ✓  4 tests/page-object.spec.js:8:1 › two fruit make two items (393ms)
  ✓  5 tests/page-object.spec.js:15:1 › the total follows the price (258ms)

  5 passed (2.8s)
```

**Cada teste agora é só o caso em si**: o que o cliente fez e o que deveria ver. Compare o segundo
teste com a versão dele na seção 02: a abertura agora é da fixture, e nenhuma das quatro linhas
restantes nomeia um elemento, um papel ou um endereço. Os testes do cartão continuam importando de
`@playwright/test` e pedindo `page`, então a fixture `shop` nunca rodou para eles: nada de limpar
a cesta, nada de carregar a página a mais.

## Para o que uma fixture não serve

Uma fixture prepara o **mundo** em que um teste começa: dados, um usuário logado, uma página
aberta. Não é lugar para os passos do teste. Uma fixture chamada `shopWithBananaInBasket` parece
prática e esconde num nome o passo de que o teste trata. O teste passa a dizer *dada uma cesta com
uma banana, espere 1*, e a única ação que ele existe para conferir saiu de vista. Se um passo é o
assunto do teste, ele pertence ao teste. A aula 15 trata do lado dos dados desse mundo: isolamento,
e limpeza depois de um teste.
