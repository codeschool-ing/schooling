---
title: Desenhado não é o mesmo que funcionando
version: 1
---

O HTML de `/ssr` desenha oito cartões, cada um com um botão **Add to basket**. São elementos
`<button>` de verdade, visíveis e habilitados, e **não fazem nada** até que um script dê a cada um
uma função para o clique. Os frameworks que renderizam no servidor chamam esse passo de
**hidratação**: o HTML chega seco, e um script que vem depois dele o faz responder. A loja faz isso à
mão, no arquivo que o servidor envia em `/slow/ssr.js`. Salve-o como `app/public/ssr.js`:

```javascript
// Until this file has run, the buttons on /ssr are drawn and do nothing.
for (const button of document.querySelectorAll('button[data-id]')) {
  button.addEventListener('click', async () => {
    const response = await fetch('/api/basket', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: button.dataset.id }),
    });
    const basket = await response.json();
    const count = basket.lines.reduce((n, line) => n + line.qty, 0);
    document.querySelector('[data-testid=basket-count]').textContent = count;
  });
}
document.body.dataset.ready = 'true';
```

A última linha dele põe `data-ready="true"` no `<body>`, depois que todo botão tem sua função. A
próxima seção tem um uso para isso.

## A lacuna, medida

O `look.mjs` da aula 1 imprime cada resposta que uma página recebe, com os milissegundos desde que
ele pediu a página. Primeiro a página inicial:

```
ana@laptop:~/quitanda$ node look.mjs
   17 ms  200 GET /  (document)
   49 ms  200 GET /style.css  (stylesheet)
   50 ms  200 GET /app.js  (script)
   81 ms  200 GET /api/products  (fetch)
   85 ms  200 GET /api/basket  (fetch)
```

Depois `/ssr`, com o endereço como argumento:

```
ana@laptop:~/quitanda$ node look.mjs http://localhost:3000/ssr
   13 ms  200 GET /ssr  (document)
   25 ms  200 GET /style.css  (stylesheet)
 1538 ms  200 GET /slow/ssr.js  (script)
```

Em `/`, os produtos chegam aos 81 ms numa requisição própria, e até lá a lista fica vazia.
Em `/ssr` eles vieram com o documento, aos 13 ms, e o script que faz os botões funcionarem chegou
aos 1538 ms. **Durante cerca de um segundo e meio a página mostra oito botões que ignoram
todo clique.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas linhas do tempo de 0 a 1700 milissegundos. A página inicial, renderizada no navegador, mostra uma lista vazia até os produtos chegarem aos 81 ms e então funciona. A página renderizada no servidor mostra os produtos desde os 13 ms, mas os botões não fazem nada até o ssr.js chegar aos 1538 ms. Um teste que clica assim que a página carregou clica dentro dessa lacuna.\"><path d=\"M170 250 L690 250\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M170.0 246 L170.0 254\" stroke=\"var(--wire)\"></path><text x=\"170.0\" y=\"272\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">0 ms</text><path d=\"M322.9 246 L322.9 254\" stroke=\"var(--wire)\"></path><text x=\"322.9\" y=\"272\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">500 ms</text><path d=\"M475.9 246 L475.9 254\" stroke=\"var(--wire)\"></path><text x=\"475.9\" y=\"272\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">1000 ms</text><path d=\"M628.8 246 L628.8 254\" stroke=\"var(--wire)\"></path><text x=\"628.8\" y=\"272\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">1500 ms</text><text x=\"690\" y=\"292\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">tempo desde o pedido da página</text><text x=\"20\" y=\"66\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">/</text><text x=\"20\" y=\"84\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">no cliente</text><rect x=\"170.0\" y=\"50\" width=\"24.8\" height=\"30\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><rect x=\"194.8\" y=\"50\" width=\"495.2\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"206.8\" y=\"70\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" text-anchor=\"start\">produtos desenhados, botões funcionam</text><text x=\"170.0\" y=\"40\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">lista vazia por 81 ms</text><text x=\"20\" y=\"146\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">/ssr</text><text x=\"20\" y=\"164\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">no servidor</text><rect x=\"174.0\" y=\"130\" width=\"466.4\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"186.0\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" text-anchor=\"start\">produtos à vista, botões não fazem nada</text><rect x=\"640.4\" y=\"130\" width=\"49.6\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"648.4\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" text-anchor=\"start\">funciona</text><path d=\"M174.0 186 L174.0 162\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><path d=\"M174.0 162 L169.0 172 L179.0 172 Z\" fill=\"var(--paper)\"></path><text x=\"174.0\" y=\"202\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\">load: o goto retorna,</text><text x=\"174.0\" y=\"218\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">e um teste clica aqui</text><path d=\"M640.4 120 L640.4 170\" stroke=\"var(--phosphor)\" stroke-dasharray=\"3 3\"></path><text x=\"632.4\" y=\"192\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"end\">ssr.js</text><text x=\"632.4\" y=\"208\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"end\">1538 ms</text></svg>", "caption": "As duas páginas ao longo do tempo, segundo as execuções do look.mjs acima. A página renderizada no servidor serve primeiro aos olhos e por último a um clique."}
```

## Um teste que clica na hora

O teste óbvio abre a página, clica no botão da banana e verifica que a cesta diz 1. O `beforeEach`
esvazia a cesta antes, pela reinicialização da loja, porque a cesta é uma lista só, compartilhada
por todo mundo, e um teste anterior pode tê-la enchido; a aula 15 trata disso. Salve-o como
`tests/ssr.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The basket is shared, so every test starts by emptying it.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a click on /ssr adds to the basket', async ({ page }) => {
  await page.goto('/ssr');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js

