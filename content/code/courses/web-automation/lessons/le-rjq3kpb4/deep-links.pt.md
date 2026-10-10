---
title: O endereço que ninguém consegue abrir
version: 1
---

Os endereços de uma SPA existem só dentro do script dela. `/spa/basket` é uma chave do objeto
`pages` de `spa.js`, e o servidor nunca ouviu falar dele. Clicar em **Basket** funciona porque o
clique nunca chega ao servidor. **Recarregar a página chega**, e também colar o endereço numa aba
nova, seguir um favorito ou abrir um link que alguém mandou: cada um pede `/spa/basket` ao servidor
como documento, e o servidor responde o que responde para qualquer arquivo que não tem.

A crença que isso quebra é a de que um endereço que funcionou uma vez funciona sempre. É também o
defeito que um clique a clique, à mão ou por robô, está montado para não ver: todo teste até aqui
começa em `/spa/` e clica.

## O 404

O `look.mjs` da aula 1 aceita um endereço como argumento. Com este, e a loja iniciada:

```
ana@laptop:~/quitanda$ node look.mjs http://localhost:3000/spa/basket
   12 ms  404 GET /spa/basket  (document)
   13 ms  console.error: Failed to load resource: the server responded with a status of 404 (Not Found)
```

**Uma linha, um 404 para o documento**, e nada depois: nenhuma folha de estilos, nenhum script,
porque a página que os nomearia nunca chegou. Num navegador você vê o `not found` simples da loja e
mais nada, o que o navegador também registra no console. É uma falha conhecida, de propósito, e o
`catch` de `serveFile` em `app/server.js` é de onde ela vem: o servidor procura um arquivo chamado
`basket` em `app/public/spa/`, não acha nenhum, e diz isso.

## Um teste que sabe do defeito

O teste a escrever é o do comportamento que você quer: abrir `/spa/basket` direto, esperar um 200 e
a cesta. Hoje ele falha, e há duas maneiras honestas de mantê-lo na suíte.

- **Afirmar o defeito como comportamento atual**: esperar o 404. A suíte fica verde, e o teste é um
  registro do que o app faz. No dia em que um desenvolvedor corrigir o servidor, esse teste falha
  com uma mensagem que parece exatamente uma regressão, e alguém precisa descobrir que o vermelho é
  boa notícia.
- **Escrever o teste do comportamento certo e marcá-lo com `test.fail()`**, que avisa ao Playwright
  que o teste deve falhar. A suíte fica verde enquanto ele falha. No dia em que ele passar, o
  Playwright o relata como falha, *expected to fail, but passed*, que é o sinal para tirar a marca.

Esta aula fica com a segunda. O teste diz o que o app deve fazer, então nunca precisa ser reescrito,
e a marca é uma linha com o motivo dentro, fácil de achar numa busca. A fraqueza dela é real:
**qualquer falha satisfaz o `test.fail()`**, então um teste quebrado por outro motivo, um título
renomeado ou um servidor que não subiu, também passaria. Mantenha um teste assim curto, e faça da
primeira verificação o próprio sintoma, o status. Salve-o como `tests/spa.spec.js`:

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

test('the basket opens from its own address', async ({ page }) => {
  test.fail(true, 'known defect: the server has no fallback for /spa/basket');
  const response = await page.goto('/spa/basket');
  expect(response.status()).toBe(200);
  await expect(page.getByRole('heading', { name: 'Basket' })).toBeVisible();
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/spa.spec.js

Running 3 tests using 1 worker

  ✓  1 tests/spa.spec.js:3:1 › Basket opens the basket without loading a page (204ms)
  ✓  2 tests/spa.spec.js:18:1 › Basket opens the basket on a slow network (1.0s)
  ✘  3 tests/spa.spec.js:30:1 › the basket opens from its own address (107ms)

  3 passed (2.8s)
```

Três testes, e o resumo diz `3 passed`, embora a terceira linha leve um `✘`. O xis é a verdade
sobre o teste: ele falhou. O resumo o conta como aprovado porque falhou como declarado. Leia os
dois, porque uma execução que diz `3 passed` ainda pode carregar um defeito conhecido, e a marca é
onde a suíte diz qual.

## A correção é do servidor

O remédio é uma regra no servidor, em geral chamada de **fallback**: um endereço sob o caminho do app
que não é arquivo é respondido com o `index.html` do app, e o script, lendo `location.pathname`,
desenha a tela certa. Todo servidor web e todo host estático têm um jeito de dizer isso, e qual se
aplica depende de onde o app é publicado. A mudança é do desenvolvedor, e a parte do testador é o
teste acima e um relatório de defeito que diga os passos: abrir o endereço direto, ver o 404. A aula
15 de `manual-testing` trata desse relatório.

Para ver a marca fazer o seu trabalho, uma rota pode fazer as vezes da correção. O arquivo abaixo
responde `/spa/basket` com a página do app, que é o menor fallback que faz o teste passar. Ele não faz
parte do seu projeto: salve-o em `app/routes/` como `spa-fallback.js` por uma execução, e apague-o
depois:

```javascript
// Not part of quitanda: the developer's fix, for one run.
import fs from 'node:fs/promises';
import path from 'node:path';

const page = path.join(import.meta.dirname, '..', 'public', 'spa', 'index.html');

export const routes = [{
  method: 'GET', path: '/spa/basket',
  handle: async ({ res }) => {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(await fs.readFile(page));
  },
}];
```

```
ana@laptop:~/quitanda$ npx playwright test tests/spa.spec.js

Running 3 tests using 1 worker

  ✓  1 tests/spa.spec.js:3:1 › Basket opens the basket without loading a page (191ms)
  ✓  2 tests/spa.spec.js:18:1 › Basket opens the basket on a slow network (1.0s)
  ✓  3 tests/spa.spec.js:30:1 › the basket opens from its own address (101ms)


  1) tests/spa.spec.js:30:1 › the basket opens from its own address ────────────────────────────────

    Expected to fail, but passed.

  1 failed
    tests/spa.spec.js:30:1 › the basket opens from its own address ─────────────────────────────────
  2 passed (2.5s)
```

Com o fallback no lugar, o terceiro teste passa, a linha dele ganha um tique, e a execução falha:
`Expected to fail, but passed.`, com `1 failed` no resumo. Esse vermelho é a mensagem que a marca
existe para mandar: o defeito foi corrigido, então apague a linha do `test.fail`. Com o arquivo da
rota apagado de novo, a loja volta ao seu 404.

Um fallback de verdade responde **todo** endereço desconhecido sob `/spa/`, e isso tem uma
consequência própria: `/spa/nonsense` passa a responder 200, e a única coisa que diz *não
encontrado* é a tela do próprio app, o título `Not found` no fim de `show()`. Uma suíte para um app
com fallback verifica essa tela também, porque o código de status já não consegue dizer isso.
