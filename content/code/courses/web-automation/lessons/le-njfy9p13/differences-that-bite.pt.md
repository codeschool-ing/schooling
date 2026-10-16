---
title: Diferenças que mordem
version: 1
---

A crença confortável é que um teste que passa headless passa com janela, e vice-versa, porque é o
mesmo navegador. **O motor é o mesmo; a janela, o nome e as fontes não são**, e um teste que
depende de qualquer um dos três pode passar num modo e falhar no outro. Aqui está um que faz isso,
escrito do jeito que alguém diante de um monitor grande escreveria.

## Um teste que confia na janela

O teste verifica que os oito produtos cabem na primeira tela, sem nada para rolar. Quem o escreveu
desligou o viewport do Playwright porque queria *a janela de verdade*, a que via na própria mesa.
Salve-o como `tests/headless.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// No viewport: the page is as big as the browser's window, whatever that is.
test.use({ viewport: null });

test('every product is fully on the first screen', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
  await expect(page.getByTestId('product-pineapple')).toBeInViewport({ ratio: 1 });
});
```

O `toBeInViewport({ ratio: 1 })` passa quando o elemento inteiro está dentro da área visível; o
abacaxi é o último cartão, então, se ele cabe, todos cabem. No modo padrão, o headless shell:

```
ana@laptop:~/quitanda$ npx playwright test tests/headless.spec.js

Running 1 test using 1 worker

  ✓  1 tests/headless.spec.js:6:1 › every product is fully on the first screen (192ms)

  1 passed (1.7s)
```

No novo headless, pelos projetos do `headless.config.js`:

```
ana@laptop:~/quitanda$ npx playwright test --config headless.config.js --project=new-headless tests/headless.spec.js

Running 1 test using 1 worker

  ✘  1 [new-headless] › tests/headless.spec.js:6:1 › every product is fully on the first screen (5.5s)


  1) [new-headless] › tests/headless.spec.js:6:1 › every product is fully on the first screen ──────

    Error: expect(locator).toBeInViewport() failed

    Locator:  getByTestId('product-pineapple')
    Expected: in viewport
    Received: viewport ratio 0.36936089396476746
    Timeout:  5000ms

    Call log:
      - Expect "toBeInViewport" with timeout 5000ms
      - waiting for getByTestId('product-pineapple')
        9 × locator resolved to <li class="card" id="card-5500" data-testid="product-pineapple">…</li>
          - unexpected value "viewport ratio 0.36936089396476746"


       7 |   await page.goto('/');
       8 |   await expect(page.locator('#products li')).toHaveCount(8);
    >  9 |   await expect(page.getByTestId('product-pineapple')).toBeInViewport({ ratio: 1 });
         |                                                       ^
      10 | });
      11 |
        at /home/ana/quitanda/tests/headless.spec.js:9:55

    Error Context: test-results/headless-every-product-is-fully-on-the-first-screen-new-headless/error-context.md

  1 failed
    [new-headless] › tests/headless.spec.js:6:1 › every product is fully on the first screen ───────
```

E com janela, sob o Xvfb:

```
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed tests/headless.spec.js

Running 1 test using 1 worker

  ✓  1 tests/headless.spec.js:6:1 › every product is fully on the first screen (340ms)

  1 passed (1.9s)
```

**Passa, falha, passa, e a loja não mudou.** A falha diz quanto do cartão conseguiu ver:
`viewport ratio 0.369…`, pouco mais de um terço. A seção sobre os dois Chromiums headless mediu o
porquê. Cada modo inventa uma janela, e o novo headless inventa a mais baixa, de 493 pixels. Com
780 de largura, a grade da loja põe três produtos por linha. O abacaxi está na terceira:

```
ana@laptop:~/quitanda$ node -e "import('@playwright/test').then(async ({ chromium }) => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 780, height: 493 } }); await p.goto('http://localhost:3000/'); console.log(await p.getByTestId('product-pineapple').boundingBox()); await b.close(); })"
{ x: 270.65625, y: 443.875, width: 238.671875, height: 133 }
```