Running 1 test using 1 worker

  ✘  1 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket (5.4s)


  1) tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket ────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  getByTestId('basket-count')
    Expected: "1"
    Received: "0"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for getByTestId('basket-count')
        9 × locator resolved to <span data-testid="basket-count">0</span>
          - unexpected value "0"


       9 |   await page.goto('/ssr');
      10 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
    > 11 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
         |                                                  ^
      12 | });
      13 |
        at /home/ana/quitanda/tests/ssr.spec.js:11:50

    Error Context: test-results/ssr-a-click-on-ssr-adds-to-the-basket/error-context.md

  1 failed
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket ─────────────────────────────────────
```

**O clique deu certo e a cesta ficou em 0.** O Playwright não reclamou do clique em si. Antes de
clicar, ele verifica que o elemento está visível, parado, habilitado e não coberto por outra coisa,
o que a documentação dele chama de **verificações de acionabilidade**, e o botão passou em todas.
Depois ele esperou os cinco segundos que uma asserção espera por padrão para o texto virar `1`, e
desistiu. Nenhuma verificação no botão poderia ter pegado isso, porque um botão sem função e um
botão com função parecem idênticos vistos de fora.

## Várias execuções, caso varie

Um problema de tempo costuma passar de vez em quando, então, antes de decidir o que fazer, descubra
de que tipo é o seu. O `--repeat-each` roda o teste esse número de vezes, o `--workers 1` roda as
cópias uma depois da outra, e o `grep` guarda as linhas que dizem como cada execução terminou. Por
padrão as cópias rodam em paralelo, e em paralelo elas dividiriam a cesta única da loja, de modo que
o clique de uma cópia poderia aparecer na contagem de outra; esse é o assunto da aula 15, e aqui só
turvaria a resposta:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js --repeat-each 5 --workers 1 | grep -E 'passed|failed|✘|✓'
  ✘  1 tests/ssr.spec.js:9:1 › a click on /ssr adds to the basket (5.3s)
  ✘  2 tests/ssr.spec.js:9:1 › a click on /ssr adds to the basket (5.4s)
  ✘  3 tests/ssr.spec.js:9:1 › a click on /ssr adds to the basket (5.3s)
  ✘  4 tests/ssr.spec.js:9:1 › a click on /ssr adds to the basket (5.3s)
  ✘  5 tests/ssr.spec.js:9:1 › a click on /ssr adds to the basket (5.2s)
    Error: expect(locator).toHaveText(expected) failed
    Error: expect(locator).toHaveText(expected) failed
    Error: expect(locator).toHaveText(expected) failed
    Error: expect(locator).toHaveText(expected) failed
    Error: expect(locator).toHaveText(expected) failed
  5 failed
```

Cinco falhas em cinco. O `page.goto` retorna quando o evento `load` da página disparou, e só então o
script embutido pede `/slow/ssr.js`; o clique cai dentro do 1,5 s em que o servidor o segura, toda
vez. Encurte essa pausa para alguns milissegundos e o mesmo teste passaria numa máquina rápida e
falharia numa máquina carregada, que é a forma dos testes intermitentes da aula 14.
