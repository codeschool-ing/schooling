---
title: Com o JavaScript desligado
version: 1
---

Algumas visitas a uma página não rodam script nenhum. Um navegador pode estar com o JavaScript
desligado, e numa conexão ruim o script pode não chegar enquanto o HTML chegou. Montar uma página
que funciona primeiro como HTML puro e melhora quando um script roda se chama **aprimoramento
progressivo**, e renderizar no servidor é o que torna isso possível: uma lista vazia não tem o que
aprimorar.

## Um contexto sem JavaScript

Todo teste do Playwright ganha seu próprio **contexto de navegador**, um perfil isolado com seus
próprios cookies e configurações; a aula 10 explica os contextos direito. Uma dessas configurações é
`javaScriptEnabled`, e o `test.use` a define para todos os testes de um arquivo, ou de um grupo
`test.describe` quando é escrito dentro dele. Toda página que esses testes abrem então não roda
script nenhum, nem o embutido. Salve-o como `tests/no-script.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Every page in this file opens in a browser with JavaScript switched off.
test.use({ javaScriptEnabled: false });

test('/ssr lists its eight products without a script', async ({ page }) => {
  await page.goto('/ssr');
  await expect(page.locator('#products li')).toHaveCount(8);
  await expect(page.getByTestId('product-banana')).toContainText('Banana');
});

// A fact about the home page today, not a requirement anybody wrote.
test('/ lists nothing without a script', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(0);
  await expect(page.locator('#products')).toHaveAttribute('aria-busy', 'true');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/no-script.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/no-script.spec.js:6:1 › /ssr lists its eight products without a script (121ms)
  ✓  2 tests/no-script.spec.js:13:1 › / lists nothing without a script (103ms)

  2 passed (1.4s)
```

Os dois passam, e dizem coisas opostas sobre as duas páginas. `/ssr` lista os oito produtos sem
script; `/` não lista nenhum, e a lista dela ainda diz `aria-busy="true"`, porque nada rodou para
mudar isso.

## O que o primeiro teste prova

Ele prova que o **conteúdo** de `/ssr` sobrevive sem script: quem lê vê os oito produtos e seus
preços. Ele não prova que a página **funciona**. Com o JavaScript desligado, os botões Add to basket
de `/ssr` não fazem nada enquanto a página estiver aberta, porque o script que lhes dá uma função
nunca roda. Uma página feita para o aprimoramento progressivo poria cada botão dentro de um `<form>`
que envia ao servidor, para que um clique funcione com ou sem script. A quitanda não faz isso, e o
teste não diz nada a respeito.

**Um teste prova o que ele afirma e nada além**, e o nome do primeiro teste foi escolhido para dizer
exatamente isso: ele lista produtos. Um teste chamado "a loja funciona sem JavaScript" com o mesmo
corpo afirmaria algo que ninguém verificou.

A correção da seção anterior também tem um custo aqui. Com os botões enviados desabilitados, uma
visita sem script mostraria oito botões que nunca podem ser apertados, o que é honesto, e não mais
útil do que antes. Cada tipo de leitor recebe uma página diferente, e um teste para cada tipo é como
uma equipe descobre o que uma mudança faz com os outros.

## Para que serve o segundo teste

O segundo teste registra um fato, e não um requisito, e o comentário dele diz isso. Ninguém quer a
página inicial vazia, mas ela está, e o teste fixa isso. No dia em que a equipe decidir que a
página inicial precisa listar os produtos sem JavaScript, este é o teste que falha primeiro e é
virado ao contrário. Sem o comentário, a próxima pessoa a lê-lo poderia tomá-lo por um requisito e
defendê-lo.
