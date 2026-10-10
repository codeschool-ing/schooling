---
title: A página, e a primeira execução
version: 1
---

A única página da loja são três arquivos: o HTML que o navegador pede primeiro, o script que o
preenche e a folha de estilos. A página chega **vazia** — a lista de produtos não está no HTML — e
o script pede os produtos ao servidor depois que a página carregou. Esse é o formato comum de uma
página moderna, e é o motivo de a aula 3 existir: um teste que procura um produto no instante em
que a página abre pode ser mais rápido que a requisição que o traz.

Salve-o como `app/public/index.html`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Quitanda</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <header>
    <a class="brand" href="/">Quitanda</a>
    <button class="menu-toggle" type="button" aria-expanded="false">Menu</button>
    <nav>
      <a href="/">Shop</a>
      <a href="/search.html">Search</a>
    </nav>
    <p class="basket">Basket: <span data-testid="basket-count">0</span> items
      · <span class="basket-total">R$ 0,00</span></p>
  </header>
  <main>
    <h1>Fruit of the season</h1>
    <ul id="products" aria-busy="true"></ul>
    <p role="status" class="toast"></p>
  </main>
  <script src="/app.js"></script>
</body>
</html>
```

O script. Ele pede os produtos, desenha um cartão para cada um e liga o botão **Add to basket** a
uma requisição que acrescenta uma unidade e redesenha o total. O aviso *Added Banana* some depois de
dois segundos, e a aula 13 tem uso para isso. Salve-o como `app/public/app.js`:

```javascript
const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

async function getJson(url, options) {
  const response = await fetch(url, options);
  return response.json();
}

function showBasket(basket) {
  const count = basket.lines.reduce((n, line) => n + line.qty, 0);
  document.querySelector('[data-testid=basket-count]').textContent = count;
  document.querySelector('.basket-total').textContent = money.format(basket.total / 100);
}

function card(product) {
  const li = document.createElement('li');
  li.className = 'card';
  // A known flaw, on purpose: the id changes every time the page loads.
  li.id = 'card-' + Math.floor(Math.random() * 10000);
  li.dataset.testid = 'product-' + product.id;
  li.innerHTML = `<h2>${product.name}</h2>
    <p class="price">${money.format(product.price / 100)} <small>/ ${product.unit}</small></p>
    <button type="button">Add to basket</button>`;
  li.querySelector('button').addEventListener('click', async () => {
    const basket = await getJson('/api/basket', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: product.id }),
    });
    showBasket(basket);
    const toast = document.querySelector('.toast');
    toast.textContent = `Added ${product.name}`;
    setTimeout(() => { toast.textContent = ''; }, 2000);
  });
  return li;
}

async function load() {
  const products = await getJson('/api/products');
  const list = document.querySelector('#products');
  list.append(...products.map(card));
  list.setAttribute('aria-busy', 'false');
  showBasket(await getJson('/api/basket'));
}

document.querySelector('.menu-toggle').addEventListener('click', (event) => {
  const open = event.target.getAttribute('aria-expanded') === 'true';
  event.target.setAttribute('aria-expanded', String(!open));
  document.querySelector('nav').classList.toggle('open', !open);
});

