---
title: A espera vem embutida, e por que isso importa
version: 1
---

**Um navegador faz as coisas no tempo dele: ele busca, interpreta, roda scripts, e a página que você
pediu chega em pedaços.** Um teste que lê a página uma vez, no momento errado, vê uma página inacabada.
Essa é a causa mais comum de um teste **instável**, um que passa ou falha no mesmo código dependendo da
velocidade da máquina.

Eis um feito de propósito. Os dados são segurados por meio segundo, que é o que uma rede lenta faz, e
dois testes leem a lista de cursos de dois jeitos. Salve isto como `e2e/waiting.spec.ts`:

```typescript
// e2e/waiting.spec.ts
import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.route("**/courses.json", async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await route.continue();
  });
});

test("reading once, straight away", async ({ page }) => {
  await page.goto("/");
  expect(await page.getByRole("listitem").count()).toBe(3);
});

test("asserting, and letting it retry", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("listitem")).toHaveCount(3);
});
```

```
ana@dev:~/planner$ npx playwright test e2e/waiting.spec.ts --reporter=list

Running 2 tests using 1 worker

  ✘  1 [chromium] › e2e/waiting.spec.ts:11:1 › reading once, straight away (276ms)
  ✓  2 [chromium] › e2e/waiting.spec.ts:16:1 › asserting, and letting it retry (986ms)


  1) [chromium] › e2e/waiting.spec.ts:11:1 › reading once, straight away ───────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: 3
    Received: 0

      11 | test("reading once, straight away", async ({ page }) => {
      12 |   await page.goto("/");
    > 13 |   expect(await page.getByRole("listitem").count()).toBe(3);
         |                                                    ^
      14 | });
      15 |
      16 | test("asserting, and letting it retry", async ({ page }) => {
        at /home/ana/planner/e2e/waiting.spec.ts:13:52

    Error Context: test-results/waiting-reading-once-straight-away-chromium/error-context.md

    attachment #2: trace (application/zip) ─────────────────────────────────────────────────────────
    test-results/waiting-reading-once-straight-away-chromium/trace.zip
    Usage:

        npx playwright show-trace test-results/waiting-reading-once-straight-away-chromium/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────

  1 failed
    [chromium] › e2e/waiting.spec.ts:11:1 › reading once, straight away ────────────────────────────
  1 passed (3.7s)
```

**O primeiro teste leu a página uma vez, não achou itens, e falhou.** O `page.goto` espera o evento
`load` da página, e o script do planner ainda estava esperando os dados quando ele disparou. Numa rede
rápida o mesmo teste passa, e é exatamente isso que o torna perigoso: ele é verde na sua máquina e
vermelho na CI numa tarde cheia.

O segundo teste difere pelo lugar onde o `await` está. O `expect(locator).toHaveCount(3)` é uma
**asserção web-first**: ela continua perguntando à página até a resposta estar certa ou passarem cinco
segundos. Aqui ela esperou cerca de meio segundo, e esperaria o quanto a rede precisasse, e nem um
instante a mais.

A regra é a da aula 3, num navegador de verdade: **faça a asserção sobre um locator, nunca sobre um
valor lido dele.** O `expect(locator).toHaveText(…)` tenta de novo; o
`expect(await locator.textContent()).toBe(…)` lê uma vez. O mesmo vale para uma pausa fixa, o
`page.waitForTimeout(1000)`, que é longa demais numa máquina rápida e curta demais numa lenta.

A demonstração cumpriu o seu papel; apague o arquivo para ele não derrubar a suíte:

```
ana@dev:~/planner$ rm e2e/waiting.spec.ts
```
