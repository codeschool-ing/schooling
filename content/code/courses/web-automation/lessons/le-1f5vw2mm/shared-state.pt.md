---
title: Uma cesta para todo mundo
version: 1
---

**Um reinício põe a loja num estado conhecido num instante, e numa execução paralela esse instante
é de outra pessoa.** O arquivo da cesta passou porque os dois testes rodaram um depois do outro,
cada reinício seguido dos próprios cliques. Rode os dois ao mesmo tempo e cada reinício cai no meio
do outro teste. É a falha não marcada da loja, da aula 1, que a aula 10 mostrou com dois contextos
de navegador: a cesta vive no servidor, como uma lista só, e nada dentro de um teste consegue dar a
um teste uma cesta própria.

## Dois testes ao mesmo tempo

O Playwright roda os arquivos em paralelo e os testes dentro de um arquivo um depois do outro, a
menos que se diga o contrário; a aula 19 trata dessas regras. O `--fully-parallel` diz o contrário
para uma execução, e os dois testes do mesmo arquivo vão para dois workers no mesmo instante:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js --fully-parallel --workers 2

Running 2 tests using 2 workers

  ✓  1 tests/basket-data.spec.js:11:1 › a banana costs R$ 5,90 (276ms)
  ✘  2 tests/basket-data.spec.js:18:1 › two mangoes cost R$ 9,00 (5.4s)


  1) tests/basket-data.spec.js:18:1 › two mangoes cost R$ 9,00 ─────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  locator('.basket-total')
    Expected: "R$ 9,00"
    Received: "R$ 14,90"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for locator('.basket-total')
        9 × locator resolved to <span class="basket-total">R$ 14,90</span>
          - unexpected value "R$ 14,90"


      21 |   await add(page, 'mango');
      22 |   await expect(page.getByTestId('basket-count')).toHaveText('2');
    > 23 |   await expect(page.locator('.basket-total')).toHaveText('R$ 9,00');
         |                                               ^
      24 | });
      25 |
        at /home/ana/quitanda/tests/basket-data.spec.js:23:47

    Error Context: test-results/basket-data-two-mangoes-cost-R-9-00/error-context.md

  1 failed
    tests/basket-data.spec.js:18:1 › two mangoes cost R$ 9,00 ──────────────────────────────────────
  1 passed (6.7s)
```

O teste da banana passou e o das mangas achou R$ 14,90: uma banana e duas mangas, numa cesta que os dois testes tinham acabado de reiniciar. O da banana passou porque a página dele mostra a resposta ao próprio clique e nunca é redesenhada; a verificação da contagem já tinha lido o seu `1`. A verificação da contagem do teste das mangas chegou a passar, lendo o `2` desenhado pela resposta do primeiro clique antes de chegar a segunda resposta, o que é assunto da aula 13. O reinício do `beforeEach` rodou nos dois workers, e **os dois reinícios fizeram o
seu trabalho**: cada um esvaziou a cesta no instante em que rodou. Depois os cliques do outro
worker chegaram na mesma cesta. Um reinício no começo só é seguro quando nada mais escreve entre o
reinício e a última verificação, e numa execução paralela sempre pode haver algo escrevendo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Dois workers dividem a única cesta da loja. O worker 1, o teste da banana, reinicia a cesta e põe uma banana. O worker 2, o teste das mangas, também reinicia e põe duas mangas. A cesta no servidor vai de 0, 0, 1, 2 a 3. O teste da banana lê 1 na própria resposta e passa; o das mangas espera R$ 9,00 e lê R$ 14,90.\"><text x=\"20\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">worker 1</text><text x=\"20\" y=\"68\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o teste da banana</text><text x=\"20\" y=\"212\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">worker 2</text><text x=\"20\" y=\"228\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o teste das mangas</text><text x=\"20\" y=\"132\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a cesta</text><text x=\"20\" y=\"148\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no servidor</text><rect x=\"162\" y=\"38\" width=\"76\" height=\"26\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"200\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reinício</text><rect x=\"342\" y=\"38\" width=\"76\" height=\"26\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"380\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+ banana</text><rect x=\"595\" y=\"38\" width=\"90\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"640\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">vê 1: passa</text><rect x=\"252\" y=\"198\" width=\"76\" height=\"26\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"290\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reinício</text><rect x=\"432\" y=\"198\" width=\"76\" height=\"26\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"470\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+ mango</text><rect x=\"522\" y=\"198\" width=\"76\" height=\"26\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"560\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+ mango</text><rect x=\"595\" y=\"198\" width=\"90\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"640\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 14,90</text><path d=\"M200 64 L200 116\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"200\" cy=\"131\" r=\"14\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></circle><text x=\"200\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M290 198 L290 146\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"290\" cy=\"131\" r=\"14\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></circle><text x=\"290\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M380 64 L380 116\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"380\" cy=\"131\" r=\"14\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></circle><text x=\"380\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><path d=\"M470 198 L470 146\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"470\" cy=\"131\" r=\"14\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></circle><text x=\"470\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><path d=\"M560 198 L560 146\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"560\" cy=\"131\" r=\"14\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"560\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">3</text><path d=\"M214 131 L276 131 M304 131 L366 131 M394 131 L456 131 M484 131 L546 131\" stroke=\"var(--wire)\"></path><text x=\"380\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada reinício esvazia a cesta dos dois testes; todo clique depois dele cai na mesma lista</text></svg>", "caption": "Uma ordem de eventos que se encaixa na execução acima. Os dois reinícios acontecem antes de qualquer clique, e mesmo assim nenhum teste tem a cesta só para si.", "same": ["worker 1", "worker 2"]}
```

