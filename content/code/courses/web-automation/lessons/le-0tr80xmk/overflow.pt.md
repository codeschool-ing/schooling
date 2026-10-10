---
title: A página que rola para o lado
version: 1
---

Num celular, uma página deve rolar numa direção só: para baixo. **Uma página mais larga que a
janela também rola para o lado**, e o que fica à direita some de vista até alguém pensar em
arrastar a página, coisa que a maioria das pessoas nunca faz. É o jeito mais comum de um layout
responsivo quebrar, e o mais barato para um robô achar: dois números, comparados.

## A falha da loja

A folha de estilos da aula 1 traz uma linha marcada como falha conhecida, e esta é a aula que ela
esperava:

```css
/* A known flaw, on purpose: this line refuses to wrap. */
.basket { margin: 0 0 0 auto; white-space: nowrap; min-width: 24rem; text-align: right; }
```

`white-space: nowrap` mantém *Basket: 0 items · R$ 0,00* numa linha só aconteça o que acontecer, e
`min-width: 24rem` deixa o parágrafo com pelo menos 384 pixels CSS de largura, nos 16 pixels por
rem de costume do navegador. Some o espaçamento de 1rem do cabeçalho à esquerda e a linha precisa de
400 pixels. Numa janela de computador ninguém percebe. Numa janela de 360, a página cresce 40
pixels para a direita.

## A verificação

A largura total de uma página é `document.documentElement.scrollWidth`. Se ela for maior que a
janela, a página rola para o lado. O teste define a largura, espera os oito cartões para medir a
página pronta e não a vazia que a aula 1 descreveu, e compara. Ele vai no mesmo arquivo dos
breakpoints, abaixo deles. Salve-o como `tests/responsive.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// style.css changes the layout at (max-width: 600px): 600 is still a
// phone, 601 is not. Each side gets the width next to the line and one
// far from it.
for (const width of [360, 600]) {
  test.describe(`${width} px wide`, () => {
    test.use({ viewport: { width, height: 800 } });

    test('the links hide behind the Menu button', async ({ page }) => {
      await page.goto('/');
      const menu = page.getByRole('button', { name: 'Menu' });
      const shop = page.getByRole('link', { name: 'Shop', includeHidden: true });
      await expect(menu).toHaveAttribute('aria-expanded', 'false');
      await expect(shop).toBeHidden();
      await menu.click();
      await expect(menu).toHaveAttribute('aria-expanded', 'true');
      await expect(shop).toBeVisible();
    });
  });
}

for (const width of [601, 1280]) {
  test.describe(`${width} px wide`, () => {
    test.use({ viewport: { width, height: 800 } });

    test('the links show and the Menu button does not', async ({ page }) => {
      await page.goto('/');
      const menu = page.getByRole('button', { name: 'Menu', includeHidden: true });
      await expect(page.getByRole('link', { name: 'Shop' })).toBeVisible();
      await expect(menu).toHaveCount(1);
      await expect(menu).toBeHidden();
    });
  });
}

// Nothing may be wider than the window. Compared with the width the test
// asked for, because a phone widens its own window to fit the page.
for (const width of [360, 390, 768]) {
  test(`nothing scrolls sideways at ${width} px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 800 });
    await page.goto('/');
    await expect(page.locator('#products li')).toHaveCount(8);
    const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth);
    expect(scrollWidth, 'the page is wider than the window').toBeLessThanOrEqual(width);
  });
}
```

As três larguras são um celular pequeno, o iPhone 13 das duas últimas seções e um tablet em pé.
Rode:

```
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js

