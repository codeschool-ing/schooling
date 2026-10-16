---
title: Anexando o que o navegador disse
version: 1
---

A aula 1 terminou com uma página cuja lista ficava vazia enquanto o Console dizia por quê: um `404`
para a lista de produtos, e o script lançando um erro ao ler `not found` como JSON. Um teste que
confere só o que vê relata *a lista está vazia* e para por aí. **O motivo foi impresso pelo
navegador, durante a execução, e ninguém estava ouvindo.** Esta seção faz o teste ouvir e põe o que
ele ouviu no relatório, ao lado da falha.

## Ouvindo, e anexando

O Playwright dá à página dois eventos para isso, os mesmos dois que o `look.mjs` usou na aula 1. O
`console` dispara para cada mensagem que a página escreve, ou que o navegador escreve sobre ela, e
o `pageerror` dispara para cada erro que os scripts da página lançaram e ninguém capturou.
Coletá-los custa duas linhas num `beforeEach`.

Pô-los no relatório é o `testInfo.attach`. Todo teste e todo hook recebem um objeto `testInfo` como
argumento depois das fixtures. O `attach` dele acrescenta um item com nome ao resultado do teste:
um `body` montado em memória, ou um `path` para um arquivo que já está no disco, com um
`contentType` dizendo o que ele é. O reporter `list` imprime um anexo de texto no terminal, e o
relatório HTML o mostra na página do teste, ao lado da captura de tela e do rastro.

O teste abaixo precisa que a página falhe, e a lista de produtos da loja funciona. Então o teste a
faz falhar: o `page.route` intercepta a requisição de `/api/products` antes de ela sair do navegador
e responde com `404` e o texto `not found`, como faria um servidor quebrado. Esse substituto do
servidor mora no teste, e o código da loja fica intocado. Salve como `evidence/errors.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

let messages = [];

// Before each test: listen to the page, as look.mjs did in lesson 1.
test.beforeEach(async ({ page }) => {
  messages = [];
  page.on('console', (m) => messages.push(`console.${m.type()}: ${m.text()}`));
  page.on('pageerror', (e) => messages.push(`pageerror: ${e.message}`));
});

// After each test, passed or failed: put what was heard into the report.
test.afterEach(async ({}, testInfo) => {
  await testInfo.attach('browser messages', {
    body: messages.join('\n') || '(none)',
    contentType: 'text/plain',
  });
});

// Fails on purpose: the product list is answered with a 404, as if the
// server had broken, and the page's script throws reading it.
test('the shop lists eight products', async ({ page }) => {
  await page.route('**/api/products', (route) => route.fulfill({ status: 404, body: 'not found' }));
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
});
```

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/errors.spec.js

Running 1 test using 1 worker

  ✘  1 evidence/errors.spec.js:22:1 › the shop lists eight products (5.6s)


  1) evidence/errors.spec.js:22:1 › the shop lists eight products ──────────────────────────────────

    Error: expect(locator).toHaveCount(expected) failed

    Locator:  locator('#products li')
    Expected: 8
    Received: 0
    Timeout:  5000ms

    Call log:
      - Expect "toHaveCount" with timeout 5000ms
      - waiting for locator('#products li')
        9 × locator resolved to 0 elements
          - unexpected value "0"


      23 |   await page.route('**/api/products', (route) => route.fulfill({ status: 404, body: 'not found' }));
      24 |   await page.goto('/');
    > 25 |   await expect(page.locator('#products li')).toHaveCount(8);
         |                                              ^
      26 | });
      27 |
        at /home/ana/quitanda/evidence/errors.spec.js:25:46

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    test-results/errors-the-shop-lists-eight-products/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    attachment #2: browser messages (text/plain) ───────────────────────────────────────────────────
    console.error: Failed to load resource: the server responded with a status of 404 (Not Found)
    pageerror: Unexpected token 'o', "not found" is not valid JSON
    ────────────────────────────────────────────────────────────────────────────────────────────────

    attachment #3: video (video/webm) ──────────────────────────────────────────────────────────────
    test-results/errors-the-shop-lists-eight-products/video.webm
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: test-results/errors-the-shop-lists-eight-products/error-context.md

    attachment #5: trace (application/zip) ─────────────────────────────────────────────────────────
    test-results/errors-the-shop-lists-eight-products/trace.zip
    Usage:

        npx playwright show-trace test-results/errors-the-shop-lists-eight-products/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────

  1 failed
    evidence/errors.spec.js:22:1 › the shop lists eight products ───────────────────────────────────

To open last HTML report run:

  npx playwright show-report
```

**O anexo #2 é o que este arquivo acrescentou**, e ele traz o diagnóstico em duas linhas: o
servidor respondeu `404`, e a página lançou um erro com a resposta. A asserção acima dele diz só
*esperava 8, recebeu 0*. Quem lê isto num servidor de build sabe onde procurar sem baixar nada, e
esse é o motivo de pôr um texto curto no terminal em vez de num arquivo que ninguém abre.

## Por que o hook é `afterEach`

O anexo é feito no `afterEach` porque um hook roda **tenha o teste passado ou falhado**. Se o
`attach` fosse a última linha do teste, nunca teria rodado: o teste parou no `expect` que falhou, e
nada depois de uma linha que falha é executado. Um teste que passa também ganha suas mensagens
anexadas, algumas centenas de bytes de texto, e um erro num teste que passa ainda merece ser visto.

O `messages` fica fora dos hooks para que os dois o alcancem, e o `beforeEach` o esvazia, porque um
worker roda os testes de um arquivo um depois do outro e a lista, sem isso, levaria as mensagens de
um teste para o seguinte.

## O rastro já as tinha

O rastro gravou os mesmos dois eventos, com seus horários, alguém os tendo anexado ou não:

```
ana@laptop:~/quitanda$ unzip -p test-results/errors-*/trace.zip 0-trace.trace | grep -o '"type":"console".\{0,150\}\|"method":"pageError".\{0,150\}'
"type":"console","messageType":"error","text":"Failed to load resource: the server responded with a status of 404 (Not Found)","args":[],"location":{"url":"http://loc
"method":"pageError","params":{"error":{"error":{"message":"Unexpected token 'o', \"not found\" is not valid JSON","stack":"","name":"Uncaught (in promise) SyntaxError"}}
```

Então o anexo não acrescenta evidência. Ele leva a mesma evidência para onde alguém lê primeiro, e
continua lá quando não há rastro, o que, com `retain-on-failure`, é o caso de todo teste que passou.

## Um erro não capturado deve reprovar o teste?

A aula 1 descreveu a posição mais forte: **um erro não capturado reprova o teste que o viu**, esteja
a página com boa aparência ou não. Com as mensagens coletadas, é uma linha a mais no fim do
`afterEach`:

```javascript
  expect(messages.filter((m) => m.startsWith('pageerror'))).toEqual([]);
```

Uma equipe que a acrescenta encontra páginas que lançam erros e ainda desenham o título, coisa que
nenhuma asserção sobre o título pegaria. Encontra também erros em código que ninguém da equipe
mantém, um widget de chat, um script de analytics, e aí precisa decidir o que fazer com eles. Essa
decisão é da equipe; a evidência para ela é o que esta seção coletou.