A reação de costume é reiniciar mais vezes: antes de cada clique, ou logo antes da verificação.
Isso estreita a janela e nunca a fecha, porque um clique do outro worker pode cair entre quaisquer
duas linhas. E cada reinício a mais é outra chance de apagar a cesta do outro teste no meio do
caminho, então as falhas mudam de lugar em vez de sumir. Em execuções paralelas, **um recurso
compartilhado com reinício é uma corrida, onde quer que os reinícios fiquem.**

## A correção de verdade é na loja

Os dados únicos resolveram os clientes porque cada teste podia criar o seu. A cesta não pode ser
tornada única por fora: existe uma, e a API não tem como pedir outra. **A correção é uma mudança na
aplicação**: uma cesta por visitante, guardada por um cookie ou uma sessão, de modo que um teste
num contexto de navegador novo, que a aula 10 mostrou não ter cookie nenhum, receba uma cesta vazia
só dele sem reiniciar nada.

Essa mudança é de quem desenvolve, e a parte de quem testa é pedi-la com as evidências: a execução
acima, a linha de `app/routes/shop.js` que guarda um único `store.basket`, e o que ela custa, que é
uma suíte que não consegue rodar os testes da cesta em paralelo. A mesma falha é um defeito para os
clientes também: duas pessoas comprando ao mesmo tempo dividem uma cesta, e a captura da aula 10 é
a prova. Testabilidade é uma funcionalidade, e pedi-la faz parte do trabalho; a aula 15 de
`manual-testing` cobre o relato.

## Enquanto isso: os testes revezam

Até a loja mudar, os testes que dividem a cesta não podem rodar ao mesmo tempo. O Playwright tem
uma configuração para um arquivo: `test.describe.configure({ mode: 'serial' })` roda os testes do
arquivo em ordem, num worker, mesmo quando a execução pede paralelismo total, e se um falha pula os
demais, já que eles podem depender do que ele deixou. Salve como `tests/basket-data.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The shop keeps one basket for everybody: these tests take turns.
test.describe.configure({ mode: 'serial' });

const add = (page, id) =>
  page.getByTestId(`product-${id}`).getByRole('button', { name: 'Add to basket' }).click();

// Every test starts from an empty basket.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a banana costs R$ 5,90', async ({ page }) => {
  await page.goto('/');
  await add(page, 'banana');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
});

test('two mangoes cost R$ 9,00', async ({ page }) => {
  await page.goto('/');
  await add(page, 'mango');
  await add(page, 'mango');
  await expect(page.getByTestId('basket-count')).toHaveText('2');
  await expect(page.locator('.basket-total')).toHaveText('R$ 9,00');
});
```

O mesmo comando de antes:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js --fully-parallel --workers 2

Running 2 tests using 1 worker

  ✓  1 tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 (236ms)
  ✓  2 tests/basket-data.spec.js:21:1 › two mangoes cost R$ 9,00 (345ms)

  2 passed (2.1s)
```

*Running 2 tests using 1 worker*: o arquivo manteve os testes juntos. **O que o modo serial não faz
é proteger o arquivo dos outros arquivos.** O `tests/banana.spec.js`, da aula 11, também reinicia a
cesta e põe coisas nela. Rode os dois arquivos com dois workers, do jeito comum que uma suíte roda:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js tests/banana.spec.js --workers 2

Running 3 tests using 2 workers

  ✓  1 tests/banana.spec.js:3:1 › a banana goes into the basket (274ms)
  ✘  2 tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 (5.3s)
  -  3 tests/basket-data.spec.js:21:1 › two mangoes cost R$ 9,00


  1) tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ───────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  getByTestId('basket-count')
    Expected: "1"
    Received: "2"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for getByTestId('basket-count')
        9 × locator resolved to <span data-testid="basket-count">2</span>
          - unexpected value "2"


      15 |   await page.goto('/');
      16 |   await add(page, 'banana');
    > 17 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
         |                                                  ^
      18 |   await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
      19 | });
      20 |
        at /home/ana/quitanda/tests/basket-data.spec.js:17:50

    Error Context: test-results/basket-data-a-banana-costs-R-5-90/error-context.md

  1 failed
    tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ────────────────────────────────────────
  1 did not run
  1 passed (6.7s)
```

O teste da banana do arquivo da cesta contou 2, contando a banana do outro arquivo, e o modo serial então pulou o teste das mangas, *1 did not run*, porque um arquivo serial para na primeira falha. O modo serial é uma afirmação sobre os testes de um arquivo, e a cesta é um fato do
servidor. O único arranjo que mantém cada teste da cesta longe de todos os outros é **um worker
para os testes que usam a cesta**:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js tests/banana.spec.js --workers 1

Running 3 tests using 1 worker

  ✓  1 tests/banana.spec.js:3:1 › a banana goes into the basket (218ms)
  ✓  2 tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 (284ms)
  ✓  3 tests/basket-data.spec.js:21:1 › two mangoes cost R$ 9,00 (331ms)

  3 passed (2.2s)
```

O `--workers 1` na linha de comando é a forma mais bruta, e deixa a execução inteira em série. A
aula 19 mostra como dar um único worker só aos testes da cesta enquanto o resto da suíte roda em
paralelo. Os dois são um custo pago a cada execução, e o comentário no topo do arquivo diz por que
está sendo pago. Quando a loja ganhar uma cesta por visitante, esse comentário é a linha a apagar.

| | resolve os dados? | mantém a execução paralela? | trabalho de quem |
|---|---|---|---|
| reiniciar no começo | só quando um teste roda por vez | não | de quem testa |
| modo serial no arquivo | dentro daquele arquivo | outros arquivos ainda colidem | de quem testa |
| um worker para os testes da cesta | sim | para todo o resto | de quem testa |
| uma cesta por visitante | sim | sim | de quem desenvolve, a pedido |
