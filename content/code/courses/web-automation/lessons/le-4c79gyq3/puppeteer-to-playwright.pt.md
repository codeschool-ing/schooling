---
title: Do Puppeteer ao Playwright, linha a linha
version: 1
---

O Playwright começou na Microsoft com engenheiros que tinham feito o Puppeteer no Google, e as duas
bibliotecas ainda se parecem: `launch()`, `newPage()`, `goto()` e `click()` estão nas duas. **A
semelhança de família deixa as diferenças fáceis de ler**: cada uma é uma lição que os autores
tiraram do Puppeteer, e a maioria delas é sobre esperar.

Aqui está a mesma verificação como um teste Playwright: esvaziar a cesta, abrir a loja, pôr uma
banana e esperar que a contagem diga 1. Salve-o como `tests/banana.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('a banana goes into the basket', async ({ page, request }) => {
  await request.post('/api/reset');
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/banana.spec.js

Running 1 test using 1 worker

  ✓  1 tests/banana.spec.js:3:1 › a banana goes into the basket (264ms)

  1 passed (1.6s)
```

Quatro linhas dentro do teste, e nenhuma espera escrita à mão. Lado a lado:

| o passo | Puppeteer | Playwright Test |
|---|---|---|
| abrir um navegador | `puppeteer.launch()` e `browser.newPage()` | a fixture `page`: o executor abre uma e a fecha |
| esvaziar a cesta | o `fetch` do Node, com o endereço inteiro | a fixture `request`, com o `baseURL` da configuração |
| achar o botão | uma string CSS, `[data-testid=product-banana] button` | um **localizador**: o cartão pelo test id, depois o botão pelo papel e pelo nome |
| esperar por ele | `waitForSelector`, escrito por você | embutido no `click()`: espera o botão existir, estar visível, habilitado e parado |
| verificar a contagem | `waitForFunction` na página, depois `$eval` para ler | `expect(...).toHaveText('1')`, que tenta de novo até bater ou estourar o tempo |
| relatar | `console.log`, lido por uma pessoa | um nome de teste, ✓ ou ✘, e o resumo do executor |

**O que mudou foi onde a espera mora.** No Puppeteer, um script que esquece uma espera continua
rodando e, como a seção anterior mostrou, dá a resposta que a corrida der. No Playwright a ação
espera o elemento antes de agir, e uma asserção que começa com `expect(locator)` continua
perguntando até a página concordar ou o tempo acabar; a documentação do Playwright chama isso de
**web-first assertions**, asserções que esperam pela página. A remoção que você fez à mão na seção
anterior não tem equivalente aqui: não existe linha para apagar.

**Os localizadores são a segunda mudança.** Um seletor do Puppeteer é uma string com que a página é
vasculhada uma vez. Um localizador do Playwright é uma descrição, *o botão chamado Add to basket
dentro do cartão da banana*, procurada de novo a cada uso, então sobrevive à página redesenhar o
cartão. Ele também prefere o que uma pessoa vê, um papel e um nome, à estrutura da página; a aula 2
trata de por que isso aguenta melhor.

**E o executor é a terceira.** As fixtures, os workers em paralelo, as novas tentativas e o
relatório vêm todos do Playwright Test. O Puppeteer deixa cada uma dessas coisas para o executor
que você puser em volta dele.

**O Puppeteer também andou**, e a comparação seria injusta sem dizer isso. A versão que você
instalou tem `page.locator()`, e a documentação dele diz que uma ação sobre ele é repetida até o
elemento estar pronto, verificando as condições de que um clique precisa. Neste script, ele
trocaria a linha do `waitForSelector` e o clique por uma linha só. O que ele ainda não tem é uma
asserção que espera, nem um executor. O Puppeteer continua biblioteca; o Playwright virou framework.

O `tests/banana.spec.js` reinicia a cesta compartilhada, então pode atrapalhar outro teste que
esteja usando a cesta no mesmo momento. É a falha não marcada da loja, da aula 1, e as aulas 15 e
19 tratam dela.
