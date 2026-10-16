---
title: Quando esperar demais faz falhar
version: 1
---

**Tudo até aqui foi sobre esperar o bastante. Um estado que não dura vira o problema do avesso: um
teste que chega depois de ele ir embora falha, e nenhum tempo limite o salva.** A crença de costume é
que um teste paciente é um teste seguro, que uma espera que só desiste depois de dez segundos só pode
ser mais confiável que uma que desiste depois de cinco. Isso vale para um estado que chega e fica. O
aviso da loja chega e vai embora.

## Uma mensagem que dura dois segundos

Quando você põe uma fruta na cesta, o `app.js` escreve *Added Banana* no parágrafo `.toast` e, com
um `setTimeout`, o esvazia de novo dois segundos depois. O parágrafo nunca some; só o texto dele. Uma
pessoa bate o olho e segue. Um teste tem de ler dentro desses dois segundos.

Este teste segue a ordem que a maioria escreveria primeiro: clicar, conferir a cesta, depois o aviso.
Entre os dois há um sleep, do tipo que fica numa suíte depois que alguém o pôs para sumir com outra
falha, e a asserção do aviso ganhou generosos dez segundos. Salve como `tests/toast.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('adding a banana says so', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button').click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await page.waitForTimeout(2000); // let the basket settle
  await expect(page.locator('.toast')).toHaveText('Added Banana', { timeout: 10000 });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/toast.spec.js

Running 1 test using 1 worker

  ✘  1 tests/toast.spec.js:7:1 › adding a banana says so (12.4s)


  1) tests/toast.spec.js:7:1 › adding a banana says so ─────────────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  locator('.toast')
    Expected: "Added Banana"
    Received: ""
    Timeout:  10000ms

    Call log:
      - Expect "toHaveText" with timeout 10000ms
      - waiting for locator('.toast')
        14 × locator resolved to <p role="status" class="toast"></p>
           - unexpected value ""


      10 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
      11 |   await page.waitForTimeout(2000); // let the basket settle
    > 12 |   await expect(page.locator('.toast')).toHaveText('Added Banana', { timeout: 10000 });
         |                                        ^
      13 | });
      14 |
        at /home/ana/quitanda/tests/toast.spec.js:12:40

    Error Context: test-results/toast-adding-a-banana-says-so/error-context.md

  1 failed
    tests/toast.spec.js:7:1 › adding a banana says so ──────────────────────────────────────────────
```

