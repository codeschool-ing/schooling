---
title: Esperar sem que mandem
version: 1
---

Um teste escrito para uma página que muda debaixo dele pareceria precisar de uma pausa antes de cada
passo: esperar o botão, clicar, esperar o total, conferir. **Os testes de Playwright deste curso
não têm pausas nem sleeps**, e passam. Dois mecanismos fazem a espera, um antes de cada ação e
outro dentro de cada asserção, e os dois desistem depois de um tempo fixo. Esta seção dá nome a
eles e mede os tempos; a aula 13 trata de esperas a fundo, e a aula 3 do carregamento assíncrono
que as torna necessárias.

## Antes de uma ação: acionabilidade

Antes de o `click()` apertar qualquer coisa, o Playwright acha o elemento que o localizador
descreve e confere, nas palavras da documentação dele, que ele está **visível**, **estável** (não
se mexendo numa animação), **recebe eventos** (nenhum outro elemento o cobre) e está **habilitado**.
Um `fill()` também exige que ele seja **editável**. Se alguma conferência falha, ele olha de novo,
e de novo, até todas passarem ou o tempo acabar. Um botão que aparece meio segundo depois de a
página carregar é clicado meio segundo depois, e o teste não diz nada sobre isso.

É também por isso que um localizador é uma descrição, e não um elemento.
`page.getByRole('button')` não acha nada quando é escrito; ele é resolvido a cada uso, contra a
página como ela está naquele momento.

## Depois de uma ação: uma asserção que tenta de novo

O **Add to basket** da loja manda uma requisição e, quando a resposta chega, redesenha a contagem e
mostra *Added Mango* no aviso por dois segundos. O `click()` volta assim que o clique é entregue,
não quando nada disso aconteceu. Este teste lê o aviso dos dois jeitos. Salve-o como
`tests/waiting.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a read is a snapshot, an assertion retries', async ({ page }) => {
  await page.goto('/');
  const toast = page.getByRole('status');
  await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
  await expect(toast).toHaveText('Added Mango');
  console.log(`read once: "${await toast.textContent()}"`);
  // The shop empties the toast two seconds after it appears.
  await expect(toast).toHaveText('');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/waiting.spec.js

Running 1 test using 1 worker

read once: "Added Mango"
  ✓  1 tests/waiting.spec.js:7:1 › a read is a snapshot, an assertion retries (3.1s)

  1 passed (4.6s)
```

A primeira asserção esperou a resposta e o aviso. O `textContent()` então o leu uma vez e recebeu
`Added Mango`: **uma leitura é uma foto**, tirada no instante em que roda, e leria a mesma coisa
por mais que o teste esperasse depois. O `expect(toast).toHaveText('')` passou no mesmo elemento,
porque uma asserção sobre um localizador é uma **asserção web-first**: ela lê, compara e lê de novo
até o texto bater. Aqui ela continuou lendo até a loja esvaziar o aviso, e é por isso que o teste
levou mais de dois segundos.

**Nunca faça uma asserção sobre a foto de algo que ainda está mudando.**
`expect(await toast.textContent()).toBe('')` confere o valor num instante só; lido antes de a loja
responder ou depois de o aviso sumir, ele dá um veredito diferente na mesma página, que é o teste
instável de que trata a aula 14.

## Quanto tempo é "até"

Nenhum dos mecanismos espera para sempre, e vale conhecer os padrões por uma execução, não de
memória. Para vê-los, acrescente estes dois testes ao fim de `tests/waiting.spec.js`, rode o
arquivo e tire-os de novo. Cada um espera algo que nunca acontece:

```javascript
test('an assertion that is never true', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});

test('a click on a button that is not there', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Buy now' }).click();
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/waiting.spec.js

Running 3 tests using 1 worker

read once: "Added Mango"
  ✓  1 tests/waiting.spec.js:7:1 › a read is a snapshot, an assertion retries (3.2s)
  ✘  2 tests/waiting.spec.js:17:1 › an assertion that is never true (5.1s)
  ✘  3 tests/waiting.spec.js:22:1 › a click on a button that is not there (30.0s)


  1) tests/waiting.spec.js:17:1 › an assertion that is never true ──────────────────────────────────

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


      17 | test('an assertion that is never true', async ({ page }) => {
      18 |   await page.goto('/');
    > 19 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
         |                                                  ^
      20 | });
      21 |
      22 | test('a click on a button that is not there', async ({ page }) => {
        at /home/ana/quitanda/tests/waiting.spec.js:19:50

    Error Context: test-results/waiting-an-assertion-that-is-never-true/error-context.md

  2) tests/waiting.spec.js:22:1 › a click on a button that is not there ────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for getByRole('button', { name: 'Buy now' })


      22 | test('a click on a button that is not there', async ({ page }) => {
      23 |   await page.goto('/');
    > 24 |   await page.getByRole('button', { name: 'Buy now' }).click();
         |                                                       ^
      25 | });
      26 |
        at /home/ana/quitanda/tests/waiting.spec.js:24:55

    Error Context: test-results/waiting-a-click-on-a-button-that-is-not-there/error-context.md

  2 failed
    tests/waiting.spec.js:17:1 › an assertion that is never true ───────────────────────────────────
    tests/waiting.spec.js:22:1 › a click on a button that is not there ─────────────────────────────
  1 passed (40.7s)
```

As duas falhas mostram dois relógios diferentes:

- **uma asserção desiste depois de cinco segundos**, e a mensagem diz isso, `Timeout: 5000ms`, com um
  registro de chamadas mostrando quantas vezes ela olhou e o que achou em cada uma;
- **uma ação não tem relógio próprio.** O clique esperou um botão chamado *Buy now* até o teste
  inteiro estourar o tempo, `Test timeout of 30000ms exceeded`, e a duração ao lado do nome do
  teste mostra isso.

Os dois podem ser mudados: `expect.timeout` e `timeout` na configuração, `actionTimeout` dentro de
`use`, ou um `{ timeout }` numa chamada só. Mudá-los é assunto da aula 13. O que importa aqui é ler
a falha: um registro de chamadas dizendo que o localizador **resolveu** e tinha o valor errado é
uma página que fez algo inesperado; um registro que só diz **waiting for** é um localizador que não
casa com nada, e isso costuma ser culpa do teste.
