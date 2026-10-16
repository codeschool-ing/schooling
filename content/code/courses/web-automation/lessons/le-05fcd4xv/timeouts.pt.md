---
title: Tempos limite, camada por camada
version: 1
---

**Toda espera num teste do Playwright roda dentro de mais de um relógio, e o primeiro que acabar
decide o que a falha diz.** Uma asserção tem o seu; uma ação e uma navegação podem ter o delas; o
teste tem um em volta de todos; e a execução pode ter um em volta de todos os testes. A aula 10 leu
dois deles em falhas. Esta seção lê todos no código instalado, dá a cada um uma falha própria, e
termina com o motivo para não aumentar nenhum deles só para um teste passar.

## Os padrões, no código-fonte

Documentação e memória mudam entre versões; o código instalado, não. Estas linhas vêm do
`@playwright/test` 1.56.0 do projeto. `3e4` é como o JavaScript escreve 30000, e `5e3`, 5000:

```
ana@laptop:~/quitanda$ grep -n -e 'defaultTimeout = ' -e 'defaultExpectTimeout = ' -e 'actionTimeout: \[' -e 'navigationTimeout: \[' -e 'launchTimeout = ' node_modules/playwright/lib/common/config.js node_modules/playwright/lib/matchers/expect.js node_modules/playwright/lib/index.js node_modules/playwright/lib/plugins/webServerPlugin.js
node_modules/playwright/lib/common/config.js:46:const defaultTimeout = 3e4;
node_modules/playwright/lib/matchers/expect.js:129:const defaultExpectTimeout = 5e3;
node_modules/playwright/lib/index.js:133:  actionTimeout: [0, { option: true, box: true }],
node_modules/playwright/lib/index.js:135:  navigationTimeout: [0, { option: true, box: true }],
node_modules/playwright/lib/plugins/webServerPlugin.js:134:    const launchTimeout = this._options.timeout || 60 * 1e3;
ana@laptop:~/quitanda$ grep -n -o -e 'globalTimeout, 0)' -e 'toPass?.timeout, 0)' node_modules/playwright/lib/common/config.js node_modules/playwright/lib/matchers/matchers.js
node_modules/playwright/lib/common/config.js:79:globalTimeout, 0)
node_modules/playwright/lib/matchers/matchers.js:311:toPass?.timeout, 0)
```

| camada | padrão | onde se define |
|---|---|---|
| o teste, seus hooks e fixtures | 30 s | `timeout` na configuração, `test.setTimeout()` |
| uma asserção | 5 s | `expect.timeout` na configuração, `{ timeout }` na chamada |
| uma ação: `click`, `fill`… | nenhum próprio | `actionTimeout` em `use`, `{ timeout }` na chamada |
| uma navegação: `goto`, `reload`… | nenhum próprio | `navigationTimeout` em `use`, `{ timeout }` na chamada |
| `toPass` | nenhum próprio | `{ timeout }` na chamada |
| a execução inteira | nenhum | `globalTimeout` na configuração |
| subir o `webServer` | 60 s | `webServer.timeout` |

O relógio do teste cobre mais que a função de teste: a documentação diz que os hooks `beforeEach` e
as fixtures que o teste usa também contam nele. **`0` quer dizer *sem limite próprio*, não *sem
espera*.** Uma ação sem tempo limite ainda para quando os 30 segundos do teste acabam, que foi
exatamente o que o clique em *Buy now* fez na aula 10. O tempo do teste é o relógio mais de fora que
vem ligado por padrão, e tudo dentro dele pega emprestado dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Caixas aninhadas. A de fora é a execução, sem limite por padrão. Dentro dela, um teste, com 30 segundos por padrão, contando os hooks. Dentro do teste, três passos: page.goto e locator.click sem limite próprio, e expect com 5 segundos próprios. Uma nota diz que um relógio de dentro mais longo que o de fora nunca é alcançado.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"34\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">a execução</text><text x=\"26\" y=\"52\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">globalTimeout: sem limite por padrão</text><rect x=\"30\" y=\"66\" width=\"660\" height=\"176\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"46\" y=\"90\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\" text-anchor=\"start\">um teste</text><text x=\"46\" y=\"108\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">30 s por padrão, com os hooks</text><rect x=\"50\" y=\"124\" width=\"190\" height=\"66\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\"></rect><text x=\"64\" y=\"150\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"start\">page.goto</text><text x=\"64\" y=\"172\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">sem limite próprio</text><rect x=\"260\" y=\"124\" width=\"190\" height=\"66\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\"></rect><text x=\"274\" y=\"150\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"start\">locator.click</text><text x=\"274\" y=\"172\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">sem limite próprio</text><rect x=\"470\" y=\"124\" width=\"190\" height=\"66\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\"></rect><text x=\"484\" y=\"150\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"start\">expect</text><text x=\"484\" y=\"172\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">5 s próprios</text><text x=\"46\" y=\"220\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">um relógio de dentro mais longo que o de fora nunca é alcançado</text></svg>", "caption": "Relógios dentro de relógios. Um passo sem limite próprio para quando o teste para."}
```

## Uma falha por camada

Este arquivo espera quatro coisas que não podem acontecer a tempo, cada uma com um relógio diferente
encurtado. Ele não faz parte do projeto: ponha em `tests/scratch.spec.js`, rode, e depois apague o
arquivo.

```javascript
import { test, expect } from '@playwright/test';