Running 7 tests using 1 worker

  ✓  1 tests/responsive.spec.js:10:5 › 360 px wide › the links hide behind the Menu button (192ms)
  ✓  2 tests/responsive.spec.js:10:5 › 600 px wide › the links hide behind the Menu button (156ms)
  ✓  3 tests/responsive.spec.js:27:5 › 601 px wide › the links show and the Menu button does not (129ms)
  ✓  4 tests/responsive.spec.js:27:5 › 1280 px wide › the links show and the Menu button does not (139ms)
  ✘  5 tests/responsive.spec.js:40:3 › nothing scrolls sideways at 360 px (127ms)
  ✘  6 tests/responsive.spec.js:40:3 › nothing scrolls sideways at 390 px (164ms)
  ✓  7 tests/responsive.spec.js:40:3 › nothing scrolls sideways at 768 px (149ms)


  1) tests/responsive.spec.js:40:3 › nothing scrolls sideways at 360 px ────────────────────────────

    Error: the page is wider than the window

    expect(received).toBeLessThanOrEqual(expected)

    Expected: <= 360
    Received:    400

      43 |     await expect(page.locator('#products li')).toHaveCount(8);
      44 |     const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth);
    > 45 |     expect(scrollWidth, 'the page is wider than the window').toBeLessThanOrEqual(width);
         |                                                              ^
      46 |   });
      47 | }
      48 |
        at /home/ana/quitanda/tests/responsive.spec.js:45:62

    Error Context: test-results/responsive-nothing-scrolls-sideways-at-360-px/error-context.md

  2) tests/responsive.spec.js:40:3 › nothing scrolls sideways at 390 px ────────────────────────────

    Error: the page is wider than the window

    expect(received).toBeLessThanOrEqual(expected)

    Expected: <= 390
    Received:    400

      43 |     await expect(page.locator('#products li')).toHaveCount(8);
      44 |     const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth);
    > 45 |     expect(scrollWidth, 'the page is wider than the window').toBeLessThanOrEqual(width);
         |                                                              ^
      46 |   });
      47 | }
      48 |
        at /home/ana/quitanda/tests/responsive.spec.js:45:62

    Error Context: test-results/responsive-nothing-scrolls-sideways-at-390-px/error-context.md

  2 failed
    tests/responsive.spec.js:40:3 › nothing scrolls sideways at 360 px ─────────────────────────────
    tests/responsive.spec.js:40:3 › nothing scrolls sideways at 390 px ─────────────────────────────
  5 passed (4.1s)
```

**400 em 360, e 400 em 390.** O mesmo número duas vezes já é uma descoberta: a página tem 400 de
largura qualquer que seja a janela, então algo nela tem um mínimo fixo, o que aponta direto para o
`min-width`. Em 768 há espaço, e passa.

**Compare com a largura que o teste pediu, nunca com `innerWidth`.** A seção sobre a viewport mediu
isso: com o descritor do iPhone 13 a loja informou uma janela de 400 dentro de uma tela de 390,
porque um celular que respeita a tag viewport alarga a janela para caber a página. Uma verificação
escrita como `scrollWidth <= innerWidth` compararia 400 com 400 nesse descritor e passaria
justamente na página que este teste existe para pegar.

## Por que esta verificação vale mais que as outras

Quase tudo o que faz um layout responsivo ser bom é questão de olhar: se uma coluna está estreita
demais, se o espaçamento agrada. Uma rolagem lateral tem **uma resposta certa, um número, em toda
largura**, e pega uma família inteira de causas com um teste só: uma largura fixa, uma palavra ou
um endereço longo que não quebra, uma tabela larga, uma imagem sem largura máxima. A falha da aula
1 é uma linha. O mesmo teste acharia qualquer uma das outras sem saber qual estava procurando.

## O que deixar no arquivo

O teste achou um defeito de verdade, e consertá-lo não cabe a um teste. Alguém o relata (a aula 15
de `manual-testing` trata do que o relato precisa ter); até o conserto, o arquivo tem de dizer
alguma coisa. Há três escolhas, e duas são piores do que parecem:

- **Pular as duas larguras.** A suíte fica verde e para de medir: se a linha da cesta crescer mais
  cem pixels, ou se alguém a consertar, nada avisa você.
- **Afirmar o defeito**, `expect(scrollWidth).toBe(400)`. A suíte fica verde e agora chama o
  defeito de correto. Uma troca de fonte que o leve a 401 derruba um teste sobre nada, e o conserto
  também falha, como regressão.
- **Marcar as larguras como falha esperada**, com `test.fail(condition, description)`. A verificação
  continua rodando em toda largura. O Playwright conta uma falha esperada como aprovada e **reprova o
  teste no dia em que ele passa**, que é o dia em que alguém consertou o CSS e a marca tem de sair.

A terceira mantém o teste honesto nas duas direções, e escreve o defeito no arquivo, onde o próximo
leitor o encontra. O arquivo como fica. Salve-o como `tests/responsive.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// style.css changes the layout at (max-width: 600px): 600 is still a
// phone, 601 is not. Each side gets the width next to the line and one
// far from it.
for (const width of [360, 600]) {
  test.describe(`${width} px wide`, () => {
    test.use({ viewport: { width, height: 800 } });

    test('the links hide behind the Menu button', async ({ page }) => {
      await page.goto('/');
      const menu = page.getByRole('button', { name: 'Menu' });
      const shop = page.getByRole('link', { name: 'Shop', includeHidden: true });
      await expect(menu).toHaveAttribute('aria-expanded', 'false');
      await expect(shop).toBeHidden();
      await menu.click();
      await expect(menu).toHaveAttribute('aria-expanded', 'true');
      await expect(shop).toBeVisible();
    });
  });
}

