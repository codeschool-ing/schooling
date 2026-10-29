---
title: Quando um teste de navegador falha
version: 1
---

**Uma falha de ponta a ponta pode estar em qualquer lugar entre o arquivo de dados e o CSS, então o
Playwright registra como estava a página quando ela aconteceu.** Para ver isso, quebre um teste de
propósito: mude o total esperado do primeiro teste de 160 para 150, como se alguém tivesse feito a conta
errado, e rode esse teste.

```
ana@dev:~/planner$ npx playwright test e2e/planner.spec.ts -g "shows the week" --reporter=list

Running 1 test using 1 worker

  ✘  1 [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week (5.3s)


  1) [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week ───────────────────────────

    Error: expect(locator).toBeVisible() failed

    Locator: getByText('This week: 150 min')
    Expected: visible
    Timeout: 5000ms
    Error: element(s) not found

    Call log:
      - Expect "toBeVisible" getByText('This week: 150 min') with timeout 5000ms
      - waiting for getByText('This week: 150 min')


       9 |   await page.goto("/");
      10 |   await expect(page.getByRole("heading", { name: "Study planner" })).toBeVisible();
    > 11 |   await expect(page.getByText("This week: 150 min")).toBeVisible();
         |                                                      ^
      12 | });
      13 |
      14 | test("a session added to a course counts in its week", async ({ page }) => {
        at /home/ana/planner/e2e/planner.spec.ts:11:54

    Error Context: test-results/planner-the-home-page-shows-the-week-chromium/error-context.md

    attachment #2: trace (application/zip) ─────────────────────────────────────────────────────────
    test-results/planner-the-home-page-shows-the-week-chromium/trace.zip
    Usage:

        npx playwright show-trace test-results/planner-the-home-page-shows-the-week-chromium/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────

  1 failed
    [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week ────────────────────────────
```

O relatório diz o teste, a linha, o que era esperado e o que a página mostrou no lugar, e depois dois
caminhos em `test-results/`. **O `error-context.md`** é escrito em toda falha. Ele começa com o erro e
algumas linhas de instruções endereçadas a um assistente de programação com IA, e no coração dele está
a página como a árvore de acessibilidade a viu naquele momento, a mesma estrutura que a Testing Library
consulta. O `sed` mostra só essa parte:

```
ana@dev:~/planner$ ls test-results/planner-the-home-page-shows-the-week-chromium
error-context.md
trace.zip
ana@dev:~/planner$ sed -n '/^- heading/,/^- paragraph/p' test-results/planner-the-home-page-shows-the-week-chromium/error-context.md
- heading "Study planner" [level=1]
- list:
  - listitem:
    - link "HTML and CSS":
      - /url: "#/course/html-css"
      - img
      - text: HTML and CSS
    - text: 45 min this week
  - listitem:
    - link "JavaScript":
      - /url: "#/course/javascript"
      - img
      - text: JavaScript
    - text: 90 min this week
  - listitem:
    - link "Git":
      - /url: "#/course/git"
      - img
      - text: Git
    - text: 25 min this week
- paragraph: "This week: 160 min"
```

Leia como uma pessoa leria a tela: um título, uma lista de três links com seus minutos, e o parágrafo
que diz 160. O teste estava errado, e não a página, e o arquivo diz isso sem abrir nada. Uma falha na
CI, numa máquina que você não consegue olhar, vem com esse arquivo.

**O `trace.zip`** é o outro, guardado porque a configuração diz `retain-on-failure`. É uma gravação do
teste inteiro: cada ação, uma imagem da página antes e depois dela, o console, e cada requisição com a
resposta. Ele abre no visualizador de trace, que é uma página web:

```sh
npx playwright show-trace test-results/planner-the-home-page-shows-the-week-chromium/trace.zip
```

*Esse comando abre uma janela e não foi rodado onde este curso foi gravado, que não tem tela.* Na sua
máquina ele abre a gravação no passo que falhou; numa máquina virtual, copie o zip para o seu computador
e solte-o em `trace.playwright.dev`, que o abre no seu navegador sem mandá-lo para lugar nenhum.

Ponha o 160 de volta, e confira que a suíte voltou a ficar verde antes de continuar:

```
ana@dev:~/planner$ git checkout e2e/planner.spec.ts
Updated 1 path from the index
ana@dev:~/planner$ npx playwright test --reporter=list

Running 5 tests using 2 workers

  ✓  1 [chromium] › e2e/empty.spec.ts:4:1 › a course with nothing planned says 0 for its week (365ms)
  ✓  2 [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week (368ms)
  ✓  3 [chromium] › e2e/planner.spec.ts:14:1 › a session added to a course counts in its week (346ms)
  ✓  4 [chromium] › e2e/planner.spec.ts:24:1 › Done marks a session and takes its button away (199ms)
  ✓  5 [chromium] › e2e/planner.spec.ts:30:1 › a failed load says so (151ms)

  5 passed (2.5s)
```