O topo em 443,875 e a altura de 133 põem a base dele em 576,875: além dos 493 do novo headless, antes
dos 600 do shell e bem antes dos 917 da janela no Xvfb.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 1080 300\" role=\"img\" aria-label=\"Quatro retângulos na mesma escala, todos a partir do topo: a janela do shell, 800 por 600; o novo headless, 780 por 493; com janela no Xvfb, 1050 por 917; e o viewport do Playwright, 1280 por 720. Nos dois primeiros, com cerca de 800 de largura e três produtos por linha, uma faixa marca o cartão do abacaxi, de 443,875 a 576,875 pixels para baixo. Ela cabe na janela do shell e é cortada pela borda de baixo do novo headless, em 493. Os dois retângulos maiores contêm o cartão inteiro.\"><rect x=\"20\" y=\"40\" width=\"200\" height=\"150\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o shell</text><text x=\"20\" y=\"32\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">800x600</text><rect x=\"26\" y=\"151\" width=\"48\" height=\"33\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"></rect><text x=\"20\" y=\"290\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">inteiro dentro</text><rect x=\"238.0\" y=\"40\" width=\"195\" height=\"123\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"238.0\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">novo headless</text><text x=\"238.0\" y=\"32\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">780x493</text><rect x=\"244.0\" y=\"151\" width=\"48\" height=\"33\" fill=\"var(--scan)\" stroke=\"var(--amber)\"></rect><text x=\"238.0\" y=\"290\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">cortado em 493</text><rect x=\"451.0\" y=\"40\" width=\"262\" height=\"229\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"451.0\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">com janela, Xvfb</text><text x=\"451.0\" y=\"32\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1050x917</text><text x=\"451.0\" y=\"290\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">inteiro dentro</text><rect x=\"731.5\" y=\"40\" width=\"320\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"731.5\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">viewport do Playwright</text><text x=\"731.5\" y=\"32\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1280x720</text><text x=\"731.5\" y=\"290\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">inteiro dentro</text><text x=\"80\" y=\"169\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cartão do abacaxi</text></svg>", "caption": "Cada modo inventa a própria janela, e só uma delas corta o cartão. O viewport padrão do Playwright é o mesmo retângulo nos três."}
```

**O teste nunca foi sobre a loja**; era sobre a janela que o navegador por acaso abriu. Na mesa de
quem o escreveu, passava. Num servidor de build passa ou falha conforme o Chromium que a
configuração cita, e trocar o shell pelo novo headless, que parece uma mudança de nada, o deixa
vermelho.

## A correção é escolher o tamanho

Apague a linha do `test.use`, e o teste roda nos 1280 por 720 do Playwright em todos os modos.
Fixar o tamanho é uma decisão sobre o que *a primeira tela* quer dizer, e o teste pode dizê-la em
voz alta: o segundo teste abaixo confere o tamanho em que rodou, então uma mudança no padrão
aparece como uma falha com um número, e não como uma surpresa de layout. O terceiro lê a página de
ofertas da aula 7 com um user agent headless. Salve o arquivo de novo como `tests/headless.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('every product is fully on the first screen', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
  await expect(page.getByTestId('product-pineapple')).toBeInViewport({ ratio: 1 });
});

test('the page is the size the test asked for', async ({ page }) => {
  await page.goto('/');
  expect(page.viewportSize()).toEqual({ width: 1280, height: 720 });
  expect(await page.evaluate(() => innerWidth)).toBe(1280);
});

test('a headless desktop browser gets the desktop deals page', async ({ page }) => {
  await page.goto('/deals');
  await expect(page.getByText('Weekly deals, in a table.')).toBeVisible();
});
```

```
ana@laptop:~/quitanda$ npx playwright test --config headless.config.js tests/headless.spec.js

Running 6 tests using 2 workers

  ✓  2 [shell] › tests/headless.spec.js:3:1 › every product is fully on the first screen (282ms)
  ✓  3 [shell] › tests/headless.spec.js:9:1 › the page is the size the test asked for (177ms)
  ✓  1 [new-headless] › tests/headless.spec.js:3:1 › every product is fully on the first screen (384ms)
  ✓  4 [shell] › tests/headless.spec.js:15:1 › a headless desktop browser gets the desktop deals page (138ms)
  ✓  5 [new-headless] › tests/headless.spec.js:9:1 › the page is the size the test asked for (269ms)
  ✓  6 [new-headless] › tests/headless.spec.js:15:1 › a headless desktop browser gets the desktop deals page (152ms)

  6 passed (2.7s)
```

```
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed tests/headless.spec.js

Running 3 tests using 1 worker

  ✓  1 tests/headless.spec.js:3:1 › every product is fully on the first screen (440ms)
  ✓  2 tests/headless.spec.js:9:1 › the page is the size the test asked for (194ms)
  ✓  3 tests/headless.spec.js:15:1 › a headless desktop browser gets the desktop deals page (241ms)

  3 passed (2.4s)
```

**Nove linhas verdes em três modos.** Celular é outra pergunta: a aula 7 testou a janela estreita
com um descritor de aparelho, que fixa o tamanho de propósito, e essa é a mesma correção vista do
outro lado.

## O nome que um site lê

A página de ofertas procura `Mobile` e mais nada, então para ela `HeadlessChrome` é só um navegador
de desktop, e o terceiro teste garante isso. **Outros sites leem a mesma string por outros
motivos.** Algumas ferramentas de análise descartam visitas cujo user agent diz headless; alguns
sites mandam uma página de desafio a qualquer coisa que pareça automatizada, e o
`navigator.webdriver` é um dos sinais que conferem. Um teste do seu site contra essas regras está
testando uma página diferente da que as pessoas veem.

A saída de quem testa é tornar isso explícito, nunca escondê-lo. No ambiente de testes, peça aos
desenvolvedores uma configuração que deixe passar o tráfego da suíte, e mantenha um teste que prove
que ela está desligada em produção. Um `userAgent` no `use` de um projeto, do jeito que os
descritores de aparelho definem um, muda o que o servidor lê; não muda o `navigator.webdriver`, e
um teste que precisa fingir ser uma pessoa é sinal de que o ambiente está errado.

## As fontes

A última diferença não tem teste falhando aqui, porque a máquina é a mesma em todos os modos. Uma
execução headless num servidor de build e uma com janela num notebook são duas máquinas, e
`system-ui` nomeia uma fonte diferente em cada uma. O título de um cartão que cabe numa linha numa
quebra na outra, e toda comparação de screenshots entre elas falha em pixels em que ninguém vê
problema. A aula 16 compara screenshots, e a regra dela vem desta: **tire a imagem de referência no
mesmo tipo de máquina, no mesmo modo, em que a comparação vai rodar.**