for (const width of [601, 1280]) {
  test.describe(`${width} px wide`, () => {
    test.use({ viewport: { width, height: 800 } });

    test('the links show and the Menu button does not', async ({ page }) => {
      await page.goto('/');
      const menu = page.getByRole('button', { name: 'Menu', includeHidden: true });
      await expect(page.getByRole('link', { name: 'Shop' })).toBeVisible();
      await expect(menu).toHaveCount(1);
      await expect(menu).toBeHidden();
    });
  });
}

// Nothing may be wider than the window. Compared with the width the test
// asked for, because a phone widens its own window to fit the page.
// A known defect, reported and not fixed yet: .basket in style.css does
// not wrap and is 24rem wide, so these widths are expected to fail. The
// day one of them passes, Playwright fails it, and this list shrinks.
const overflows = [360, 390];

for (const width of [360, 390, 768]) {
  test(`nothing scrolls sideways at ${width} px`, async ({ page }) => {
    test.fail(overflows.includes(width), 'known defect: .basket is wider than a phone');
    await page.setViewportSize({ width, height: 800 });
    await page.goto('/');
    await expect(page.locator('#products li')).toHaveCount(8);
    const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth);
    expect(scrollWidth, 'the page is wider than the window').toBeLessThanOrEqual(width);
  });
}
```

```
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js

Running 7 tests using 1 worker

  ✓  1 tests/responsive.spec.js:10:5 › 360 px wide › the links hide behind the Menu button (234ms)
  ✓  2 tests/responsive.spec.js:10:5 › 600 px wide › the links hide behind the Menu button (194ms)
  ✓  3 tests/responsive.spec.js:27:5 › 601 px wide › the links show and the Menu button does not (126ms)
  ✓  4 tests/responsive.spec.js:27:5 › 1280 px wide › the links show and the Menu button does not (144ms)
  ✘  5 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (147ms)
  ✘  6 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (126ms)
  ✓  7 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (129ms)

  7 passed (2.6s)
```

Sete passaram, e a lista ainda desenha as duas falhas conhecidas com um X, então elas continuam
visíveis em toda execução. Este é o mesmo arquivo no dia em que as duas declarações de `.basket`
são apagadas:

```
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js

Running 7 tests using 1 worker

  ✓  1 tests/responsive.spec.js:10:5 › 360 px wide › the links hide behind the Menu button (244ms)
  ✓  2 tests/responsive.spec.js:10:5 › 600 px wide › the links hide behind the Menu button (148ms)
  ✓  3 tests/responsive.spec.js:27:5 › 601 px wide › the links show and the Menu button does not (115ms)
  ✓  4 tests/responsive.spec.js:27:5 › 1280 px wide › the links show and the Menu button does not (119ms)
  ✓  5 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (142ms)
  ✓  6 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (169ms)
  ✓  7 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (154ms)


  1) tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px ────────────────────────────

    Expected to fail, but passed.

  2) tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px ────────────────────────────

    Expected to fail, but passed.

  2 failed
    tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px ─────────────────────────────
    tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px ─────────────────────────────
  5 passed (4.1s)
```

**Expected to fail, but passed.** A suíte fica vermelha até alguém tirar 360 e 390 de `overflows`,
que é o momento em que o conserto é notado e o teste volta a vigiar a linha. `test.fail` é para uma
falha que você entende e espera em toda execução. Um teste que falha só às vezes é o tema da aula
14, e esta marca é a ferramenta errada para ele.
