---
title: Os primeiros testes num navegador
version: 1
---

**Um teste de ponta a ponta faz o que uma pessoa faz, no navegador que uma pessoa usa, contra o app
como ele é servido.** Os quatro testes abaixo cobrem o caminho inteiro do planner: a semana na página
inicial, abrir um curso, adicionar uma sessão, marcar uma como feita, e o que acontece quando os dados
não chegam. Salve isto como `e2e/planner.spec.ts`:

```typescript
// e2e/planner.spec.ts
import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
});

test("the home page shows the week", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Study planner" })).toBeVisible();
  await expect(page.getByText("This week: 160 min")).toBeVisible();
});

test("a session added to a course counts in its week", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("link", { name: "JavaScript" }).click();
  await expect(page).toHaveURL(/#\/course\/javascript$/);
  await page.getByLabel("Date").fill("2026-10-23");
  await page.getByLabel("Minutes").fill("15");
  await page.getByRole("button", { name: "Add session" }).click();
  await expect(page.getByText("This week: 105 min")).toBeVisible();
});

test("Done marks a session and takes its button away", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await page.getByRole("button", { name: "Done" }).click();
  await expect(page.getByRole("button", { name: "Done" })).toHaveCount(0);
});

test("a failed load says so", async ({ page }) => {
  await page.route("**/courses.json", (route) => route.fulfill({ status: 500 }));
  await page.goto("/");
  await expect(page.getByText("Could not load your courses.")).toBeVisible();
});
```

Cada teste recebe uma `page`, uma aba nova num perfil de navegador novo, então nenhum teste vê o que
outro guardou. As buscas são as da Testing Library, pelo nome: `getByRole`, `getByLabel`,
`getByText`. E **o `page.clock.setFixedTime` para o relógio do navegador** às dez da manhã da quarta,
21 de outubro de 2026, então a "semana atual" é a semana dos dados do planner em qualquer dia em que
este teste rodar. É a frase que a aula 1 deixou em aberto: os totais que você viu no seu navegador
eram 0, e estes não são.

O último teste responde ele mesmo à requisição do `courses.json`, com um 500, então o caminho de erro
da página roda num navegador de verdade sem servidor quebrado nenhum. A seção depois da próxima é sobre
isso.

```
ana@dev:~/planner$ npx playwright test --reporter=list

Running 4 tests using 1 worker

  ✓  1 [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week (275ms)
  ✓  2 [chromium] › e2e/planner.spec.ts:14:1 › a session added to a course counts in its week (340ms)
  ✓  3 [chromium] › e2e/planner.spec.ts:24:1 › Done marks a session and takes its button away (240ms)
  ✓  4 [chromium] › e2e/planner.spec.ts:30:1 › a failed load says so (159ms)

  4 passed (2.3s)
```

**Quatro testes, quatro aprovados, poucos segundos**, a maior parte subindo o servidor de
desenvolvimento e o navegador. O `--reporter=list` mostra uma linha por teste; sem ele, o Playwright
mostra um ponto por teste e escreve também um relatório em HTML. Faça o commit deles:

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "End-to-end tests with Playwright"
```

## O que esta camada viu e as outras não conseguiam

Estes testes rodaram o `main.ts` de verdade, buscando o `courses.json` por HTTP no Vite. Eles clicaram
em elementos que tinham tamanho e lugar numa página com o CSS aplicado, e o Playwright **se recusa a
clicar** no que está escondido, coberto ou ainda se mexendo: antes de cada clique ele confere que o
elemento está visível, parado, habilitado e recebe o ponteiro. Uma execução verde aqui quer dizer que
uma pessoa teria conseguido fazer tudo isso, no Chromium, o que é uma frase mais forte do que qualquer
teste das aulas 2 e 3 consegue dizer.