test('an action with a timeout of its own', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Buy now' }).click({ timeout: 2000 });
});

test('a navigation slower than its timeout', async ({ page }) => {
  await page.goto('/slow/ssr.js', { timeout: 1000 });
});

test('an assertion shorter than the page needs', async ({ page }) => {
  await page.goto('/ssr');
  await expect(page.locator('body')).toHaveAttribute('data-ready', 'true', { timeout: 1000 });
});

test('a test shorter than its steps', async ({ page }) => {
  test.setTimeout(1000);
  await page.goto('/ssr');
  await expect(page.locator('body')).toHaveAttribute('data-ready', 'true');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/scratch.spec.js --workers 1

Running 4 tests using 1 worker

  ✘  1 tests/scratch.spec.js:3:1 › an action with a timeout of its own (2.2s)
  ✘  2 tests/scratch.spec.js:8:1 › a navigation slower than its timeout (2.6s)
  ✘  3 tests/scratch.spec.js:12:1 › an assertion shorter than the page needs (1.2s)
  ✘  4 tests/scratch.spec.js:17:1 › a test shorter than its steps (1.0s)


  1) tests/scratch.spec.js:3:1 › an action with a timeout of its own ───────────────────────────────

    TimeoutError: locator.click: Timeout 2000ms exceeded.
    Call log:
      - waiting for getByRole('button', { name: 'Buy now' })


      3 | test('an action with a timeout of its own', async ({ page }) => {
      4 |   await page.goto('/');
    > 5 |   await page.getByRole('button', { name: 'Buy now' }).click({ timeout: 2000 });
        |                                                       ^
      6 | });
      7 |
      8 | test('a navigation slower than its timeout', async ({ page }) => {
        at /home/ana/quitanda/tests/scratch.spec.js:5:55

    Error Context: test-results/scratch-an-action-with-a-timeout-of-its-own/error-context.md

  2) tests/scratch.spec.js:8:1 › a navigation slower than its timeout ──────────────────────────────

    TimeoutError: page.goto: Timeout 1000ms exceeded.
    Call log:
      - navigating to "http://localhost:3000/slow/ssr.js", waiting until "load"


       7 |
       8 | test('a navigation slower than its timeout', async ({ page }) => {
    >  9 |   await page.goto('/slow/ssr.js', { timeout: 1000 });
         |              ^
      10 | });
      11 |
      12 | test('an assertion shorter than the page needs', async ({ page }) => {
        at /home/ana/quitanda/tests/scratch.spec.js:9:14

    Error Context: test-results/scratch-a-navigation-slower-than-its-timeout/error-context.md

  3) tests/scratch.spec.js:12:1 › an assertion shorter than the page needs ─────────────────────────

    Error: expect(locator).toHaveAttribute(expected) failed

    Locator:  locator('body')
    Expected: "true"
    Received: ""
    Timeout:  1000ms

    Call log:
      - Expect "toHaveAttribute" with timeout 1000ms
      - waiting for locator('body')
        5 × locator resolved to <body>…</body>
          - unexpected value "null"


      12 | test('an assertion shorter than the page needs', async ({ page }) => {
      13 |   await page.goto('/ssr');
    > 14 |   await expect(page.locator('body')).toHaveAttribute('data-ready', 'true', { timeout: 1000 });
         |                                      ^
      15 | });
      16 |
      17 | test('a test shorter than its steps', async ({ page }) => {
        at /home/ana/quitanda/tests/scratch.spec.js:14:38

    Error Context: test-results/scratch-an-assertion-shorter-than-the-page-needs/error-context.md

  4) tests/scratch.spec.js:17:1 › a test shorter than its steps ────────────────────────────────────

    Test timeout of 1000ms exceeded.

    Error: expect(locator).toHaveAttribute(expected) failed

    Locator:  locator('body')
    Expected: "true"
    Received: ""

    Call log:
      - Expect "toHaveAttribute" with timeout 5000ms
      - waiting for locator('body')
        5 × locator resolved to <body>…</body>
          - unexpected value "null"


      18 |   test.setTimeout(1000);
      19 |   await page.goto('/ssr');
    > 20 |   await expect(page.locator('body')).toHaveAttribute('data-ready', 'true');
         |                                      ^
      21 | });
      22 |
        at /home/ana/quitanda/tests/scratch.spec.js:20:38

    Error Context: test-results/scratch-a-test-shorter-than-its-steps/error-context.md

  4 failed
    tests/scratch.spec.js:3:1 › an action with a timeout of its own ────────────────────────────────
    tests/scratch.spec.js:8:1 › a navigation slower than its timeout ───────────────────────────────
    tests/scratch.spec.js:12:1 › an assertion shorter than the page needs ──────────────────────────
    tests/scratch.spec.js:17:1 › a test shorter than its steps ─────────────────────────────────────
```

**Cada mensagem dá nome ao relógio que acabou**, e essa é a primeira coisa a ler em qualquer estouro
de tempo. `locator.click: Timeout 2000ms exceeded` e `page.goto: Timeout 1000ms exceeded` são o da
ação e o da navegação. A asserção informa `Timeout: 1000ms`. A última é a que ensina: o registro de
chamadas ainda diz `with timeout 5000ms`, o relógio da própria asserção, mas o relógio de um segundo
do teste acabou antes, e a falha abre com `Test timeout of 1000ms exceeded`. Um tempo de dentro mais
longo que o de fora nunca é alcançado.

## Escolhendo os números

Duas regras resolvem a maioria das suítes. **Deixe os cinco segundos da asserção em paz, e dê às
ações e às navegações um limite próprio**, como dez ou quinze segundos por `actionTimeout` e
`navigationTimeout`, para que um clique que nunca pode acontecer falhe com o próprio nome depois de
alguns segundos, em vez de gastar o teste inteiro. E quando um passo é lento de verdade, um upload ou
um relatório que o servidor monta, dê **àquela chamada** um `{ timeout }`, com um comentário dizendo
por quê. Um número aumentado para a suíte toda é pago por todo teste que falha.

## Por que aumentar o tempo limite esconde um defeito

O conserto tentador para um estouro de tempo é um tempo maior, e às vezes ele é errado de um jeito
que nenhum teste vai acusar. Este arquivo faz as vezes de uma versão que deixou a lista de produtos
da loja seis segundos mais lenta, segurando a resposta com `page.route`, como o `at-load.mjs` da
aula 3 fez. Ponha em `tests/scratch.spec.js` no lugar do anterior, rode, e apague o arquivo depois:

```javascript
import { test, expect } from '@playwright/test';

// Stands in for a release that made the products six seconds slower.
test.beforeEach(async ({ page }) => {
  await page.route('**/api/products', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 6000));
    await route.continue();
  });
});

