---
title: Testando o elemento num navegador
version: 1
---

**Um elemento é mais bem testado onde roda, num navegador, e o Playwright entra sozinho em raízes shadow
abertas.** Um locator como `page.locator("#session-6 .when")` acha o span `.when` mesmo ele estando dentro
da árvore shadow da linha, e o `getByRole` acha o botão do mesmo jeito. A biblioteca ganha os mesmos dois
pacotes de teste que o planner ganhou na aula 6, fixados nas mesmas versões:

```
ana@dev:~/planner-ui$ npm install --save-dev --save-exact @playwright/test@1.63.0 @axe-core/playwright@4.14.0 2>&1 | tail -1
found 0 vulnerabilities
```

A configuração inicia o Vite numa porta só dele, para que os testes nunca encontrem um servidor de
desenvolvimento que você deixou rodando, e roda no Chromium:

```typescript
// playwright.config.ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "tests",
  use: { baseURL: "http://127.0.0.1:5180" },
  webServer: {
    command: "npx vite --host 127.0.0.1 --port 5180 --strictPort",
    url: "http://127.0.0.1:5180/",
    reuseExistingServer: false,
  },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
});
```

Os testes abrem a página de demonstração e conferem quatro coisas, uma por teste:

```typescript
// tests/session-element.spec.ts
import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.goto("/");
});

test("draws its attributes", async ({ page }) => {
  await expect(page.locator("#session-6 .when")).toHaveText("2026-10-15 · 45 min");
  await expect(page.locator("#session-4 .when")).toHaveText("2026-10-12 · 1 h");
});

test("marks itself done and says so", async ({ page }) => {
  await page.locator("#session-6").getByRole("button", { name: "Mark done" }).click();
  await expect(page.locator("#session-6")).toHaveAttribute("done", "");
  await expect(page.locator("#log")).toHaveText("session-6 marked done");
});

test("keeps the page's styles out", async ({ page }) => {
  const button = page.locator("#session-6").getByRole("button");
  await expect(button).toHaveCSS("background-color", "rgb(47, 111, 78)");
});

test("passes axe", async ({ page }) => {
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations.map((v) => v.id)).toEqual([]);
});
```

- **Draws its attributes** lê o texto que a árvore shadow desenhou a partir de `date` e `minutes`, passando
  pelo `duration` da própria biblioteca.
- **Marks itself done and says so** aperta o botão como uma pessoa faria, depois confere os dois
  resultados na ordem em que o elemento os produz: o atributo, e depois o evento que a página ouviu.
- **Keeps the page's styles out** pede o fundo calculado do botão. `rgb(47, 111, 78)` é `#2f6f4e`, o token
  `--color-green-600` para o qual `--accent` aponta no tema claro; o vermelho da página seria
  `rgb(255, 0, 0)`. Uma só verificação prova as duas metades das duas últimas seções: o seletor não
  entrou, e a propriedade customizada entrou.
- **Passes axe** roda as regras de acessibilidade sobre a página, árvores shadow incluídas.

Rode os testes, depois de dizer ao Git que deixe a saída do Playwright em paz:

```
ana@dev:~/planner-ui$ printf 'test-results\nplaywright-report\n' >> .gitignore
```

```
ana@dev:~/planner-ui$ npx playwright test 2>&1 | tail -1
  4 passed (5.2s)
```

Quatro passaram. Faça o commit do elemento com a página e os testes:

```
ana@dev:~/planner-ui$ git add -A && git commit -qm "Add <planner-session>, its demo page and its tests"
```

## Um teste que consegue falhar

Um teste que nunca falhou ainda não mostrou que consegue. Então quebre a fronteira de propósito: faça de
`#root` o próprio elemento em vez de uma raiz shadow, e o mesmo template é desenhado no light DOM, onde as
regras da página o alcançam.

```
ana@dev:~/planner-ui$ sed -i 's/#root = this.attachShadow({ mode: "open" });/#root = this;/' src/session-element.ts
ana@dev:~/planner-ui$ npx playwright test 2>&1 | grep -E '^  [0-9]+ (failed|passed)|Received: |"color-contrast"'
    Received: "rgb(255, 0, 0)"
    +   "color-contrast",
  2 failed
  2 passed (11.5s)
ana@dev:~/planner-ui$ git restore src/session-element.ts
```

Dois testes falham, e cada um diz o que encontrou. O botão está com o vermelho da página, e o axe agora
acha uma violação de `color-contrast`: texto vermelho e branco sobre vermelho medem os dois cerca de 4:1,
contra os 4,5:1 que um texto precisa. É por isso que as regras da página de demonstração dizem
`main button` e não `button`: sem raiz shadow, o `<style>` do elemento seria só mais uma folha de estilo
na página, e uma regra `button` simples da página perderia para ela só pela ordem, então o teste passaria
com a fronteira desfeita. O `git restore` devolve o arquivo ao estado do commit.

## Onde o Playwright para

Os locators de CSS e de papel do Playwright atravessam raízes shadow **abertas**. Não atravessam as
fechadas, e XPath não atravessa nenhuma, o que é mais um motivo para o elemento ser aberto. Um teste que
precise alcançar uma árvore fechada tem de passar por código que o elemento expõe para isso, e a essa
altura a privacidade do elemento é um custo, e não uma proteção.

Um executor sobre um DOM simulado, jsdom ou happy-dom com o Vitest, também suporta custom elements e
raízes shadow, e começa mais rápido. Mas ele não calcula estilos a partir de uma cascata de verdade, então
o terceiro teste, o da fronteira, só poderia rodar num navegador de verdade. Os testes de unidade do
planner continuam no Vitest; o que o elemento desenha é testado aqui.
