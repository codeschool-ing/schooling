---
title: Componentes dentro da página
version: 1
---

**Um page object para uma página inteira vira um arquivo comprido, e quase todo esse comprimento
é a mesma parte descrita de novo e de novo.** A loja desenha oito cartões de produto com o mesmo
markup, e uma linha da cesta no cabeçalho. Uma aplicação de verdade repete muito mais: um
cabeçalho em toda página, um cartão de produto na página inicial, na busca e na cesta. Descrever
um cartão dentro do `ShopPage` é descrevê-lo outra vez no próximo page object que mostrar um. A
resposta é dar a cada parte repetida um objeto pequeno, um **objeto de componente**, e montar os
page objects com eles.

Um objeto de componente é construído a partir de um **localizador raiz**: o elemento que contém a
parte. Todo localizador dentro dele parte dessa raiz, então a mesma classe descreve qualquer
cartão que receber e não consegue alcançar nada fora dele. É o encadeamento da aula 2,
`getByTestId('product-mango').getByRole(...)`, transformado em classe.

## As duas partes

O cartão. Salve como `pages/product-card.js`:

```javascript
// One product card. It is built from the card's own locator, so one class
// serves every card, on any page that draws one.
export class ProductCard {
  constructor(root) {
    this.name = root.getByRole('heading');
    this.price = root.locator('.price');
    this.addButton = root.getByRole('button', { name: 'Add to basket' });
  }

  async add() {
    await this.addButton.click();
  }
}
```

A linha da cesta no cabeçalho. Ela só mostra, então não tem métodos: dois localizadores,
construídos a partir da raiz que receber. Salve como `pages/basket-summary.js`:

```javascript
// The basket line in the header: how many items, and what they cost.
export class BasketSummary {
  constructor(root) {
    this.count = root.getByTestId('basket-count');
    this.total = root.locator('.basket-total');
  }
}
```

## A página, feita delas

O `ShopPage` agora guarda um `BasketSummary` construído a partir do `header` da página, e cria um
`ProductCard` para o produto que o teste nomear. Os quatro métodos mantêm os nomes que tinham,
então os testes não mudam. Salve como `pages/shop-page.js`:

```javascript
import { ProductCard } from './product-card.js';
import { BasketSummary } from './basket-summary.js';

// The shop's one page, made of the parts it draws.
export class ShopPage {
  constructor(page) {
    this.page = page;
    this.basket = new BasketSummary(page.locator('header'));
  }

  async open() {
    await this.page.goto('/');
  }

  product(id) {
    return new ProductCard(this.page.getByTestId(`product-${id}`));
  }

  async addToBasket(id) {
    await this.product(id).add();
  }

  basketCount() {
    return this.basket.count;
  }

  basketTotal() {
    return this.basket.total;
  }
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 385\" role=\"img\" aria-label=\"Cinco camadas, de cima para baixo. O teste diz await shop.addToBasket('banana'). O page object ShopPage oferece open, addToBasket, basketCount e basketTotal. Ele é feito de dois componentes, ProductCard, uma classe para oito cartões, e BasketSummary, no cabeçalho. Cada componente guarda localizadores, getByRole button com um nome e getByTestId basket-count, e os localizadores encontram elementos no DOM, um li com o test id product-banana e um span com o test id basket-count. Uma mudança no markup chega por baixo e para na linha dos localizadores.\"><text x=\"20\" y=\"48\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o teste</text><text x=\"20\" y=\"118\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">page object</text><text x=\"20\" y=\"188\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">componentes</text><text x=\"20\" y=\"258\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">localizadores</text><text x=\"20\" y=\"328\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o DOM</text><rect x=\"180\" y=\"20\" width=\"520\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"440\" y=\"48\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">await shop.addToBasket('banana')</text><path d=\"M440 66 L440 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M440 88 L435 79 L445 79 Z\" fill=\"var(--phosphor)\"></path><rect x=\"180\" y=\"90\" width=\"520\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"440\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">ShopPage</text><text x=\"440\" y=\"128\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">open() · addToBasket(id) · basketCount() · basketTotal()</text><path d=\"M310 136 L310 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M310 158 L305 149 L315 149 Z\" fill=\"var(--phosphor)\"></path><path d=\"M570 136 L570 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M570 158 L565 149 L575 149 Z\" fill=\"var(--phosphor)\"></path><rect x=\"180\" y=\"160\" width=\"260\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"310\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">ProductCard</text><text x=\"310\" y=\"198\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma classe, oito cartões</text><rect x=\"460\" y=\"160\" width=\"240\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"580\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">BasketSummary</text><text x=\"580\" y=\"198\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no cabeçalho</text><path d=\"M310 206 L310 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M310 228 L305 219 L315 219 Z\" fill=\"var(--phosphor)\"></path><path d=\"M580 206 L580 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M580 228 L575 219 L585 219 Z\" fill=\"var(--phosphor)\"></path><rect x=\"180\" y=\"230\" width=\"260\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"310\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">getByRole('button', { name })</text><rect x=\"460\" y=\"230\" width=\"240\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"580\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">getByTestId('basket-count')</text><path d=\"M310 276 L310 298\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M310 298 L305 289 L315 289 Z\" fill=\"var(--phosphor)\"></path><path d=\"M580 276 L580 298\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M580 298 L575 289 L585 289 Z\" fill=\"var(--phosphor)\"></path><rect x=\"180\" y=\"300\" width=\"260\" height=\"46\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\"></rect><text x=\"310\" y=\"328\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;li data-testid=\"product-banana\"&gt;</text><rect x=\"460\" y=\"300\" width=\"240\" height=\"46\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\"></rect><text x=\"580\" y=\"328\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;span data-testid=\"basket-count\"&gt;</text><text x=\"440\" y=\"372\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma mudança no markup chega por baixo e para na linha dos localizadores</text></svg>", "caption": "Cada camada conhece só a de baixo. O teste nunca vê um localizador, e só os localizadores veem o HTML.", "same": ["page object"]}
```