test('the default timeout notices', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
});

test('a raised timeout does not', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8, { timeout: 10000 });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/scratch.spec.js --workers 1

Running 2 tests using 1 worker

  ✘  1 tests/scratch.spec.js:11:1 › the default timeout notices (5.2s)
  ✓  2 tests/scratch.spec.js:16:1 › a raised timeout does not (7.2s)


  1) tests/scratch.spec.js:11:1 › the default timeout notices ──────────────────────────────────────

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


      11 | test('the default timeout notices', async ({ page }) => {
      12 |   await page.goto('/');
    > 13 |   await expect(page.locator('#products li')).toHaveCount(8);
         |                                              ^
      14 | });
      15 |
      16 | test('a raised timeout does not', async ({ page }) => {
        at /home/ana/quitanda/tests/scratch.spec.js:13:46

    Error Context: test-results/scratch-the-default-timeout-notices/error-context.md

  1 failed
    tests/scratch.spec.js:11:1 › the default timeout notices ───────────────────────────────────────
  1 passed (15.0s)
```

**O tempo aumentado aprovou uma loja onde o cliente fica seis segundos olhando uma página vazia.** O
padrão falhou, e essa falha era o único aviso que alguém receberia de que a versão deixou a página
mais lenta; o teste que passa está verde, quieto, e errado sobre a primeira coisa que um cliente
notaria. Um tempo limite não é só quanto o teste aceita esperar. É também a resposta mais lenta que
o teste aceita chamar de correta, e aumentá-lo muda o que a suíte aceita. Se seis segundos são
aceitáveis é pergunta para a aula 10 de `non-functional-testing`, sobre desempenho no front-end, e
não algo para resolver editando um número até a execução ficar verde.
