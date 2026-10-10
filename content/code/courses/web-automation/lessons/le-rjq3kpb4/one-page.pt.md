---
title: Um documento, muitos endereços
version: 1
---

Uma **aplicação de página única**, uma SPA (do inglês *single-page application*), carrega um
documento HTML e nunca carrega outro. Toda tela depois da primeira é desenhada por JavaScript dentro
desse documento, e a barra de endereço também é mudada pelo script, para que o botão voltar do
navegador e os favoritos continuem funcionando. O Gmail, o Trello e as telas de administração da
maioria dos produtos web funcionam assim, e os frameworks por trás deles, React, Vue, Angular e
Svelte entre eles, são sobretudo maneiras de organizar esse desenho.

A crença comum é que uma SPA é só uma página com muito JavaScript. A primeira página da loja já tem
um script que busca os produtos, e não é uma SPA. **O que faz uma SPA é a navegação**: clicar num
link não pede uma página ao servidor. Para um teste, isso muda duas coisas de uma vez, o que ele
espera e o que ele pode perguntar ao servidor, e esta seção trata da primeira.

## O app

A quitanda tem um pequeno em `/spa/`, com duas telas: as frutas e a cesta. O HTML é um cabeçalho
com dois links e um `<main>` vazio. Salve-o como `app/public/spa/index.html`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Quitanda app</title>
  <link rel="stylesheet" href="/style.css">
  <link rel="manifest" href="/spa/manifest.json">
</head>
<body>
  <header>
    <a class="brand" href="/spa/">Quitanda app</a>
    <nav>
      <a href="/spa/">Fruit</a>
      <a href="/spa/basket">Basket</a>
    </nav>
  </header>
  <main id="view"></main>
  <script src="/spa/spa.js"></script>
</body>
</html>
```

O script. `pages` liga cada endereço a uma função que busca o que aquela tela precisa e a desenha em
`#view`, que leva `aria-busy="true"` enquanto isso acontece. O tratador de clique é o truque todo:
ele cancela a navegação comum do link, chama `history.pushState` para pôr o novo endereço na barra
e desenha a tela por conta própria. Salve-o como `app/public/spa/spa.js`:

```javascript
// One HTML page, and the address bar changed by JavaScript rather than by
// loading another page.
const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
const view = document.querySelector('#view');

const pages = {
  '/spa/': async () => {
    const products = await (await fetch('/api/products')).json();
    view.innerHTML = '<h1>Fruit</h1><ul></ul>';
    view.querySelector('ul').append(...products.map((p) => {
      const li = document.createElement('li');
      li.textContent = `${p.name}, ${money.format(p.price / 100)}`;
      return li;
    }));
  },
  '/spa/basket': async () => {
    const basket = await (await fetch('/api/basket')).json();
    view.innerHTML = `<h1>Basket</h1><p>Total: ${money.format(basket.total / 100)}</p>`;
  },
};

async function show(path) {
  view.setAttribute('aria-busy', 'true');
  await (pages[path] ?? (() => { view.innerHTML = '<h1>Not found</h1>'; }))();
  view.setAttribute('aria-busy', 'false');
  document.title = view.querySelector('h1').textContent + ' · Quitanda app';
}

document.addEventListener('click', (event) => {
  const link = event.target.closest('a');
  if (!link || !link.pathname.startsWith('/spa/')) return;
  event.preventDefault();
  history.pushState(null, '', link.pathname);
  show(link.pathname);
});
window.addEventListener('popstate', () => show(location.pathname));

show(location.pathname);
if ('serviceWorker' in navigator) navigator.serviceWorker.register('/spa/sw.js');
```

A última linha registra um **service worker**, e o HTML nomeia um **manifesto**. Os dois são o que
faz deste app uma PWA, e a seção sobre service workers, duas abas adiante, trata deles; salve-os
agora para que a página os encontre. Salve-o como `app/public/spa/manifest.json`:

```json
{
  "name": "Quitanda",
  "start_url": "/spa/",
  "display": "standalone",
  "background_color": "#fbfaf5",
  "theme_color": "#2f6f4e"
}
```

Salve-o como `app/public/spa/sw.js`:

```javascript
// The service worker that makes the app open with no network. It keeps a
// copy of the page, its script and its style, and answers from that copy
// before asking the server.
const SHELL = ['/spa/', '/spa/spa.js', '/style.css'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open('shell-v1').then((cache) => cache.addAll(SHELL)));
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.pathname.startsWith('/api/')) return;
  event.respondWith(caches.match(event.request).then((hit) => hit ?? fetch(event.request)));
});
```

## O que um clique pede ao servidor

O `look.mjs` da aula 1 imprimia cada resposta enquanto uma página carregava. Este script faz o mesmo
para o app e depois clica em **Basket**, para você ver quanto custa uma navegação dentro de uma SPA.
Ele guarda o perfil do navegador numa pasta chamada `.spa-profile` dentro do projeto, para que uma
segunda execução seja um visitante voltando; apague a pasta para ser de novo um visitante novo.
Salve-o como `spa-look.mjs`:

```javascript
// Opens the single-page app, clicks Basket, and prints every response and
// who answered it. The browser's profile is kept in .spa-profile, so a second
// run is a visitor coming back. Run it with the shop started:
// node spa-look.mjs
import { chromium } from '@playwright/test';

const context = await chromium.launchPersistentContext('.spa-profile');
const page = context.pages()[0] ?? await context.newPage();
const start = Date.now();
const ms = () => String(Date.now() - start).padStart(5) + ' ms';

page.on('response', (response) => {
  const request = response.request();
  const who = response.fromServiceWorker() ? 'the service worker' : 'the server';
  const path = new URL(response.url()).pathname;
  console.log(`${ms()}  ${request.resourceType().padEnd(10)} ${path}  from ${who}`);
});

await page.goto('http://localhost:3000/spa/');
await page.locator('#view[aria-busy=false]').waitFor();
console.log(`${ms()}  heading: ${await page.locator('h1').textContent()}`);
await page.evaluate(() => navigator.serviceWorker.ready);
console.log(`${ms()}  service worker ready; click Basket`);
await page.getByRole('link', { name: 'Basket' }).click();
await page.getByRole('heading', { name: 'Basket' }).waitFor();
console.log(`${ms()}  heading: Basket, address: ${page.url()}`);
await context.close();
```

Com a loja iniciada num terminal, a primeira execução:

```
ana@laptop:~/quitanda$ node spa-look.mjs
   15 ms  document   /spa/  from the server
   22 ms  stylesheet /style.css  from the server
   23 ms  script     /spa/spa.js  from the server
   41 ms  fetch      /api/products  from the server
  128 ms  heading: Fruit
  187 ms  service worker ready; click Basket
  227 ms  fetch      /api/basket  from the server
  248 ms  heading: Basket, address: http://localhost:3000/spa/basket
```