**Isto é composição: a página tem uma cesta e tem cartões.** O outro caminho, que a maioria das
suítes toma primeiro, é a herança: um `BasePage` com o cabeçalho dentro, e todo page object faz
`extends BasePage`. Funciona até uma página não ter cabeçalho, ou ter dois tipos de cartão, ou
uma parte aparecer em algumas páginas e não em outras. Aí a classe base junta métodos que só
alguns filhos conseguem oferecer de verdade, e todo page object herda todos eles. Uma parte
guardada como campo está presente onde a página a tem e ausente onde não tem, e o `ShopPage` diz
no construtor exatamente do que é feito.

## Um componente, duas páginas

A aula 6 construiu `/ssr`, a mesma loja renderizada no servidor. Os cartões de lá têm o mesmo
markup dos da página inicial, e ela não tem cabeçalho: a contagem fica num parágrafo simples, sem
total. Então o `ProductCard` deve funcionar lá sem mudança, e o `BasketSummary` não tem o que
fazer lá. Este arquivo confere a primeira afirmação nas duas páginas, e não põe nada na cesta, o
que importa em `/ssr`, onde um clique antes de o script chegar não faz nada. Salve como
`tests/page-object-card.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { ProductCard } from '../pages/product-card.js';

// The same component on two pages: the shop, and the one lesson 6 renders
// on the server. Only the card is shared; nothing here adds to the basket.
for (const address of ['/', '/ssr']) {
  test(`the guava card on ${address}`, async ({ page }) => {
    await page.goto(address);
    const guava = new ProductCard(page.getByTestId('product-guava'));
    await expect(guava.name).toHaveText('Guava');
    await expect(guava.price).toContainText('R$ 12,90');
  });
}
```

Rode-o com os testes do page object, cujo arquivo é o da seção anterior, intocado:

```
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js tests/page-object-card.spec.js --workers 1

Running 5 tests using 1 worker

  ✓  1 tests/page-object-card.spec.js:7:3 › the guava card on / (164ms)
  ✓  2 tests/page-object-card.spec.js:7:3 › the guava card on /ssr (121ms)
  ✓  3 tests/page-object.spec.js:8:1 › a banana goes into the basket (206ms)
  ✓  4 tests/page-object.spec.js:15:1 › two fruit make two items (322ms)
  ✓  5 tests/page-object.spec.js:24:1 › the total follows the price (263ms)

  5 passed (2.7s)
```

Cinco aprovados. **Os três testes da cesta rodaram contra um page object cujo interior foi
reescrito**, e não perceberam. Os dois testes do cartão rodaram uma classe em duas páginas
construídas por código diferente, uma desenhada por um script no navegador e outra enviada
inteira pelo servidor. O `toContainText` está ali porque a página inicial escreve a unidade depois
do preço, *R$ 12,90 / kg*, e `/ssr` não.