load();
```

Duas das linhas dele são falhas em que um teste tropeça. Cada cartão ganha um `id` sorteado, então
ele muda a cada carregamento da página; a aula 2 trata de por que um teste nunca deve procurar um
elemento por algo assim. E os preços são escritos pelo `Intl.NumberFormat` para o Brasil, que põe
um **espaço inseparável** entre `R$` e o número. Ele parece exatamente um espaço, e um teste que
compara o texto com um espaço comum falha por um motivo que ninguém enxerga.

A folha de estilos. O bloco no fim muda o layout para janelas de 600 pixels de largura ou menos, e
o comentário no meio marca a falha de que trata a aula 7. Salve-a como `app/public/style.css`:

```css
body { margin: 0; font-family: system-ui, sans-serif; color: #1d2b1f; background: #fbfaf5; }
header { display: flex; flex-wrap: wrap; align-items: center; gap: 1rem; padding: 0.75rem 1rem; background: #2f6f4e; color: #fff; }
header a { color: #fff; }
.brand { font-weight: 700; font-size: 1.25rem; text-decoration: none; }
nav { display: flex; gap: 1rem; }
.menu-toggle { display: none; }
/* A known flaw, on purpose: this line refuses to wrap. */
.basket { margin: 0 0 0 auto; white-space: nowrap; min-width: 24rem; text-align: right; }
main { padding: 1rem; }
#products { list-style: none; padding: 0; display: grid; gap: 1rem; grid-template-columns: repeat(auto-fill, minmax(12rem, 1fr)); }
.card { background: #fff; border: 1px solid #c9d6c3; border-radius: 0.5rem; padding: 1rem; }
.card h2 { margin: 0 0 0.5rem; font-size: 1.1rem; }
.price { margin: 0 0 0.75rem; }
button { font: inherit; padding: 0.5rem 0.75rem; border-radius: 0.375rem; border: 1px solid #2f6f4e; background: #fff; color: #2f6f4e; cursor: pointer; }
.toast { min-height: 1.5rem; }

@media (max-width: 600px) {
  .menu-toggle { display: inline-block; margin-left: auto; }
  nav { display: none; width: 100%; flex-direction: column; }
  nav.open { display: flex; }
}
```

## Instalando as ferramentas

Na pasta do projeto, `npm install` lê o `package.json` e põe o Playwright em `node_modules`:

```
ana@laptop:~/quitanda$ npm install

added 3 packages, and audited 4 packages in 1s

found 0 vulnerabilities
```

Isso instalou a **biblioteca**: o código que diz a um navegador o que fazer. Os **navegadores** são
um download à parte, porque cada versão do Playwright é feita para versões específicas deles. Este
comando baixa a versão do Chromium que o Playwright 1.56.0 espera, uns 920 MB descompactados, para
uma pasta de cache na sua pasta pessoal:

```sh
npx playwright install chromium
```

No Linux, o Chromium também precisa de algumas bibliotecas do sistema que um desktop costuma ter e
uma máquina recém-instalada talvez não. Se mais tarde uma execução reclamar de um arquivo `.so`
ausente, `npx playwright install-deps chromium` as instala com `sudo`. **O download não foi
executado para estas transcrições**: a máquina de onde elas vêm não alcança o servidor de downloads
do Playwright, então a mesma versão do Chromium foi copiada para a pasta de cache. Tudo daqui em
diante rodou com ela.

## Iniciando a loja

```
ana@laptop:~/quitanda$ npm start

> start
> node app/server.js

quitanda is listening on http://localhost:3000
```

O terminal agora fica ocupado: o servidor roda até você apertar **Ctrl+C**. Abra
`http://localhost:3000` no seu navegador e você vê oito cartões, um botão **Add to basket** em cada
um e o total da cesta na barra verde. Ponha uma banana na cesta e veja o total mudar.

O servidor responde a quem perguntar, não só a navegadores. De um segundo terminal, a cesta em JSON,
depois de uma banana:

```
ana@laptop:~/quitanda$ curl -s http://localhost:3000/api/basket
{"lines":[{"id":"banana","qty":1}],"total":590}
```

e o reinício, que a esvazia de novo:

```
ana@laptop:~/quitanda$ curl -s -X POST http://localhost:3000/api/reset
{"reset":true}
```

## O primeiro teste

Um teste prova que o laboratório funciona de ponta a ponta: o Playwright inicia a loja, abre o
Chromium, carrega a página e confere que o título está lá e que oito produtos foram desenhados. Pare
o servidor com Ctrl+C antes, porque o Playwright inicia o dele. Salve-o como `tests/smoke.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('the shop opens and lists its fruit', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Fruit of the season' })).toBeVisible();
  await expect(page.locator('#products li')).toHaveCount(8);
});
```

```
ana@laptop:~/quitanda$ npx playwright test

Running 1 test using 1 worker

  ✓  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (225ms)

  1 passed (1.4s)
```

**Um passou, e o laboratório está pronto.** Você não viu janela de navegador: por padrão o
Playwright roda o navegador **headless**, sem janela, desenhando a página em memória, o que é mais
rápido e é o que um servidor de build faz. Acrescente `--headed` ao comando e uma janela do Chromium
abre, carrega a loja e fecha quando o teste termina; a máquina de onde vêm estas transcrições não
tem tela, então essa não foi executada aqui. A aula 17 trata do que muda entre os dois modos.