As quatro primeiras linhas são um carregamento comum: o documento, a folha de estilos e o script,
depois o `fetch` do script pelos produtos. **Depois do clique há uma linha só, um `fetch`.** Nenhum
documento, nenhuma folha de estilos, nenhum script: o endereço mudou para `/spa/basket` e o navegador
não pediu ao servidor nada além dos dados da cesta. Num site de várias páginas, o mesmo clique pede
um documento novo e tudo o que ele nomeia, e o evento `load` dispara de novo quando tudo chega.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" aria-label=\"Duas colunas. À esquerda, uma página por endereço: clique em Basket, um documento novo é pedido, chegam HTML, CSS e script, o evento load, a cesta é desenhada. À direita, uma página com muitos endereços: clique em Basket, history.pushState, fetch de /api/basket, a tela é redesenhada. Ao lado do pushState uma nota diz que o endereço muda e o waitForURL retorna; ao lado do último passo uma nota diz que o título Basket aparece.\"><text x=\"20\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper)\">Uma página por endereço</text><text x=\"370\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper)\">Uma página, muitos endereços</text><rect x=\"20\" y=\"48\" width=\"300\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"36\" y=\"69\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">clique em Basket</text><rect x=\"20\" y=\"98\" width=\"300\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"36\" y=\"119\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um documento novo é pedido</text><rect x=\"20\" y=\"148\" width=\"300\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"36\" y=\"169\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">chegam HTML, CSS e script</text><rect x=\"20\" y=\"198\" width=\"300\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"36\" y=\"219\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o evento load</text><rect x=\"20\" y=\"248\" width=\"300\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"36\" y=\"269\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a cesta é desenhada</text><path d=\"M170 80 L170 98 M170 130 L170 148 M170 180 L170 198 M170 230 L170 248\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"370\" y=\"48\" width=\"230\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"386\" y=\"69\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">clique em Basket</text><rect x=\"370\" y=\"98\" width=\"230\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"386\" y=\"119\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">history.pushState(…)</text><rect x=\"370\" y=\"148\" width=\"230\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"386\" y=\"169\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">fetch('/api/basket')</text><rect x=\"370\" y=\"198\" width=\"230\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"386\" y=\"219\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a tela é redesenhada</text><path d=\"M485 80 L485 98 M485 130 L485 148 M485 180 L485 198\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M604 114 L614 114\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"618\" y=\"110\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o endereço muda;</text><text x=\"618\" y=\"126\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">waitForURL retorna</text><path d=\"M604 214 L614 214\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"618\" y=\"210\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o título Basket</text><text x=\"618\" y=\"226\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">aparece</text></svg>", "caption": "O mesmo clique duas vezes. À direita, o endereço fica certo uma requisição antes da página."}
```

## Esperando a coisa errada

Num site de várias páginas, um teste que clica num link pode esperar o evento `load` da página
seguinte. **Numa SPA nada carrega.** O evento `load` disparou uma vez, quando `/spa/` abriu, e o
`pushState` não dispara outro, então `page.waitForLoadState()` depois do clique não tem o que esperar
e retorna na hora. O substituto que as pessoas procuram é `page.waitForURL`, que espera até o
endereço bater. Ele espera alguma coisa, mas a figura mostra o quê: o endereço muda no tratador de
clique, **antes** de o `fetch` da cesta sequer ter sido enviado.

Eis uma primeira tentativa escrita assim, duas vezes. O segundo teste é igual ao primeiro numa rede
mais lenta: `page.route` segura toda requisição para `/api/basket` por meio segundo antes de
deixá-la passar, que é o que um celular com sinal fraco faz com ela de qualquer jeito. Salve-o como
`tests/spa.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('Basket opens the basket', async ({ page }) => {
  await page.goto('/spa/');
  await page.getByRole('link', { name: 'Basket' }).click();
  await page.waitForURL('**/spa/basket');
  expect(await page.locator('h1').textContent()).toBe('Basket');
});

test('Basket opens the basket on a slow network', async ({ page }) => {
  await page.route('**/api/basket', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await route.continue();
  });
  await page.goto('/spa/');
  await page.getByRole('link', { name: 'Basket' }).click();
  await page.waitForURL('**/spa/basket');
  expect(await page.locator('h1').textContent()).toBe('Basket');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/spa.spec.js

Running 2 tests using 1 worker

  ✘  1 tests/spa.spec.js:3:1 › Basket opens the basket (173ms)
  ✘  2 tests/spa.spec.js:10:1 › Basket opens the basket on a slow network (186ms)


  1) tests/spa.spec.js:3:1 › Basket opens the basket ───────────────────────────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: "Basket"
    Received: "Fruit"

       5 |   await page.getByRole('link', { name: 'Basket' }).click();
       6 |   await page.waitForURL('**/spa/basket');
    >  7 |   expect(await page.locator('h1').textContent()).toBe('Basket');
         |                                                  ^
       8 | });
       9 |
      10 | test('Basket opens the basket on a slow network', async ({ page }) => {
        at /home/ana/quitanda/tests/spa.spec.js:7:50

    Error Context: test-results/spa-Basket-opens-the-basket/error-context.md

  2) tests/spa.spec.js:10:1 › Basket opens the basket on a slow network ────────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: "Basket"
    Received: "Fruit"

      16 |   await page.getByRole('link', { name: 'Basket' }).click();
      17 |   await page.waitForURL('**/spa/basket');
    > 18 |   expect(await page.locator('h1').textContent()).toBe('Basket');
         |                                                  ^
      19 | });
      20 |
        at /home/ana/quitanda/tests/spa.spec.js:18:50

    Error Context: test-results/spa-Basket-opens-the-basket-on-a-slow-network/error-context.md

  2 failed
    tests/spa.spec.js:3:1 › Basket opens the basket ────────────────────────────────────────────────
    tests/spa.spec.js:10:1 › Basket opens the basket on a slow network ─────────────────────────────
