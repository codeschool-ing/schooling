---
title: Os testes óbvios, e como eles decidem
version: 1
---

Os primeiros testes que qualquer um escreve contra uma página assim digitam a palavra, olham a
lista e verificam que ela tem uma fruta. **O problema está em *olham*.** Cada uma das maneiras óbvias
de olhar escolhe um momento, e a seção anterior mostrou que a lista diz coisas diferentes em
momentos diferentes. Um teste que escolhe um momento está medindo o momento.

Esta versão do arquivo de testes tem quatro deles. Três digitam a palavra tecla por tecla com
`pressSequentially`, que dispara um evento `input` por tecla como a digitação de uma pessoa, e só
diferem em quando leem a lista: na hora, depois de meio segundo, depois de um segundo inteiro. O
quarto usa `fill`, que põe a palavra inteira na caixa de uma vez, e espera um segundo. Todos leem a
lista com `count()`, que conta **uma vez** e responde. Salve como `tests/search.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/search.html');
});

test('reads the list as soon as the typing ends', async ({ page }) => {
  await page.getByLabel('Fruit').pressSequentially('papaya');
  expect(await page.locator('#results li').count()).toBe(1);
});

test('sleeps half a second, then reads', async ({ page }) => {
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await page.waitForTimeout(500);
  expect(await page.locator('#results li').count()).toBe(1);
});

test('sleeps a whole second, then reads', async ({ page }) => {
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await page.waitForTimeout(1000);
  expect(await page.locator('#results li').count()).toBe(1);
});

test('fills the box, sleeps a second, then reads', async ({ page }) => {
  await page.getByLabel('Fruit').fill('papaya');
  await page.waitForTimeout(1000);
  expect(await page.locator('#results li').count()).toBe(1);
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/search.spec.js

Running 4 tests using 1 worker

  ✘  1 tests/search.spec.js:7:1 › reads the list as soon as the typing ends (184ms)
  ✓  2 tests/search.spec.js:12:1 › sleeps half a second, then reads (673ms)
  ✘  3 tests/search.spec.js:18:1 › sleeps a whole second, then reads (1.2s)
  ✓  4 tests/search.spec.js:24:1 › fills the box, sleeps a second, then reads (1.2s)


  1) tests/search.spec.js:7:1 › reads the list as soon as the typing ends ──────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: 1
    Received: 0

       7 | test('reads the list as soon as the typing ends', async ({ page }) => {
       8 |   await page.getByLabel('Fruit').pressSequentially('papaya');
    >  9 |   expect(await page.locator('#results li').count()).toBe(1);
         |                                                     ^
      10 | });
      11 |
      12 | test('sleeps half a second, then reads', async ({ page }) => {
        at /home/ana/quitanda/tests/search.spec.js:9:53

    Error Context: test-results/search-reads-the-list-as-soon-as-the-typing-ends/error-context.md

  2) tests/search.spec.js:18:1 › sleeps a whole second, then reads ─────────────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: 1
    Received: 3

      19 |   await page.getByLabel('Fruit').pressSequentially('papaya');
      20 |   await page.waitForTimeout(1000);
    > 21 |   expect(await page.locator('#results li').count()).toBe(1);
         |                                                     ^
      22 | });
      23 |
      24 | test('fills the box, sleeps a second, then reads', async ({ page }) => {
        at /home/ana/quitanda/tests/search.spec.js:21:53

    Error Context: test-results/search-sleeps-a-whole-second-then-reads/error-context.md

  2 failed
    tests/search.spec.js:7:1 › reads the list as soon as the typing ends ───────────────────────────
    tests/search.spec.js:18:1 › sleeps a whole second, then reads ──────────────────────────────────
  2 passed (6.3s)
```

## Quatro vereditos, uma página

Dois falharam e dois passaram, e nenhum dos quatro disse nada de verdadeiro sobre a busca.

**Ler na hora falhou com `Received: 0`.** O `pressSequentially` retorna quando a última tecla foi
apertada, e nesse momento nenhuma resposta voltou: a lista está vazia. O teste não achou um
defeito; achou que tinha olhado antes de a página poder responder.

**Meio segundo passou, e um segundo inteiro falhou com `Received: 3`.** Mesma página, mesma
digitação, vereditos opostos, e a única diferença é o número no `waitForTimeout`. A figura da seção
anterior diz por quê: aos 500 ms a lista por acaso tinha Papaya, e aos 1000 ms tinha as três frutas
em que termina. **A aprovação é a mais perigosa das duas**, porque é a que ninguém investiga. Ela
entra na suíte, continua verde e relata uma busca correta numa página que mostra a fruta errada a
quem digita rápido. Num servidor mais lento, em que toda resposta chega mais tarde, ela poderia
perfeitamente falhar, e aí falharia *às vezes*, que é o assunto da aula 14.

**O `fill` passou, por um motivo que não tem nada a ver com a espera.** É o quarto teste o que mais
importa, porque é o que muita gente escreveria primeiro.

## Por que o `fill` esconde a corrida

O `fill` é o jeito habitual de digitar numa caixa no Playwright, e para a maioria das caixas é o
certo: é rápido e define o valor como colar faz. **É exatamente por isso que ele nunca encontra
este defeito.** Uma mudança de valor é um evento `input`, uma requisição, uma resposta, e nada com
que disputar. O teste passa, e a página em que passou é a página que mostra três frutas a quem
digita rápido.

O `pressSequentially` existe para o caso oposto: uma página que reage a cada tecla, como uma caixa
de busca que sugere enquanto você digita. Nenhum dos dois métodos é o certo em geral. **Um teste
deve digitar como os usuários da página digitam sempre que a página reage ao jeito como eles
digitam**, e uma caixa de busca que envia uma requisição por tecla é uma página assim. Testá-la só
com `fill` testa o único jeito de digitar, colar, que não pode encontrar o defeito.
