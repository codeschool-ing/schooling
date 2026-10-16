---
title: Uma configuração que guarda as evidências
version: 1
---

Um teste que falha no terminal diz **o que** deu errado e raramente **por quê**. O primeiro teste
da aula 6 para a página renderizada no servidor clicava num botão assim que ele aparecia, e falhava
com *expected "1", received "0"*: o contador da cesta nunca mudou. O registro de chamadas abaixo
dessa linha não diz qual de quatro histórias é a verdadeira. O clique errou o botão, ou o clique
acertou e ninguém estava ouvindo, ou a requisição saiu e falhou, ou o servidor contou errado. A aula
6 sabia a resposta porque tinha lido a página antes. Um teste que falha numa suíte de duzentos não
traz esse conhecimento junto.

No seu computador, você rodaria de novo com a janela aberta e ficaria olhando. **Num servidor de
build ninguém olha**, a execução que falhou já foi embora, e a próxima pode passar. As evidências
precisam ser coletadas durante a execução que falhou, pela própria execução.

## Três opções e um reporter

O Playwright coleta três tipos de evidência, cada um ligado por uma chave dentro de `use`. Este
curso mantém o `playwright.config.js` como a aula 1 o escreveu, então as opções ficam num segundo
arquivo, que importa o primeiro e muda só o que esta aula precisa. Salve como `evidence.config.js`:

```javascript
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

// The base configuration, plus the evidence a failing test leaves behind.
// It reads its tests from evidence/, where every test fails on purpose.
export default defineConfig({
  ...base,
  testDir: 'evidence',
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    ...base.use,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',
  },
});
```

`...base` copia tudo o que a aula 1 definiu, inclusive a loja iniciada pelo `webServer`, e as
chaves depois dele substituem as que nomeiam. `...base.use` preserva o `baseURL` dentro de `use`,
que um `use: {…}` sozinho teria jogado fora. As três opções:

- **`screenshot: 'only-on-failure'`** tira uma foto da página quando um teste falha, no fim;
- **`video: 'retain-on-failure'`** filma todo teste e apaga o filme de cada um que passa;
- **`trace: 'retain-on-failure'`** grava um rastro, o arquivo de ações, snapshots, rede e console
  da aula 10, para todo teste, e o apaga quando o teste passa.

A lista de reporters mantém as linhas do `list` no terminal e também escreve o relatório HTML da
aula 10, com `open: 'never'` para que uma execução com falhas não tente abrir uma janela de
navegador. O arquivo é escolhido com `--config`.

## Onde moram os testes que falham de propósito

Esta aula precisa de testes que falham, porque uma falha é o que ela diagnostica, e não pode deixar
a suíte do projeto vermelha. A aula 3 enfrentou o mesmo problema e escolheu `test.fail()`. **Aqui,
`test.fail()` destruiria justamente aquilo de que a aula trata.** *Retain on failure* quer dizer:
guardar as evidências quando um teste não fez o que foi declarado que faria. Um teste declarado
para falhar que falha fez exatamente isso, então o Playwright o conta como aprovado e joga o rastro
fora. O próprio arquivo da aula 3 mostra isso, rodado com a opção de rastro na linha de comando:

```
ana@laptop:~/quitanda$ npx playwright test tests/search.spec.js --trace retain-on-failure

Running 2 tests using 1 worker

  ✓  1 tests/search.spec.js:7:1 › one request: filling the box finds papaya (205ms)
  ✘  2 tests/search.spec.js:13:1 › typed key by key, the list settles on papaya (6.1s)

  2 passed (7.6s)
ana@laptop:~/quitanda$ find test-results
test-results
test-results/.last-run.json
test-results/search-typed-key-by-key-the-list-settles-on-papaya
test-results/search-typed-key-by-key-the-list-settles-on-papaya/error-context.md
```

O segundo teste falhou, como diz o `✘`, e o resumo o conta entre os aprovados. A pasta dele em
`test-results/` guarda só o `error-context.md`, um arquivo que a próxima seção lê; **o rastro
sumiu**, apagado junto com os testes que passaram. Um teste em quarentena deixa quase nenhuma
evidência para trás, e a aula 14, que trata de quarentena, tem de conviver com isso.

Por isso os testes desta aula ficam numa pasta própria, `evidence/`, que a configuração base nunca
lê, já que o `testDir` dela é `tests`. Um `npx playwright test` simples continua verde; as falhas só
rodam quando você pede, com `--config evidence.config.js`. Cada arquivo começa com um comentário
dizendo que falha de propósito, para ninguém consertá-lo por engano. O primeiro é o teste da aula
6, igual a não ser pelo título. Salve como `evidence/ssr.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The basket is shared, so the test starts by emptying it.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

// Fails on purpose: it clicks as soon as the button is drawn, before the
// script that makes the buttons work has arrived (lesson 6).
test('a click on /ssr, at once', async ({ page }) => {
  await page.goto('/ssr');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});
```

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/ssr.spec.js

Running 1 test using 1 worker

  ✘  1 evidence/ssr.spec.js:10:1 › a click on /ssr, at once (5.7s)


  1) evidence/ssr.spec.js:10:1 › a click on /ssr, at once ──────────────────────────────────────────

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


      11 |   await page.goto('/ssr');
      12 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
    > 13 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
         |                                                  ^
      14 | });
      15 |
        at /home/ana/quitanda/evidence/ssr.spec.js:13:50

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    test-results/ssr-a-click-on-ssr-at-once/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    attachment #2: video (video/webm) ──────────────────────────────────────────────────────────────
    test-results/ssr-a-click-on-ssr-at-once/video.webm
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: test-results/ssr-a-click-on-ssr-at-once/error-context.md

    attachment #4: trace (application/zip) ─────────────────────────────────────────────────────────
    test-results/ssr-a-click-on-ssr-at-once/trace.zip
    Usage:

        npx playwright show-trace test-results/ssr-a-click-on-ssr-at-once/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────

  1 failed
    evidence/ssr.spec.js:10:1 › a click on /ssr, at once ───────────────────────────────────────────

To open last HTML report run:

  npx playwright show-report
```

**A metade de cima é a falha da aula 6, e a de baixo é nova.** Quatro coisas foram anexadas: uma
captura de tela, um vídeo, um contexto de erro e um rastro, cada um com seu caminho em
`test-results/`. Os anexos são numerados na ordem em que o Playwright os coletou; o contexto de
erro sai com um rótulo próprio, e é por isso que a numeração pula o 3. A próxima seção abre cada um.