```

Os dois falham, com a mesma mensagem: o título que o teste leu foi `Fruit`, num endereço que já
dizia `/spa/basket`. O segundo falha sempre, porque a resposta da cesta é segurada por meio segundo
e o teste lê o título muito antes de ela chegar. O primeiro é uma corrida entre o teste e um
servidor na mesma máquina, e pode ir para qualquer lado de uma execução para outra; desta vez
perdeu. Um teste que passa no seu computador e falha num servidor de build mais lento é o assunto da
aula 14, e este é um dos jeitos mais comuns de escrever um.

**O endereço é um fato sobre a URL, e o título é um fato sobre a página.** A correção é esperar
aquilo de que o teste trata, com uma asserção que tenta de novo até valer. A versão abaixo mantém o
`waitForURL`, porque uma SPA que esquecesse o `pushState` desenharia a cesta no endereço errado, e
vale pegar isso, e depois verifica o título. O primeiro teste também verifica `aria-busy`, e escuta
pedidos de documento depois que a primeira página carregou, esperando nenhum. Os dois esperam as
frutas antes de clicar, para que duas telas nunca estejam carregando ao mesmo tempo; a aula 3 trata
do que acontece quando duas respostas apostam corrida. Salve-o como `tests/spa.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('Basket opens the basket without loading a page', async ({ page }) => {
  await page.goto('/spa/');
  await expect(page.getByRole('heading', { name: 'Fruit' })).toBeVisible();
  const documents = [];
  page.on('request', (request) => {
    if (request.resourceType() === 'document') documents.push(request.url());
  });

  await page.getByRole('link', { name: 'Basket' }).click();
  await page.waitForURL('**/spa/basket');
  await expect(page.getByRole('heading', { name: 'Basket' })).toBeVisible();
  await expect(page.locator('#view')).toHaveAttribute('aria-busy', 'false');
  expect(documents).toEqual([]);
});

test('Basket opens the basket on a slow network', async ({ page }) => {
  await page.route('**/api/basket', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await route.continue();
  });
  await page.goto('/spa/');
  await expect(page.getByRole('heading', { name: 'Fruit' })).toBeVisible();
  await page.getByRole('link', { name: 'Basket' }).click();
  await page.waitForURL('**/spa/basket');
  await expect(page.getByRole('heading', { name: 'Basket' })).toBeVisible();
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/spa.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/spa.spec.js:3:1 › Basket opens the basket without loading a page (196ms)
  ✓  2 tests/spa.spec.js:18:1 › Basket opens the basket on a slow network (1.0s)

  2 passed (2.6s)
```

`toBeVisible` e `toHaveAttribute` são **asserções web-first**: perguntam de novo à página até a
resposta estar certa ou o tempo acabar, cinco segundos por padrão. `expect(await …textContent())`
pergunta uma vez e compara o que veio. A aula 13 trata de espera em geral, e de por que a asserção
que tenta de novo é a primeira a usar; o ponto aqui é mais estreito. Numa SPA, **o sinal de que a
página está pronta é algo na página**, nunca a navegação.
