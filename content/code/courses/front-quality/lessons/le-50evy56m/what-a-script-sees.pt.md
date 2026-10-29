---
title: O que um script na página consegue ver
version: 1
---

**A diferença entre as linhas daquela tabela pode ser testada, no próprio navegador do planner.** Dois
testes: fazer login pela página e procurar o cookie de sessão a partir de um script, e depois pôr um
token no `localStorage` e procurá-lo a partir de um segundo script, como qualquer biblioteca da página
poderia fazer.

Os testes precisam da API rodando ao lado do servidor de desenvolvimento, então o `webServer` no
`playwright.config.ts` vira uma lista de dois:

```
ana@dev:~/planner$ git diff playwright.config.ts
diff --git a/playwright.config.ts b/playwright.config.ts
index cea6ae4..2894629 100644
--- a/playwright.config.ts
+++ b/playwright.config.ts
@@ -9,9 +9,8 @@ export default defineConfig({
     trace: "retain-on-failure",
   },
   projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
-  webServer: {
-    command: "npm run dev",
-    url: "http://localhost:5173",
-    reuseExistingServer: true,
-  },
+  webServer: [
+    { command: "npm run api", url: "http://127.0.0.1:3000/api/plan", reuseExistingServer: true },
+    { command: "npm run dev", url: "http://localhost:5173", reuseExistingServer: true },
+  ],
 });
```

O Playwright espera cada endereço responder antes do primeiro teste. O `/api/plan` responde 401 sem
cookie, e um 401 conta como resposta: quer dizer que o servidor está de pé e pedindo login. Salve o
primeiro como `e2e/storage.spec.ts`:

```typescript
// e2e/storage.spec.ts
import { expect, test } from "@playwright/test";

test("the session cookie is out of reach of the page's scripts", async ({ page, context }) => {
  await page.goto("/");
  const status = await page.evaluate(async () => {
    const response = await fetch("/api/login", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ name: "ana", password: "correct horse battery staple" }),
    });
    return response.status;
  });
  expect(status).toBe(200);
  const cookies = await context.cookies();
  expect(cookies).toHaveLength(1);
  expect(cookies[0].httpOnly).toBe(true);
  expect(await page.evaluate(() => document.cookie)).toBe("");
});
```

E o segundo, que é sobre o navegador e não sobre o planner, num arquivo só dele, para poder sair depois
de mostrar o que tem a mostrar. Salve isto como `e2e/local-storage.spec.ts`:

```typescript
// e2e/local-storage.spec.ts
import { expect, test } from "@playwright/test";

test("a token in localStorage is in reach of every script", async ({ page }) => {
  await page.goto("/");
  await page.evaluate(() => localStorage.setItem("token", "eyJhbGciOiJIUzI1NiJ9.e30.x"));
  await page.addScriptTag({ content: "document.title = localStorage.getItem('token')" });
  await expect(page).toHaveTitle("eyJhbGciOiJIUzI1NiJ9.e30.x");
});
```

O primeiro teste faz login do jeito que a página faria, com `fetch`, e depois faz duas perguntas. O
navegador tem o cookie, como o `context.cookies()` mostra de fora da página, marcado como `httpOnly`. E
o `document.cookie`, que é o que um script na página vê, está vazio.

O segundo teste é a outra linha. O `addScriptTag` acrescenta um segundo script à página, no lugar de
qualquer outro código que rode ali, e tudo o que ele faz é copiar o que acha no `localStorage` para o
título da página, onde o teste consegue ler. **Uma testemunha inofensiva basta**: se um script consegue
pôr o token no título, outro consegue pô-lo numa requisição para qualquer lugar.

```
ana@dev:~/planner$ npx playwright test e2e/storage.spec.ts e2e/local-storage.spec.ts --reporter=list

Running 2 tests using 2 workers

  ✓  1 [chromium] › e2e/storage.spec.ts:4:1 › the session cookie is out of reach of the page's scripts (395ms)
  ✓  2 [chromium] › e2e/local-storage.spec.ts:4:1 › a token in localStorage is in reach of every script (420ms)

  2 passed (2.0s)
```

Os dois passam, e os dois dizem o que prometem. **O primeiro é um teste do planner e fica**: se uma
mudança um dia deixar o cookie de sessão legível, ele falha. O segundo testa o navegador, que não é seu
para testar, como disse a aula 1, e o planner não guarda nada no `localStorage`; ele mostrou a linha da
tabela funcionando, e sai:

```
ana@dev:~/planner$ rm e2e/local-storage.spec.ts
```
