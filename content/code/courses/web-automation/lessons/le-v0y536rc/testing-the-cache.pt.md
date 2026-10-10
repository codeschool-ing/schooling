---
title: Testando o cache de propósito
version: 1
---

Um cache pode ser testado de dois jeitos, e uma suíte quer os dois. **A promessa** é o cabeçalho que
o servidor manda: barata de verificar, exata, e causa de todo o resto. **A consequência** é o que um
cliente que volta vê: mais lenta de testar, e a única prova de que a promessa faz o que você acha.

## A promessa, sem navegador

A fixture `request` manda requisições HTTP do próprio teste, sem navegador e **sem cache de tipo
nenhum**, então vê exatamente o que o servidor diz, toda vez. O `response.headers()` devolve os
cabeçalhos com os nomes em minúsculas. Uma página também consegue lê-los, pela resposta que o
`page.waitForResponse` devolve, mas as respostas de uma página podem sair do cache dela, que é
justamente o que está em dúvida; a `request` pergunta ao servidor.

## Um teste que espera falhar

O teste do cliente que volta, da seção anterior, está certo: descreve o que a loja deveria fazer. A
loja ainda não faz, e apagar o teste jogaria fora o achado. O **`test.fail()`** diz exatamente isso:
este teste deve falhar, e eis o porquê. A execução o conta como aprovado enquanto ele falha, e o acusa
como falha **no dia em que passar**, que é o dia em que alguém corrigiu a falha e a marca tem de sair.
Um teste desligado com `test.skip()` não diria nada nesse dia.

## O arquivo inteiro

A versão final mantém o primeiro teste, marca o cliente que volta e acrescenta três: o cabeçalho da
oferta, marcado do mesmo jeito; o cabeçalho de um arquivo estático e o seu `304`, que a loja acerta;
e o cliente que volta mais uma vez, com rotas ligadas, que a próxima seção explica. Salve-o como
`tests/cache.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a new offer reaches the page', async ({ page, request }) => {
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});

test('a returning customer sees the new offer', async ({ page, request }) => {
  test.fail(true, 'known flaw: GET /api/offer may be kept for ten minutes');
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Mango');
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});

test('the offer is checked with the server before it is reused', async ({ request }) => {
  test.fail(true, 'known flaw: GET /api/offer may be kept for ten minutes');
  const response = await request.get('/api/offer');
  expect(response.headers()['cache-control']).toMatch(/no-cache|no-store/);
});

test('a static file is reused only when the server agrees', async ({ request }) => {
  const first = await request.get('/style.css');
  expect(first.headers()['cache-control']).toBe('no-cache');
  const etag = first.headers()['etag'];
  expect(etag).toBeTruthy();

  const again = await request.get('/style.css', { headers: { 'If-None-Match': etag } });
  expect(again.status()).toBe(304);
});

// The returning customer again, with routing switched on. It passes, and
// that is the warning: routing turns the browser's cache off.
test('routing hides the flaw', async ({ page, request }) => {
  await page.route('**/*', (route) => route.continue());
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Mango');
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});
```

Inicie a loja num terminal com o log ligado e rode o arquivo de outro; o Playwright encontra a loja
já escutando e a usa:

```
ana@laptop:~/quitanda$ npx playwright test tests/cache.spec.js

Running 5 tests using 1 worker

  ✓  1 tests/cache.spec.js:7:1 › a new offer reaches the page (174ms)
  ✘  2 tests/cache.spec.js:13:1 › a returning customer sees the new offer (5.2s)
  ✘  3 tests/cache.spec.js:22:1 › the offer is checked with the server before it is reused (11ms)
  ✓  4 tests/cache.spec.js:28:1 › a static file is reused only when the server agrees (13ms)
  ✓  5 tests/cache.spec.js:40:1 › routing hides the flaw (185ms)

  5 passed (6.7s)
```

**Dois xis, e cinco aprovados.** O `✘` marca os dois testes que falharam, e a contagem diz aprovados
porque os dois falharam como estavam marcados para falhar. Leia o xis como *a falha ainda está lá*.

O terminal da loja mostra o que cada teste fez. Os dois primeiros `GET /api/products` são o
Playwright conferindo se a loja está de pé; depois disso, cada teste começa com o seu
`POST /api/reset`:

```
ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start

> start
> node app/server.js

quitanda is listening on http://localhost:3000
GET /api/products 200
GET /api/products 200
POST /api/reset 200
POST /api/offer 200
GET /offer.html 200
GET /style.css 200
GET /api/offer 200
POST /api/reset 200
GET /offer.html 200
GET /style.css 200
GET /api/offer 200
POST /api/offer 200
GET /offer.html 304
GET /style.css 304
POST /api/reset 200
GET /api/offer 200
POST /api/reset 200
GET /style.css 200
GET /style.css 304
POST /api/reset 200
GET /offer.html 200
GET /style.css 200
GET /api/offer 200
POST /api/offer 200
GET /offer.html 200
GET /style.css 200
GET /api/offer 200
```

- **o cliente que volta**, o segundo bloco, pediu de novo a página e a folha de estilos e recebeu
  `304` para as duas, e **nunca pediu a oferta uma segunda vez**. É a falha, nas palavras do próprio
  servidor;
- **os testes de cabeçalho** pediram `/api/offer` uma vez, e `style.css` duas: a segunda com a
  impressão digital, respondida com `304`;
- **o teste com rota**, o último bloco, pediu tudo de novo na segunda visita, tudo `200`, sem nenhum
  `304`: a rota desligou o cache tão completamente que o navegador nem guardou cópia sobre a qual
  perguntar.

## O dia em que a falha é corrigida

Para ver o que as marcas fazem, imagine que alguém troca `max-age=600` por `no-cache` em
`app/routes/offer.js` e reinicia a loja. Esta execução foi feita com essa troca, depois desfeita:

```
ana@laptop:~/quitanda$ npx playwright test tests/cache.spec.js

Running 5 tests using 1 worker

  ✓  1 tests/cache.spec.js:7:1 › a new offer reaches the page (168ms)
  ✓  2 tests/cache.spec.js:13:1 › a returning customer sees the new offer (145ms)
  ✓  3 tests/cache.spec.js:22:1 › the offer is checked with the server before it is reused (43ms)
  ✓  4 tests/cache.spec.js:28:1 › a static file is reused only when the server agrees (49ms)
  ✓  5 tests/cache.spec.js:40:1 › routing hides the flaw (236ms)


  1) tests/cache.spec.js:13:1 › a returning customer sees the new offer ────────────────────────────

    Expected to fail, but passed.

  2) tests/cache.spec.js:22:1 › the offer is checked with the server before it is reused ───────────

    Expected to fail, but passed.

  2 failed
    tests/cache.spec.js:13:1 › a returning customer sees the new offer ─────────────────────────────
    tests/cache.spec.js:22:1 › the offer is checked with the server before it is reused ────────────
  3 passed (3.2s)
```

Todo teste ganhou um visto, e dois deles são acusados como falha mesmo assim, cada um com a mesma
linha: **`Expected to fail, but passed.`**, esperava falhar, mas passou. É a execução dizendo a quem
corrigiu a falha que tire as linhas `test.fail`, e depois disso o arquivo descreve uma loja sem essa
falha.