**A asserção olhou 14 vezes em dez segundos e achou um parágrafo vazio em todas.** O registro de
chamadas diz que o localizador *resolveu*, então o elemento estava lá; o que ele tinha era `""`.
Quando a asserção começou, a mensagem já tinha sido mostrada e retirada, e perguntar de novo por dez
segundos, ou cem, é perguntar a uma página que nunca mais vai dizer aquilo. O tempo de dez segundos
mudou uma coisa só: quanto o teste levou para falhar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma linha do tempo a partir do clique. O aviso diz Added Banana de 0 a 2000 ms e fica vazio depois. O teste que olha primeiro é satisfeito na hora. O teste que dorme 2000 ms começa a olhar logo depois que o texto sumiu e continua olhando por 10 segundos, achando um parágrafo vazio toda vez.\"><text x=\"20\" y=\"50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">o aviso</text><rect x=\"170.0\" y=\"34\" width=\"320.0\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"330.0\" y=\"50\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"middle\">Added Banana</text><rect x=\"490.0\" y=\"34\" width=\"192.0\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></rect><text x=\"586.0\" y=\"50\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">\"\"</text><text x=\"20\" y=\"104\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">olhar primeiro</text><circle cx=\"174.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"186.0\" y=\"104\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"start\">satisfeito na hora</text><text x=\"20\" y=\"154\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">dormir, depois olhar</text><path d=\"M170.0 150 L491.6 150\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" stroke-dasharray=\"2 4\"></path><text x=\"330.0\" y=\"142\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">sleep de 2000 ms</text><circle cx=\"491.6\" cy=\"150\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M491.6 150 L682.0 150\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M682.0 150 L674.0 145 L674.0 155 Z\" fill=\"var(--amber)\"></path><text x=\"690.0\" y=\"154\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" text-anchor=\"start\">10 s</text><text x=\"491.6\" y=\"176\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" text-anchor=\"start\">toda olhada acha \"\"</text><path d=\"M170 206 L682.0 206\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M170.0 202 L170.0 210\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"170.0\" y=\"226\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">0 ms</text><path d=\"M330.0 202 L330.0 210\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"330.0\" y=\"226\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">1000 ms</text><path d=\"M490.0 202 L490.0 210\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"490.0\" y=\"226\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">2000 ms</text><path d=\"M650.0 202 L650.0 210\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"650.0\" y=\"226\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">3000 ms</text><text x=\"682.0\" y=\"248\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">tempo desde o clique</text></svg>", "caption": "Um estado que vai embora. A asserção que começa depois dos 2000 ms só pode ver o parágrafo vazio, por mais que olhe.", "same": ["10 s"]}
```

## Olhe enquanto ele está lá

O conserto é a ordem, e ele leva o sleep junto. **Confira um estado passageiro primeiro, logo depois
da ação que o provoca, e deixe os estados que duram para depois.** A asserção do aviso então começa
milissegundos depois do clique e é satisfeita na primeira ou na segunda olhada. A contagem da cesta
dura, então pode esperar a vez dela. Uma última asserção confere que o aviso vai embora, que é a
outra metade do comportamento dele e a que uma pessoa notaria se quebrasse: uma mensagem que nunca
sai. O `toBeEmpty` passa quando o elemento não tem texto, e os três segundos de tempo limite dele
dizem de propósito que dois segundos é a promessa. Salve como `tests/toast.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('adding a banana says so, then stops saying it', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button').click();
  await expect(page.locator('.toast')).toHaveText('Added Banana');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.toast')).toBeEmpty({ timeout: 3000 });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/toast.spec.js

Running 1 test using 1 worker

  ✓  1 tests/toast.spec.js:7:1 › adding a banana says so, then stops saying it (3.3s)

  1 passed (5.0s)
```

**O teste levou 3,3 s, e a maior parte disso é a última asserção fazendo o que diz.** O aviso
esvaziou dois segundos depois do clique; a asserção, que a essa altura olhava uma vez por segundo,
como a seção 04 contou, viu o parágrafo vazio na olhada seguinte. Um teste que confere um
desaparecimento paga por ele em tempo, e isso é motivo para conferir um só onde importa.

## O que torna um estado passageiro

O aviso é o caso mais simples. O mesmo formato aparece sempre que uma página mostra algo a caminho
de outra coisa: um rótulo *Salvando…*, um spinner, o destaque numa linha que mudou, um banner que se
fecha sozinho, a lista de duas frutas que a página de busca mostrou por um instante na aula 3. Três
hábitos mantêm o teste do lado certo deles.

- **Afirme um estado passageiro logo depois da causa dele**, sem nada lento no meio, nem mesmo outra
  asserção sobre algo que dura.
- **Não aumente o tempo limite dele.** O tempo só precisa cobrir quanto o estado leva para aparecer;
  quanto ele fica é assunto da página, e uma espera mais longa não consegue esticá-lo.
- **Se o estado é curto demais para pegar com confiança, teste o que ele deixa para trás**, o
  registro salvo ou a contagem, ou peça aos desenvolvedores um sinal que dure. Uma mensagem que some
  antes de um teste conseguir lê-la também some antes de algumas pessoas conseguirem; quanto tempo
  uma mensagem deve ficar na tela é uma questão de acessibilidade, e as aulas 12 a 15 de
  `non-functional-testing` são onde ela é respondida.
